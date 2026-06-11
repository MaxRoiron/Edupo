from ...core import get_session
from ..users import User, get_current_user
from fastapi import APIRouter, Depends, HTTPException, status
from .shemas import LawView, LawCreate, LawUpdate, VoteCreate, VoteUpdate, Voteview
from .services import read_all_law, read_law, add_law, update_law, delete_law
from .services import read_all_vote, read_vote, add_vote, update_vote, delete_vote
from .scraper import resync_voted_laws

from sqlmodel import Session
import httpx

router = APIRouter()

import zipfile
import io
import json

# In-memory cache for the organes and scrutins ZIP data
_organes_cache: dict | None = None
_scrutins_cache: dict | None = None

async def _load_organes(client: httpx.AsyncClient) -> dict:
    """Download and cache the political group organe data (abbreviation + color)."""
    global _organes_cache
    if _organes_cache is not None:
        return _organes_cache

    url = "https://data.assemblee-nationale.fr/static/openData/repository/17/amo/deputes_actifs_mandats_actifs_organes/AMO10_deputes_actifs_mandats_actifs_organes.json.zip"
    resp = await client.get(url, timeout=30.0, follow_redirects=True)
    if resp.status_code != 200:
        return {}

    result = {}
    with zipfile.ZipFile(io.BytesIO(resp.content)) as z:
        for name in z.namelist():
            if name.startswith("json/organe/") and name.endswith(".json"):
                with z.open(name) as f:
                    data = json.load(f)
                    organe = data.get("organe", {})
                    if organe.get("codeType") == "GP":
                        uid = organe.get("uid", "")
                        result[uid] = {
                            "abbreviation": organe.get("libelleAbrege", ""),
                            "name": organe.get("libelle", ""),
                            "color": organe.get("couleurAssociee", "#808080"),
                            "preseance": int(organe.get("preseance", 99)),
                        }
    _organes_cache = result
    return result


async def _load_scrutin(client: httpx.AsyncClient, scrutin_uid: str) -> dict | None:
    """Download the scrutins ZIP and extract a specific scrutin by UID."""
    global _scrutins_cache
    if _scrutins_cache is None:
        url = "https://data.assemblee-nationale.fr/static/openData/repository/17/loi/scrutins/Scrutins.json.zip"
        resp = await client.get(url, timeout=30.0, follow_redirects=True)
        if resp.status_code != 200:
            return None
        cache = {}
        with zipfile.ZipFile(io.BytesIO(resp.content)) as z:
            for name in z.namelist():
                if name.endswith(".json"):
                    with z.open(name) as f:
                        data = json.load(f)
                        uid = data.get("scrutin", {}).get("uid", "")
                        if uid:
                            cache[uid] = data
        _scrutins_cache = cache

    return _scrutins_cache.get(scrutin_uid)


def _extract_votants(container, position: str) -> list:
    """Extract individual votants from a decompteNominatif section."""
    if not container:
        return []
    votant = container.get("votant", [])
    if isinstance(votant, dict):
        votant = [votant]
    return [{"acteurRef": v.get("acteurRef", ""), "position": position} for v in votant]


