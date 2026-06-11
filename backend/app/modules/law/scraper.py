import httpx
import re
import asyncio
import zipfile
import io
import json
import xml.etree.ElementTree as ET
import hashlib
from datetime import datetime, timedelta
from sqlmodel import Session, select
from app.core.database import engine

from app.modules.country.model import Country
from app.modules.political_party.model import Domain
from app.modules.law.model import Law


def _build_rss_description_lookup(rss_content: bytes) -> dict:
    """
    Parse le RSS de vie-publique.fr et construit un dictionnaire
    qui mappe des mots-clés normalisés du titre → description.
    Permet de retrouver la description d'une loi votée à partir du titre du scrutin AN.
    """
    root = ET.fromstring(rss_content)
    dc_ns = "{http://purl.org/dc/elements/1.1/}"
    lookup = []

    for item in root.findall(".//item"):
        title = item.findtext("title", "").strip()
        desc = item.findtext(f"{dc_ns}description", "").strip()
        link = item.findtext("link", "").strip()
        if not desc:
            continue
        # Nettoyer HTML
        clean_desc = re.sub('<[^<]+?>', '', desc).strip()
        clean_desc = clean_desc.replace('&nbsp;', ' ').replace('&amp;', '&').replace('&#039;', "'")
        # Normaliser le titre pour le matching
        norm = title.lower()
        norm = re.sub(r'^(loi du \d+ \w+ \d+ )', '', norm)
        norm = re.sub(r'^(projet|proposition) de loi (organique )?', '', norm)
        norm = re.sub(r'^(visant à |relative? à |portant |d[\'e] |sur |de )', '', norm)
        lookup.append({
            'title': title,
            'norm': norm.strip(),
            'description': clean_desc,
            'link': link,
        })

    return lookup


def _find_rss_description(scrutin_titre: str, rss_lookup: list) -> str | None:
    """
    Cherche dans le lookup RSS la meilleure description correspondant
    au titre d'un scrutin de l'Assemblée nationale.
    """
    # Extraire la partie significative du titre du scrutin
    norm_scrutin = scrutin_titre.lower()
    norm_scrutin = re.sub(r'^.*l\'ensemble d[ue] (projet|proposition) de loi ', '', norm_scrutin)
    norm_scrutin = re.sub(r'\(texte.*$', '', norm_scrutin).strip()
    norm_scrutin = re.sub(r',?\s*en\s+(nouvelle|première|deuxième|lecture|définitive)[\s,]*', ' ', norm_scrutin).strip()

    # Extraire les mots significatifs (4+ chars) du titre du scrutin
    scrutin_words = {w for w in norm_scrutin.split() if len(w) >= 4}
    if not scrutin_words:
        return None

    best_desc = None
    best_score = 0

    for entry in rss_lookup:
        rss_words = {w for w in entry['norm'].split() if len(w) >= 4}
        if not rss_words:
            continue
        common = scrutin_words & rss_words
        if len(common) < 2:
            continue
        score = len(common) / min(len(scrutin_words), len(rss_words))
        if score > best_score:
            best_score = score
            best_desc = entry['description']

    return best_desc if best_score >= 0.4 else None

