from ...core import get_password_hash
from ..users import UserCreate, User, UserView, UserUpdate

from sqlmodel import Session, select
from fastapi import HTTPException, status
import datetime

def get_user_by_id(session: Session, id: int) -> User | None:
    return session.exec(select(User).where(User.id == id)).first()

def get_user_by_ggid(session: Session, ggid: int) -> User | None:
    return session.exec(select(User).where(User.ggid == ggid)).first()

def get_user_by_email(session: Session, email: str) -> User | None:
    return session.exec(select(User).where(User.email == email)).first()

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
    if user.role != "admin":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="You don't have the required authorization")
    user_to_delete = get_user_by_email(session=session, email=email)
    if user_to_delete is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User ({email}) not found")
    if user.email == email:
        raise HTTPException(status_code=status.HTTP_405_METHOD_NOT_ALLOWED, detail="You can't delete yourself")
    session.delete(user_to_delete)
    session.commit()
    return {"message": f"User ({email}) has been deleted"}