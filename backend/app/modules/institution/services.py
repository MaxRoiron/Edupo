from sqlmodel import Session
from fastapi import HTTPException, status
from .model import Institution, InstitutionType, Power
from .shemas import (
    InstitutionCreate, InstitutionUpdate, 
    InstitutionTypeCreate, InstitutionTypeUpdate, 
    PowerCreate, PowerUpdate
)

def read_all_institution(session: Session):
    return session.query(Institution).all()

def read_institution(session: Session, id_institution: int):
    return session.query(Institution).filter(Institution.id == id_institution).first()

def add_institution(session: Session, institution: InstitutionCreate):
    db_institution = Institution.model_validate(institution)
    session.add(db_institution)
    session.commit()
    session.refresh(db_institution)
    return db_institution

def delete_institution_by_id(id_institution: int, session: Session):
    db_institution = session.query(Institution).filter(Institution.id == id_institution).first()
    if db_institution is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution can't be found")
    session.delete(db_institution)
    session.commit()
    return True

def update_institution_by_id(id_institution: int, institution_update: InstitutionUpdate, session: Session):
    db_institution = session.query(Institution).filter(Institution.id == id_institution).first()
    if db_institution is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution can't be found")
    institution_data = institution_update.model_dump(exclude_unset=True)
    for key, value in institution_data.items():
        setattr(db_institution, key, value)
    session.add(db_institution)
    session.commit()
    session.refresh(db_institution)
    return db_institution

def read_all_institution_type(session: Session):
    return session.query(InstitutionType).all()

def read_institution_type(session: Session, id_institution_type: int):
    return session.query(InstitutionType).filter(InstitutionType.id == id_institution_type).first()

def add_institution_type(session: Session, institution_type: InstitutionTypeCreate):
    db_institution_type = InstitutionType.model_validate(institution_type)
    session.add(db_institution_type)
    session.commit()
    session.refresh(db_institution_type)
    return db_institution_type

def delete_institution_type_by_id(id_institution_type: int, session: Session):
    db_institution_type = session.query(InstitutionType).filter(InstitutionType.id == id_institution_type).first()
    if db_institution_type is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution type can't be found")
    session.delete(db_institution_type)
    session.commit()
    return True

def update_institution_type_by_id(id_institution_type: int, institution_type_update: InstitutionTypeUpdate, session: Session):
    db_institution_type = session.query(InstitutionType).filter(InstitutionType.id == id_institution_type).first()
    if db_institution_type is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution type can't be found")
    institution_type_data = institution_type_update.model_dump(exclude_unset=True)
    for key, value in institution_type_data.items():
        setattr(db_institution_type, key, value)
    session.add(db_institution_type)
    session.commit()
    session.refresh(db_institution_type)
    return db_institution_type

def read_all_power(session: Session):
    return session.query(Power).all()

def read_power(session: Session, id_power: int):
    return session.query(Power).filter(Power.id == id_power).first()

def add_power(session: Session, power: PowerCreate):
    db_power = Power.model_validate(power)
    session.add(db_power)
    session.commit()
    session.refresh(db_power)
    return db_power

def delete_power_by_id(id_power: int, session: Session):
    db_power = session.query(Power).filter(Power.id == id_power).first()
    if db_power is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Power can't be found")
    session.delete(db_power)
    session.commit()
    return True

def update_power_by_id(id_power: int, power_update: PowerUpdate, session: Session):
    db_power = session.query(Power).filter(Power.id == id_power).first()
    if db_power is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Power can't be found")
    power_data = power_update.model_dump(exclude_unset=True)
    for key, value in power_data.items():
        setattr(db_power, key, value)
    session.add(db_power)
    session.commit()
    session.refresh(db_power)
    return db_power
