from ..user_data import UserData, UserDataView, UserDataCreate, UserDataUpdate
from ..users import User, get_user_by_email

from sqlmodel import Session, select
from fastapi import HTTPException, status

def get_user_data_by_user_id(session: Session, user: User) -> UserData | None:
    return session.exec(select(UserData).where(UserData.user_id == user.id)).first()

def get_user_data_by_user_email(email: str, session: Session) -> UserData | None:
    user = get_user_by_email(session=session, email=email)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User ({email}) not found")
    return get_user_data_by_user_id(session=session, user=user)

def add_user_data(session: Session, user_data: UserDataCreate) -> UserDataView:
    db_user_data = UserData(
        age=user_data.age,
        user_id=user_data.user_id,
        professional_status_id=user_data.professional_status_id,
        social_status_id=user_data.social_status_id,
        gender_identity_id=user_data.gender_identity_id
    )
    session.add(db_user_data)
    session.commit()
    session.refresh(db_user_data)
    return UserDataView(
        id=db_user_data.id,
        age=db_user_data.age,
        professional_status_id=db_user_data.professional_status_id,
        social_status_id=db_user_data.social_status_id,
        gender_identity_id=db_user_data.gender_identity_id
    )

def update_user_data(session: Session, user_data: UserData, data_update: UserDataUpdate) -> UserDataView:
    if data_update.age is not None:
        user_data.age = data_update.age

    if data_update.professional_status_id is not None:
        user_data.professional_status_id = data_update.professional_status_id

    if data_update.social_status_id is not None:
        user_data.social_status_id = data_update.social_status_id

    if data_update.gender_identity_id is not None:
        user_data.gender_identity_id = data_update.gender_identity_id

    session.add(user_data)
    session.commit()
    session.refresh(user_data)
    return UserDataView(
        id=user_data.id,
        age=user_data.age,
        professional_status_id=user_data.professional_status_id,
        social_status_id=user_data.social_status_id,
        gender_identity_id=user_data.gender_identity_id
    )

def reset_user_data_by_email(email: str, session: Session, user: User) -> UserDataView:
    if user.role != "admin":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="You don't have the required authorization")
    user_data = get_user_data_by_user_email(email=email, session=session)
    if user_data is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User ({email})'s data can't be found")
    user_data.age = None
    user_data.professional_status_id = None
    user_data.social_status_id = None
    user_data.gender_identity_id = None

    session.add(user_data)
    session.commit()
    session.refresh(user_data)
    return UserDataView(
        id=user_data.id,
        age=user_data.age,
        professional_status_id=user_data.professional_status_id,
        social_status_id=user_data.social_status_id,
        gender_identity_id=user_data.gender_identity_id
    )