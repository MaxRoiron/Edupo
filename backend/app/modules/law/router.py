from ...core import get_session
from ..users import User, get_current_user
from fastapi import APIRouter, Depends, HTTPException, status
from .shemas import LawView, LawCreate, LawUpdate, VoteCreate, VoteUpdate, Voteview
from .services import read_all_law, read_law, add_law, update_law, delete_law
from .services import read_all_vote, read_vote, add_vote, update_vote, delete_vote
from .scraper import resync_voted_laws

from sqlmodel import Session

router = APIRouter()

from typing import Literal
from fastapi import Query
from .scraper import synchronize_laws
from .assembly_votes import assembly_vote_result, political_groups
from .model import LawScrutin
from .services import read_citizen_vote, save_citizen_vote
from .shemas import CitizenVoteInput, CitizenVoteView
from sqlmodel import select


@router.post("/law/sync", tags=["Law"])
async def synchronize_endpoint():
    """Refresh on client launch. Shared job + database lock + short cooldown."""
    return await synchronize_laws()


@router.get("/law/sync/status", tags=["Law"])
def synchronization_status(session: Session = Depends(get_session)):
    from .model import LawSyncState

    return session.exec(select(LawSyncState)).all()


@router.get("/law/assembly_votes/{scrutin_id}", tags=["Law"])
def fetch_assembly_votes(scrutin_id: str, session: Session = Depends(get_session)):
    row = session.exec(select(LawScrutin).where(LawScrutin.uid == scrutin_id)).first()
    if row is None:
        raise HTTPException(
            status_code=404, detail="Aucun scrutin officiel disponible pour ce texte"
        )
    return assembly_vote_result(row.payload, political_groups())


@router.post("/admin/law/resync-voted", tags=["Admin"])
async def resync_voted_laws_endpoint(user: User = Depends(get_current_user)):
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Administration requise")
    return await resync_voted_laws()


@router.get("/law", response_model=list[LawView], tags=["Law"])
def read_all_law_endpoint(
    session: Session = Depends(get_session),
    group: Literal["pending", "voted"] | None = None,
    q: str = Query(default="", max_length=200),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    return read_all_law(session, group=group, query=q, limit=limit, offset=offset)


@router.get("/law/{id_law}/my-vote", response_model=CitizenVoteView, tags=["Law"])
def my_vote(
    id_law: int,
    session: Session = Depends(get_session),
    user: User = Depends(get_current_user),
):
    read_law(session, id_law)
    return read_citizen_vote(session, id_law, user.id)


@router.put("/law/{id_law}/my-vote", response_model=CitizenVoteView, tags=["Law"])
def vote_on_law(
    id_law: int,
    choice: CitizenVoteInput,
    session: Session = Depends(get_session),
    user: User = Depends(get_current_user),
):
    return save_citizen_vote(session, id_law, user.id, choice.position)


@router.get("/law/{id_law}", response_model=LawView, tags=["Law"])
def read_law_endpoint(id_law: int, session: Session = Depends(get_session)):
    law = read_law(session, id_law)
    if law.source == "legacy" and not law.is_active:
        raise HTTPException(status_code=404, detail="Texte archivé non vérifié")
    return law


@router.post(
    "/admin/law",
    response_model=LawView,
    status_code=status.HTTP_201_CREATED,
    tags=["Admin"],
)
def add_law_endpoint(
    law: LawCreate,
    session: Session = Depends(get_session),
    user: User = Depends(get_current_user),
):
    if user.role == "admin":
        return add_law(session, law)
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to add a law",
        )


@router.patch("/admin/law/{id_law}", tags=["Admin"])
def update_law_endpoint(
    id_law: int,
    law: LawUpdate,
    session: Session = Depends(get_session),
    user: User = Depends(get_current_user),
):
    if not user.role == "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to update a law",
        )
    return update_law(session, id_law, law)


@router.delete("/admin/law/{id_law}", tags=["Admin"])
def delete_law_endpoint(
    id_law: int,
    session: Session = Depends(get_session),
    user: User = Depends(get_current_user),
):
    if not user.role == "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to delete a law",
        )
    return delete_law(session, id_law)


@router.get("/vote", response_model=list[Voteview], tags=["Vote"])
def read_all_vote_endpoint(
    session: Session = Depends(get_session), user: User = Depends(get_current_user)
):
    return read_all_vote(session)


@router.get("/vote/{id_vote}", response_model=Voteview, tags=["Vote"])
def read_vote_endpoint(
    id_vote: int,
    session: Session = Depends(get_session),
    user: User = Depends(get_current_user),
):
    return read_vote(session, id_vote)


@router.post(
    "/admin/vote",
    response_model=Voteview,
    status_code=status.HTTP_201_CREATED,
    tags=["Admin"],
)
def add_vote_endpoint(
    vote: VoteCreate,
    session: Session = Depends(get_session),
    user: User = Depends(get_current_user),
):
    if user.role == "admin":
        return add_vote(session, vote)
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to add a vote",
        )


@router.patch("/admin/vote/{id_vote}", tags=["Admin"])
def update_vote_endpoint(
    id_vote: int,
    vote: VoteUpdate,
    session: Session = Depends(get_session),
    user: User = Depends(get_current_user),
):
    if not user.role == "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to update a vote",
        )
    return update_vote(session, id_vote, vote)


@router.delete("/admin/vote/{id_vote}", tags=["Admin"])
def delete_vote_endpoint(
    id_vote: int,
    session: Session = Depends(get_session),
    user: User = Depends(get_current_user),
):
    if not user.role == "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to delete a vote",
        )
    return delete_vote(session, id_vote)