async def scrape_and_sync_laws():
    """
    Système automatique de mise à jour des lois.
    Se connecte à l'Open Data de nosdeputes.fr pour scanner les scrutins récents,
    et mettre à jour notre base de données postgres "law" automatiquement.
    """
    url = "https://www.nosdeputes.fr/16/scrutins/json"
    
    async with httpx.AsyncClient() as client:
        try:
            with Session(engine) as session:
                country = session.exec(select(Country).where(Country.name == "France")).first()
                domain = session.exec(select(Domain).where(Domain.name == "Général")).first()
                if not country or not domain:
                    print("[Scraper] Pays ou Domaine manquant, impossible de scraper.")
                    return 0
                
                laws_added = 0

                # --- Récupérer le RSS vie-publique.fr pour avoir les vraies descriptions ---
                rss_lookup = []
                try:
                    rss_resp = await client.get("https://www.vie-publique.fr/lois-feeds.xml", timeout=15.0)
                    if rss_resp.status_code == 200:
                        rss_lookup = _build_rss_description_lookup(rss_resp.content)
                        print(f"[Scraper] {len(rss_lookup)} descriptions RSS chargées depuis vie-publique.fr")
                except Exception as e:
                    print(f"[Scraper] Impossible de charger le RSS vie-publique : {e}")
                
                # Check les scrutins de l'Assemblée nationale (17ème législature Open Data)
                try:
                    zip_url = "https://data.assemblee-nationale.fr/static/openData/repository/17/loi/scrutins/Scrutins.json.zip"
                    an_resp = await client.get(zip_url, timeout=30.0, follow_redirects=True)
                    if an_resp.status_code == 200:
                        with zipfile.ZipFile(io.BytesIO(an_resp.content)) as z:
                            for filename in z.namelist():
                                if filename.endswith(".json"):
                                    with z.open(filename) as f:
                                        data = json.load(f)
                                        s = data.get("scrutin", {})
                                        titre = s.get("titre", "")
                                        
                                        if "l'ensemble du projet de loi" in titre.lower() or "l'ensemble de la proposition de loi" in titre.lower():
                                            uid = str(s.get("uid", ""))
                                            numero = str(s.get("numero", ""))
                                            
                                            existing = session.exec(select(Law).where(Law.scrutin_id == uid)).first()
                                            if not existing:
                                                clean_title = re.sub(r'^.*l\'ensemble d[ue] (projet|proposition) de loi (.*)$', r'\2', titre, flags=re.IGNORECASE)
                                                clean_title = clean_title.split("(texte")[0].strip().capitalize()
                                                
                                                category = "Justice / Intérieur" if "intérieur" in clean_title.lower() or "sécurité" in clean_title.lower() else "Législation"
                                                category = "Écologie" if "climat" in clean_title.lower() or "environnement" in clean_title.lower() else category
                                                category = "Économie" if "pouvoir d'achat" in clean_title.lower() or "finances" in clean_title.lower() else category
                                                
                                                vote_date_str = s.get("dateScrutin", "")
                                                if not vote_date_str: continue

                                                # Ignorer les lois votées il y a plus de 6 mois
                                                vote_dt = datetime.strptime(vote_date_str, "%Y-%m-%d")
                                                if (datetime.now() - vote_dt).days > 180:
                                                    continue

                                                sort_code = (s.get("sort") or {}).get("code", "")
                                                synthese = s.get("syntheseVote", {}).get("decompte", {})
                                                pours = synthese.get("pour", "0")
                                                contres = synthese.get("contre", "0")
                                                votants = s.get("syntheseVote", {}).get("nombreVotants", "0")

                                                # Chercher la vraie description dans vie-publique.fr (comme pour les lois à venir)
                                                rss_desc = _find_rss_description(titre, rss_lookup)
                                                if rss_desc:
                                                    description = rss_desc
                                                else:
                                                    description = f"Le texte original est intitulé : '{titre}'.\nVote effectué le {vote_date_str} avec un résultat '{sort_code}'.\n\nParticipants: {votants} votants dont {pours} 'Pour' et {contres} 'Contre'."
                                                
                                                new_law = Law(
                                                    title=clean_title,
                                                    subtitle=f"Scrutin National n°{numero}",
                                                    description=description,
                                                    domain_id=domain.id,
                                                    country_id=country.id,
                                                    vote_date=datetime.strptime(vote_date_str, "%Y-%m-%d"),
                                                    scrutin_id=uid,
                                                    category=category,
                                                    is_active=True
                                                )
                                                session.add(new_law)
                                                laws_added += 1
                    else:
                        print(f"[Scraper] Erreur accès Open Data AN, statut {an_resp.status_code}")
                except Exception as an_err:
                    print(f"[Scraper] Impossible de traiter le ZIP Open Data AN : {repr(an_err)}")
                
                # --- VRAIES LOIS À VENIR (Scrapées depuis vie-publique.fr RSS) ---
                rss_url = "https://www.vie-publique.fr/lois-feeds.xml"
                try:
                    rss_resp = await client.get(rss_url, timeout=15.0)
                    if rss_resp.status_code == 200:
                        import xml.etree.ElementTree as ET
                        import hashlib
                        root = ET.fromstring(rss_resp.content)
                        
                        items = root.findall(".//item")
                        future_count = 0
                        dc_namespace = "{http://purl.org/dc/elements/1.1/}"
                        
                        # We only take the first few to avoid overloading
                        for item in items:
                            title = item.findtext("title", "")
                            description = item.findtext(f"{dc_namespace}description", "")
                            link = item.findtext("link", "")
                            pubDate = item.findtext("pubDate", "")
                            
                            if "projet de loi" in title.lower() or "proposition de loi" in title.lower():
                                # Uniq ID from link hash (deterministic)
                                fake_id = hashlib.sha256(link.encode()).hexdigest()[:8]
                                existing = session.exec(select(Law).where(Law.scrutin_id == fake_id)).first()
                                if not existing:
                                    clean_title = re.sub(r'^(Projet|Proposition) de loi (.*)$', r'\2', title, flags=re.IGNORECASE)
                                    clean_title = clean_title.capitalize()
                                    
                                    # Set a future date within the next 2 months
                                    future_date = datetime.now() + timedelta(days=10 + (future_count % 45))
                                    
                                    category = "Justice / Politique" if "justice" in clean_title.lower() or "sécurité" in clean_title.lower() else "Société et Débat Public"
                                    category = "Économie" if "finances" in clean_title.lower() or "budget" in clean_title.lower() else category
                                    
                                    # Use a plain HTML tag removal for description
                                    clean_desc = re.sub('<[^<]+?>', '', description)
                                    
                                    session.add(Law(
                                        title=clean_title,
                                        subtitle="Texte à venir",
                                        description=f"{clean_desc}\n\nLien de suivi : {link}",
                                        domain_id=domain.id,
                                        country_id=country.id,
                                        vote_date=future_date,
                                        scrutin_id=fake_id,
                                        category=category,
                                        is_active=True
                                    ))
                                    laws_added += 1
                                    future_count += 1
                except Exception as ex_rss:
                    print(f"[Scraper] Erreur RSS vie-publique : {ex_rss}")

                session.commit()
                print(f"[Scraper] Automatisme exécuté avec succès. {laws_added} nouvelles lois intégrées.")
                return laws_added

        except Exception as e:
            print(f"[Scraper] Erreur interne lors du scraping: {e}")
            return 0

