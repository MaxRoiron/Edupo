from ...core import get_session
from ..users import User, get_current_user
from fastapi import APIRouter, Depends, HTTPException, status
from .shemas import LawView, LawCreate, LawUpdate, VoteCreate, VoteUpdate, Voteview
from .services import read_all_law, read_law, add_law, update_law, delete_law
from .services import read_all_vote, read_vote, add_vote, update_vote, delete_vote

from sqlmodel import Session
import httpx

router = APIRouter()

@router.get("/law/assembly_votes/{scrutin_id}", tags=["Law"])
async def fetch_assembly_votes(scrutin_id: str):
    """Retrieve official government votes results from nosdeputes.fr OpenData for a specific scrutin"""
    url = f"https://www.nosdeputes.fr/16/scrutin/{scrutin_id}/json"
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(
                url, 
                timeout=10.0, 
                headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
            )
            if resp.status_code == 200:
                data = resp.json()
                return {"votes": data.get("votes", [])}
            elif resp.status_code == 404:
                raise HTTPException(status_code=404, detail="Résultats non disponibles")
            else:
                raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Failed to fetch open data")
        except HTTPException as he:
            raise he
        except Exception as e:
            raise HTTPException(status_code=500, detail="Internal Error")

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
