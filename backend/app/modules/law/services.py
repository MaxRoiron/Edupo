from sqlmodel import Session, select
from fastapi import HTTPException, status
from .model import Law, Vote, VoteResult
from .shemas import LawView, LawCreate, LawUpdate, VoteCreate, Voteview, VoteUpdate, VoteResultCreate, VoteResultTypeUpdate, VoteResultTypeView

def read_all_law(session: Session):
    return session.exec(select(Law)).all()

def read_law(session: Session, id_law: int):
    law = session.exec(select(Law).where(Law.id == id_law)).first()
    if not law:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Law not found")
    return law

def add_law(session: Session, law: LawCreate):
    db_law = Law.model_validate(law)
    session.add(db_law)
    session.commit()
    session.refresh(db_law)
    return db_law

def update_law(session: Session, id_law: int, law: LawUpdate):
    db_law = session.exec(select(Law).where(Law.id == id_law)).first()
    if not db_law:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Law not found")
    law_data = law.model_dump(exclude_unset=True)
    for key, value in law_data.items():
        setattr(db_law, key, value)
    session.add(db_law)
    session.commit()
    session.refresh(db_law)
    return db_law

def delete_law(session: Session, id_law: int):
    db_law = session.exec(select(Law).where(Law.id == id_law)).first()
    if not db_law:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Law not found")
    session.delete(db_law)
    session.commit()
    return {"message": "Law deleted successfully"}  

def read_all_vote(session: Session):
    return session.exec(select(Vote)).all()

def read_vote(session: Session, id_vote: int):
    vote = session.exec(select(Vote).where(Vote.id == id_vote)).first()
    if not vote:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="vote not found")
    return vote

def add_vote(session: Session, vote: VoteCreate):
    db_vote = Vote.model_validate(vote)
    session.add(db_vote)
    session.commit()
    session.refresh(db_vote)
    return db_vote

def update_vote(session: Session, id_vote: int, vote: VoteUpdate):
    db_vote = session.exec(select(Vote).where(Vote.id == id_vote)).first()
    if not db_vote:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="vote not found")
    vote_data = vote.model_dump(exclude_unset=True)
    for key, value in vote_data.items():
        setattr(db_vote, key, value)
    session.add(db_vote)
    session.commit()
    session.refresh(db_vote)
    return db_vote

def delete_vote(session: Session, id_vote: int):
    db_vote = session.exec(select(Vote).where(Vote.id == id_vote)).first()
    if not db_vote:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="vote not found")
    session.delete(db_vote)
    session.commit()
    return {"message": "vote deleted successfully"}

def read_all_vote_result(session: Session):
    return session.exec(select(VoteResult)).all()

def read_vote_result(session: Session, id_vote_result: int):
    vote_result = session.exec(select(VoteResult).where(VoteResult.id == id_vote_result)).first()
    if not vote_result:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vote result not found")
    return vote_result

def add_vote_result(session: Session, vote_result: VoteResultCreate):
    db_vote_result = VoteResult.model_validate(vote_result)
    session.add(db_vote_result)
    session.commit()
    session.refresh(db_vote_result)
    return db_vote_result

def update_vote_result(session: Session, id_vote_result: int, vote_result: VoteResultTypeUpdate):
    db_vote_result = session.exec(select(VoteResult).where(VoteResult.id == id_vote_result)).first()
    if not db_vote_result:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vote result not found")
    vote_result_data = vote_result.model_dump(exclude_unset=True)
    for key, value in vote_result_data.items():
        setattr(db_vote_result, key, value)
    session.add(db_vote_result)
    session.commit()
    session.refresh(db_vote_result)
    return db_vote_result

def delete_vote_result(session: Session, id_vote_result: int):
    db_vote_result = session.exec(select(VoteResult).where(VoteResult.id == id_vote_result)).first()
    if not db_vote_result:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vote result not found")
    session.delete(db_vote_result)
    session.commit()
    return {"message": "Vote result deleted successfully"}