# Boucle pour l'exécution en arrière-plan
async def periodic_law_scraper():
    while True:
        print("[Scraper] Lancement de la synchronisation automatique des lois...")
        await scrape_and_sync_laws()
        # Scan toutes les 6 heures
        await asyncio.sleep(60 * 60 * 6)


async def resync_voted_laws():
    """
    Met à jour le title/subtitle/description de toutes les lois déjà votées
    existantes en base, en re-téléchargeant les données de l'Assemblée nationale
    et en croisant avec vie-publique.fr pour avoir de vraies descriptions.
    """
    async with httpx.AsyncClient() as client:
        try:
            with Session(engine) as session:
                # Charger les descriptions depuis vie-publique.fr
                rss_lookup = []
                try:
                    rss_resp = await client.get("https://www.vie-publique.fr/lois-feeds.xml", timeout=15.0)
                    if rss_resp.status_code == 200:
                        rss_lookup = _build_rss_description_lookup(rss_resp.content)
                        print(f"[Resync] {len(rss_lookup)} descriptions RSS chargées")
                except Exception as e:
                    print(f"[Resync] RSS indisponible : {e}")

                zip_url = "https://data.assemblee-nationale.fr/static/openData/repository/17/loi/scrutins/Scrutins.json.zip"
                an_resp = await client.get(zip_url, timeout=30.0, follow_redirects=True)
                if an_resp.status_code != 200:
                    print(f"[Resync] Erreur accès Open Data AN, statut {an_resp.status_code}")
                    return 0

                updated = 0
                with zipfile.ZipFile(io.BytesIO(an_resp.content)) as z:
                    for filename in z.namelist():
                        if filename.endswith(".json"):
                            with z.open(filename) as f:
                                data = json.load(f)
                                s = data.get("scrutin", {})
                                titre = s.get("titre", "")
                                uid = str(s.get("uid", ""))
                                numero = str(s.get("numero", ""))

                                existing = session.exec(select(Law).where(Law.scrutin_id == uid)).first()
                                if existing:
                                    # Recalculer titre propre
                                    clean_title = re.sub(r'^.*l\'ensemble d[ue] (projet|proposition) de loi (.*)$', r'\2', titre, flags=re.IGNORECASE)
                                    clean_title = clean_title.split("(texte")[0].strip().capitalize()
                                    clean_title = re.sub(r',?\s*en\s+(nouvelle\s+lecture|première\s+lecture|deuxième\s+lecture|lecture\s+définitive).*$', '', clean_title, flags=re.IGNORECASE).strip()

                                    sort_code = (s.get("sort") or {}).get("code", "")
                                    synthese = s.get("syntheseVote", {}).get("decompte", {})
                                    pours = synthese.get("pour", "0")
                                    contres = synthese.get("contre", "0")
                                    votants = s.get("syntheseVote", {}).get("nombreVotants", "0")
                                    vote_date_str = s.get("dateScrutin", "")

                                    subtitle = f"Scrutin National n°{numero}"

                                    # Chercher la vraie description dans vie-publique.fr
                                    rss_desc = _find_rss_description(titre, rss_lookup)
                                    if rss_desc:
                                        description = rss_desc
                                    else:
                                        sort_label = "adopté" if sort_code == "adopté" else "rejeté" if sort_code == "rejeté" else sort_code
                                        description = f"Le texte original est intitulé : '{titre}'.\nVote effectué le {vote_date_str} avec un résultat '{sort_label}'.\n\nParticipants: {votants} votants dont {pours} 'Pour' et {contres} 'Contre'."

                                    existing.title = clean_title
                                    existing.subtitle = subtitle
                                    existing.description = description
                                    session.add(existing)
                                    updated += 1

                session.commit()
                print(f"[Resync] {updated} lois votées mises à jour avec le nouveau format.")
                return updated

        except Exception as e:
            print(f"[Resync] Erreur lors de la mise à jour : {e}")
            return 0
