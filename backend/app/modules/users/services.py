from ...core import get_password_hash
from .model import User
from .shemas import UserCreate, UserView, UserUpdate, AdminUserView

from sqlmodel import Session, select
from fastapi import HTTPException, status
import datetime

def get_user_by_id(session: Session, id: int) -> User | None:
    return session.exec(select(User).where(User.id == id)).first()

def get_user_by_ggid(session: Session, ggid: int) -> User | None:
    return session.exec(select(User).where(User.ggid == ggid)).first()

def get_user_by_email(session: Session, email: str) -> User | None:
    return session.exec(select(User).where(User.email == email)).first()

def get_all_users(session: Session) -> list[AdminUserView]:
    from ..user_data.model import UserData, GenderIdentities, ProfessionalStatus
    users = session.exec(select(User)).all()
    results = []
    for u in users:
        user_data = session.exec(select(UserData).where(UserData.user_id == u.id)).first()
        gender = None
        profession = None
        if user_data:
            if user_data.gender_identity_id:
                gi = session.exec(select(GenderIdentities).where(GenderIdentities.id == user_data.gender_identity_id)).first()
                gender = gi.name if gi else None
            if user_data.professional_status_id:
                ps = session.exec(select(ProfessionalStatus).where(ProfessionalStatus.id == user_data.professional_status_id)).first()
                profession = ps.name if ps else None

        results.append(
            AdminUserView(
                id=u.id, username=u.username, email=u.email,
                role=u.role, created_at=u.created_at,
                age=user_data.age if user_data else None,
                phone_number=user_data.phone_number if user_data else None,
                gender=gender,
                profession=profession
            )
        )
    return results

def add_user(session: Session, user: UserCreate) -> UserView:
    hashed_password = get_password_hash(password=user.password)
    db_user = User(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password,
        role="user",
        ggid=user.ggid,
        created_at=datetime.datetime.now(datetime.UTC)
    )
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return UserView(
        id=db_user.id,
        username=db_user.username,
        email=db_user.email,
        role=db_user.role,
        ggid=db_user.ggid,
        created_at=db_user.created_at
    )

def update_user(session: Session, user: User, user_update: UserUpdate) -> UserView:
    if user_update.username is not None:
        user.username = user_update.username

    if user_update.email is not None:
        existing_user = session.exec(select(User).where(User.email == user_update.email)).first()
        if existing_user is not None and existing_user.id != user.id:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already used")
        user.email = user_update.email

    if user_update.password is not None:
        user.hashed_password = get_password_hash(user_update.password)

    session.add(user)
    session.commit()
    session.refresh(user)
    return UserView(
        id=user.id,
        username=user.username,
        email=user.email,
        role=user.role,
        ggid=user.ggid,
        created_at=user.created_at
    )

def delete_user_by_email(email: str, user: User, session: Session):
    user_to_delete = get_user_by_email(session=session, email=email)
    if user_to_delete is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User ({email}) not found")
    if user_to_delete.role == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You can't delete yourself")
    session.delete(user_to_delete)
    session.commit()
    return {"message": f"User ({email}) has been deleted"}