@router.get("/law/assembly_votes/{scrutin_id}", tags=["Law"])
async def fetch_assembly_votes(scrutin_id: str):
    """Retrieve official vote results from Assemblée nationale Open Data for a specific scrutin UID."""
    async with httpx.AsyncClient() as client:
        try:
            organes = await _load_organes(client)
            scrutin_data = await _load_scrutin(client, scrutin_id)

            if not scrutin_data:
                raise HTTPException(status_code=404, detail="Résultats non disponibles")

            s = scrutin_data.get("scrutin", {})

            TOTAL_SEATS = 577  # Total de sièges à l'Assemblée nationale

            # Position politique gauche → droite (spectre réel de l'hémicycle)
            POLITICAL_POSITION = {
                "GDR": 1,        # Gauche Démocrate et Républicaine
                "LFI-NFP": 2,    # La France Insoumise - NFP
                "EcoS": 3,       # Écologiste et Social
                "SOC": 4,        # Socialistes et apparentés
                "LIOT": 5,       # Libertés, Indépendants, Outre-mer et Territoires
                "EPR": 6,        # Ensemble pour la République
                "Dem": 7,        # Les Démocrates
                "HOR": 8,        # Horizons & Indépendants
                "DR": 9,         # Droite Républicaine
                "UDR": 10,       # Union des Droites pour la République
                "RN": 11,        # Rassemblement National
                "NI": 12,        # Non-inscrits
            }

            # Extract per-group votes
            ventilation = s.get("ventilationVotes", {}).get("organe", {}).get("groupes", {}).get("groupe", [])
            if isinstance(ventilation, dict):
                ventilation = [ventilation]

            groups = []
            individual_votes = []

            for grp in ventilation:
                organe_ref = grp.get("organeRef", "")
                organe_info = organes.get(organe_ref, {})
                abbreviation = organe_info.get("abbreviation", "?")
                color = organe_info.get("color", "#808080")
                group_name = organe_info.get("name", "Inconnu")
                pol_pos = POLITICAL_POSITION.get(abbreviation, 50)

                vote_data = grp.get("vote", {})
                decompte_voix = vote_data.get("decompteVoix", {})
                nominatif = vote_data.get("decompteNominatif", {})

                group_summary = {
                    "organeRef": organe_ref,
                    "abbreviation": abbreviation,
                    "name": group_name,
                    "color": color,
                    "politicalPosition": pol_pos,
                    "pour": int(decompte_voix.get("pour", 0)),
                    "contre": int(decompte_voix.get("contre", 0)),
                    "abstentions": int(decompte_voix.get("abstentions", 0)),
                    "positionMajoritaire": vote_data.get("positionMajoritaire", ""),
                }
                groups.append(group_summary)

                # Extract individual votes for hemicycle dots
                pours = _extract_votants(nominatif.get("pours"), "pour")
                contres = _extract_votants(nominatif.get("contres"), "contre")
                abstentions = _extract_votants(nominatif.get("abstentions"), "abstention")
                # Non-votants du groupe → comptés comme abstention
                non_votants = _extract_votants(nominatif.get("nonVotants"), "abstention")

                for v in pours + contres + abstentions + non_votants:
                    individual_votes.append({
                        **v,
                        "groupe": abbreviation,
                        "color": color,
                        "politicalPosition": pol_pos,
                    })

            # Ajouter les sièges manquants (députés absents) comme abstention
            current_count = len(individual_votes)
            absent_count = max(0, TOTAL_SEATS - current_count)
            for _ in range(absent_count):
                individual_votes.append({
                    "acteurRef": "",
                    "position": "abstention",
                    "groupe": "Absent",
                    "color": "#C8CCD2",
                    "politicalPosition": 99,
                })

            # Recalculer le summary avec les 577 sièges
            nb_pour = sum(1 for v in individual_votes if v["position"] == "pour")
            nb_contre = sum(1 for v in individual_votes if v["position"] == "contre")
            nb_abst = sum(1 for v in individual_votes if v["position"] == "abstention")

            summary = {
                "pour": nb_pour,
                "contre": nb_contre,
                "abstentions": nb_abst,
                "votants": TOTAL_SEATS,
                "sort": (s.get("sort") or {}).get("code", ""),
            }

            # Trier par position politique gauche → droite (spectre réel)
            groups.sort(key=lambda g: g["politicalPosition"])
            individual_votes.sort(key=lambda v: v["politicalPosition"])

            return {
                "summary": summary,
                "groups": groups,
                "votes": individual_votes,
            }

        except HTTPException as he:
            raise he
        except Exception as e:
            print(f"[assembly_votes] Error: {e}")
            raise HTTPException(status_code=500, detail="Internal Error")


@router.post("/admin/law/resync-voted", tags=["Admin"])
async def resync_voted_laws_endpoint():
    """Re-télécharge les données de l'AN et met à jour title/subtitle/description des lois votées existantes."""
    count = await resync_voted_laws()
    return {"message": f"{count} lois votées mises à jour avec le nouveau format."}

@router.get("/law", response_model=list[LawView], tags=["Law"])
def read_all_law_endpoint(session: Session = Depends(get_session)):
    return read_all_law(session)

@router.get("/law/{id_law}", response_model=LawView, tags=["Law"])
def read_law_endpoint(id_law: int, session: Session = Depends(get_session)):
    return read_law(session, id_law)

@router.post("/admin/law", response_model=LawView, status_code=status.HTTP_201_CREATED, tags=["Admin"])
def add_law_endpoint(law: LawCreate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "admin":
        return add_law(session, law)
    else:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to add a law")

@router.patch("/admin/law/{id_law}", tags=["Admin"])
def update_law_endpoint(id_law: int, law: LawUpdate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.role == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to update a law")
    return update_law(session, id_law, law)

@router.delete("/admin/law/{id_law}", tags=["Admin"])
def delete_law_endpoint(id_law: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.role == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to delete a law")
    return delete_law(session, id_law)




@router.get("/vote", response_model=list[Voteview], tags=["Vote"])
def read_all_vote_endpoint(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_all_vote(session)

@router.get("/vote/{id_vote}", response_model=Voteview, tags=["Vote"])
def read_vote_endpoint(id_vote: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_vote(session, id_vote)

@router.post("/admin/vote", response_model=Voteview, status_code=status.HTTP_201_CREATED, tags=["Admin"])
def add_vote_endpoint(vote: VoteCreate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "admin":
        return add_vote(session, vote)
    else:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to add a vote")

@router.patch("/admin/vote/{id_vote}", tags=["Admin"])
def update_vote_endpoint(id_vote: int, vote: VoteUpdate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.role == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to update a vote")
    return update_vote(session, id_vote, vote)

@router.delete("/admin/vote/{id_vote}", tags=["Admin"])
def delete_vote_endpoint(id_vote: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.role == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to delete a vote")
    return delete_vote(session, id_vote)
