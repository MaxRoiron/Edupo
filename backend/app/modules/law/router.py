from ...core import get_session
from ..users import User, get_current_user
from fastapi import APIRouter, Depends, HTTPException, status
from .shemas import LawView, LawCreate, LawUpdate, VoteCreate, VoteUpdate, Voteview, VoteResultCreate, VoteResultTypeUpdate, VoteResultTypeView
from .services import read_all_law, read_law, add_law, update_law, delete_law
from .services import read_all_vote, read_vote, add_vote, update_vote, delete_vote
from .services import read_all_vote_result, read_vote_result, add_vote_result, update_vote_result, delete_vote_result

from sqlmodel import Session

router = APIRouter()

@router.get("/law", response_model=list[LawView], tags=["Law"])
def read_all_law_endpoint(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_all_law(session)

@router.get("/law/{id_law}", response_model=LawView, tags=["Law"])
def read_law_endpoint(id_law: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_law(session, id_law)

@router.post("/admin/law", response_model=LawView, tags=["Admin"])
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

@router.post("/admin/vote", response_model=Voteview, tags=["Admin"])
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

@router.get("/vote-result", response_model=list[VoteResultTypeView], tags=["VoteResult"])
def read_all_vote_result_endpoint(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_all_vote_result(session)

@router.get("/vote-result/{id_vote_result}", response_model=VoteResultTypeView, tags=["VoteResult"])
def read_vote_result_endpoint(id_vote_result: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_vote_result(session, id_vote_result)

@router.post("/admin/vote-result", response_model=VoteResultTypeView, tags=["Admin"])
def add_vote_result_endpoint(vote_result: VoteResultCreate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "admin":
        return add_vote_result(session, vote_result)
    else:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to add a vote result")

@router.patch("/admin/vote-result/{id_vote_result}", tags=["Admin"])
def update_vote_result_endpoint(id_vote_result: int, vote_result: VoteResultTypeUpdate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.role == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to update a vote result")
    return update_vote_result(session, id_vote_result, vote_result)

@router.delete("/admin/vote-result/{id_vote_result}", tags=["Admin"])
def delete_vote_result_endpoint(id_vote_result: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.role == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to delete a vote result")
    return delete_vote_result(session, id_vote_result)
