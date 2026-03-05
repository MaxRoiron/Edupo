from ..user_data import UserData, UserDataView, UserDataCreate, UserDataUpdate
from ..user_data import ProfessionalStatus, ProfessionalStatusCreate, ProfessionalStatusUpdate, ProfessionalStatusView
from ..user_data import SocialStatus, SocialStatusCreate, SocialStatusUpdate, SocialStatusView
from ..user_data import GenderIdentities, GenderIdentitiesCreate, GenderIdentitiesUpdate, GenderIdentitiesView
from ..users import get_user_by_email

from sqlmodel import Session, select
from fastapi import HTTPException, status

def get_user_data_by_user_email(email: str, session: Session) -> UserData | None:
    user = get_user_by_email(session=session, email=email)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User ({email}) not found")
    return user.user_data

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

def reset_user_data(session: Session, user_data: UserData):
    if user_data is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User's data can't be found")
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






def add_professional_status(status: ProfessionalStatusCreate, session: Session):
    db_status = ProfessionalStatus(
        name=status.name
    )
    session.add(db_status)
    session.commit()
    session.refresh(db_status)
    return ProfessionalStatusView(
        id=db_status.id,
        name=db_status.name
    )

def get_professional_status_by_id(id: int, session: Session):
    return session.exec(select(ProfessionalStatus).where(ProfessionalStatus.id == id)).first()

def read_all_professional_status(session: Session):
    return session.exec(select(ProfessionalStatus)).all()

def update_professional_status_by_id(status_id: int, update_data: ProfessionalStatusUpdate, session: Session):
    db_status = get_professional_status_by_id(id=status_id, session=session)
    if db_status is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Professional status ({status_id}) can't be found")

    if update_data.name is not None:
        db_status.name = update_data.name

    session.add(db_status)
    session.commit()
    session.refresh(db_status)
    return ProfessionalStatusView(
        id=db_status.id,
        name=db_status.name
    )

def delete_professional_status_by_id(status_id: int, session: Session):
    db_status = get_professional_status_by_id(id=status_id, session=session)
    if db_status is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Professional status ({status_id}) can't be found")

    session.delete(db_status)
    session.commit()
    return {"message": f"Professional status ({status_id}) has been deleted"}






def add_social_status(status: SocialStatusCreate, session: Session):
    db_status = SocialStatus(
        name=status.name
    )
    session.add(db_status)
    session.commit()
    session.refresh(db_status)
    return SocialStatusView(
        id=db_status.id,
        name=db_status.name
    )

def get_social_status_by_id(id: int, session: Session):
    return session.exec(select(SocialStatus).where(SocialStatus.id == id)).first()

def read_all_social_status(session: Session):
    return session.exec(select(SocialStatus)).all()

def update_social_status_by_id(status_id: int, update_data: SocialStatusUpdate, session: Session):
    db_status = get_social_status_by_id(id=status_id, session=session)
    if db_status is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Social status ({status_id}) can't be found")

    if update_data.name is not None:
        db_status.name = update_data.name

    session.add(db_status)
    session.commit()
    session.refresh(db_status)
    return SocialStatusView(
        id=db_status.id,
        name=db_status.name
    )

def delete_social_status_by_id(status_id: int, session: Session):
    db_status = get_social_status_by_id(id=status_id, session=session)
    if db_status is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Social status ({status_id}) can't be found")

    session.delete(db_status)
    session.commit()
    return {"message": f"Social status ({status_id}) has been deleted"}






def add_gender(status: GenderIdentitiesCreate, session: Session):
    db_status = GenderIdentities(
        name=status.name
    )
    session.add(db_status)
    session.commit()
    session.refresh(db_status)
    return GenderIdentitiesView(
        id=db_status.id,
        name=db_status.name
    )

def get_gender_by_id(id: int, session: Session):
    return session.exec(select(GenderIdentities).where(GenderIdentities.id == id)).first()

def read_all_gender(session: Session):
    return session.exec(select(GenderIdentities)).all()

def update_gender_by_id(status_id: int, update_data: GenderIdentitiesUpdate, session: Session):
    db_status = get_gender_by_id(id=status_id, session=session)
    if db_status is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Gender identity ({status_id}) can't be found")

    if update_data.name is not None:
        db_status.name = update_data.name

    session.add(db_status)
    session.commit()
    session.refresh(db_status)
    return GenderIdentitiesView(
        id=db_status.id,
        name=db_status.name
    )

def delete_gender_by_id(status_id: int, session: Session):
    db_status = get_gender_by_id(id=status_id, session=session)
    if db_status is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Gender identity ({status_id}) can't be found")

    session.delete(db_status)
    session.commit()
    return {"message": f"Gender identity ({status_id}) has been deleted"}