import httpx
import re
import asyncio
import zipfile
import io
import json
from datetime import datetime, timedelta
from sqlmodel import Session, select
from app.core.database import engine

from app.modules.country.model import Country
from app.modules.political_party.model import Domain
from app.modules.law.model import Law

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
                                                
                                                new_law = Law(
                                                    title=clean_title,
                                                    subtitle=f"Scrutin National n°{numero}",
                                                    description=f"Le texte original est intitulé : '{titre}'.\nVote effectué le {vote_date_str} avec un résultat '{sort_code}'.\n\nParticipants: {votants} votants dont {pours} 'Pour' et {contres} 'Contre'.",
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
