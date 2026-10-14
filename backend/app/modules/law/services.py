from sqlmodel import Session, select
from sqlalchemy import or_, func, text
from .text import clean_law_title, subject_title, relevance_score
from datetime import datetime, timezone
from fastapi import HTTPException, status
from .model import Law, Vote
from .shemas import LawView, LawCreate, LawUpdate, VoteCreate, Voteview, VoteUpdate


def read_all_law(
    session: Session,
    group: str | None = None,
    query: str = "",
    limit: int = 50,
    offset: int = 0,
):
    statement = select(Law).where(Law.is_active == True)
    if group == "pending":
        statement = statement.where(Law.status == "pending")
    elif group == "voted":
        statement = statement.where(
            Law.status.in_(["adopted", "rejected", "promulgated"])
        )
    if query.strip():
        if session.get_bind().dialect.name == "postgresql":
            statement = statement.where(
                text(
                    "to_tsvector('french', coalesce(title, '') || ' ' || coalesce(description, '')) @@ plainto_tsquery('french', :law_search)"
                ).bindparams(law_search=query.strip())
            )
        else:
            escaped = (
                query.strip()
                .replace("\\", "\\\\")
                .replace("%", "\\%")
                .replace("_", "\\_")
            )
            pattern = f"%{escaped}%"
            statement = statement.where(
                or_(
                    Law.title.ilike(pattern, escape="\\"),
                    Law.description.ilike(pattern, escape="\\"),
                )
            )
    statement = statement.order_by(
        func.coalesce(
            Law.activity_at, Law.vote_date, Law.published_at, Law.updated_at
        ).desc(),
        Law.relevance.desc(),
        Law.id.desc(),
    )
    return session.exec(statement.offset(offset).limit(limit)).all()


def read_law(session: Session, id_law: int):
    law = session.exec(select(Law).where(Law.id == id_law)).first()
    if law and law.merged_into_id:
        return read_law(session, law.merged_into_id)
    if not law:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Law not found"
        )
    return law


def add_law(session: Session, law: LawCreate):
    db_law = Law.model_validate(law)
    db_law.hidden_by_admin = not law.is_active
    db_law.official_title = law.title
    db_law.short_title = subject_title(law.title)
    db_law.title = clean_law_title(law.title)
    db_law.relevance = relevance_score(law.title, law.description)
    session.add(db_law)
    session.commit()
    session.refresh(db_law)
    return db_law


def update_law(session: Session, id_law: int, law: LawUpdate):
    db_law = session.exec(select(Law).where(Law.id == id_law)).first()
    if not db_law:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Law not found"
        )
    law_data = law.model_dump(exclude_unset=True)
    for key, value in law_data.items():
        setattr(db_law, key, value)
    if "is_active" in law_data:
        db_law.hidden_by_admin = not law_data["is_active"]
    if "title" in law_data:
        db_law.official_title = law_data["title"]
        db_law.short_title = subject_title(law_data["title"])
        db_law.title = clean_law_title(law_data["title"])
    db_law.updated_at = datetime.now(timezone.utc)
    db_law.relevance = relevance_score(
        db_law.official_title or db_law.title, db_law.description
    )
    session.add(db_law)
    session.commit()
    session.refresh(db_law)
    return db_law


def delete_law(session: Session, id_law: int):
    db_law = session.exec(select(Law).where(Law.id == id_law)).first()
    if not db_law:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Law not found"
        )
    db_law.is_active = False
    db_law.hidden_by_admin = True
    session.add(db_law)
    session.commit()
    return {"message": "Law deleted successfully"}


def read_all_vote(session: Session):
    return session.exec(select(Vote)).all()


def read_vote(session: Session, id_vote: int):
    vote = session.exec(select(Vote).where(Vote.id == id_vote)).first()
    if not vote:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="vote not found"
        )
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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="vote not found"
        )
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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="vote not found"
        )
    session.delete(db_vote)
    session.commit()
    return {"message": "vote deleted successfully"}


def read_citizen_vote(session: Session, law_id: int, user_id: int) -> dict:
    from app.modules.user_vote.model import UserVote

    law_id = read_law(session, law_id).id
    position = session.exec(
        select(Vote.position)
        .join(UserVote, UserVote.position_id == Vote.id)
        .where(UserVote.user_id == user_id, UserVote.law_id == law_id)
    ).first()
    return {"law_id": law_id, "position": position}


def save_citizen_vote(
    session: Session, law_id: int, user_id: int, position: str
) -> dict:
    from app.modules.user_vote.model import UserVote
    from sqlalchemy.dialects.postgresql import insert as pg_insert
    from sqlalchemy.dialects.sqlite import insert as sqlite_insert

    law = read_law(session, law_id)
    law_id = law.id
    if not law.is_active or law.status != "pending":
        raise HTTPException(
            status_code=409, detail="Le vote citoyen est fermé pour ce texte"
        )
    insert = (
        pg_insert if session.get_bind().dialect.name == "postgresql" else sqlite_insert
    )
    session.execute(
        insert(Vote)
        .values(position=position)
        .on_conflict_do_nothing(index_elements=["position"])
    )
    vote = session.exec(select(Vote).where(Vote.position == position)).one()
    statement = insert(UserVote).values(
        user_id=user_id, law_id=law_id, position_id=vote.id
    )
    session.execute(
        statement.on_conflict_do_update(
            index_elements=["user_id", "law_id"], set_={"position_id": vote.id}
        )
    )
    session.commit()
    return {"law_id": law_id, "position": position}
