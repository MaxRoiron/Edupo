from app.modules.country import Country, get_country_by_id, update_country_by_id, CountryUpdate, delete_country_by_id

import pytest
from sqlmodel import Session
from fastapi import HTTPException, status

def add_country(session: Session):
    data = Country(
        name="testCountry",
        iso_code="TC"
    )
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def test_get_nonexistent_country(session):
    with pytest.raises(HTTPException) as raise_value:
        get_country_by_id(id_country=1, session=session)
    assert raise_value.value.status_code == status.HTTP_404_NOT_FOUND

def test_update_nonexistent_country(session):
    with pytest.raises(HTTPException) as raise_value:
        update_country_by_id(id_country=1, country_update=CountryUpdate(), session=session)
    assert raise_value.value.status_code == status.HTTP_404_NOT_FOUND

def test_update_country_with_values(session):
    country = add_country(session=session)
    updt_country = update_country_by_id(id_country=1, country_update=CountryUpdate(name="updatedName"), session=session)
    assert updt_country.name == "updatedName"

def test_delete_nonexistent_country(session):
    with pytest.raises(HTTPException) as raise_value:
        delete_country_by_id(id_country=1, session=session)
    assert raise_value.value.status_code == status.HTTP_404_NOT_FOUND