from sqlmodel import Session, select
from fastapi import HTTPException, status
from .model import Country
from .shemas import CountryCreate, CountryUpdate

def read_all_country(session: Session):
    return session.exec(select(Country)).all()

def get_country_by_id(id_country: int, session: Session):
    country = session.exec(select(Country).where(Country.id == id_country)).first()
    if not country:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Country not found")
    return country

def add_country(session: Session, country: CountryCreate):
    country = Country.model_validate(country)
    session.add(country)
    session.commit()
    session.refresh(country)
    return country

def update_country_by_id(id_country: int, country_update: CountryUpdate, session: Session):
    country = session.exec(select(Country).where(Country.id == id_country)).first()
    if not country:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Country not found")
    country_update_data = country_update.model_dump(exclude_unset=True)
    for key, value in country_update_data.items():
        setattr(country, key, value)
    session.add(country)
    session.commit()
    session.refresh(country)
    return country

def delete_country_by_id(id_country: int, session: Session):
    country = session.exec(select(Country).where(Country.id == id_country)).first()
    if not country:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Country not found")
    session.delete(country)
    session.commit()
    return {"message": "Country deleted successfully"}