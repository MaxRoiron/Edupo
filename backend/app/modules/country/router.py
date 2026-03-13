from ...core import get_session
from .model import Country
from .shemas import CountryCreate, CountryUpdate, CountryView
from .services import add_country, update_country_by_id, delete_country_by_id, get_country_by_id, read_all_country

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session

from ..users import User, get_current_user

router = APIRouter()

@router.get("/country", response_model=list[CountryView], tags=["Country"])
def read_all_country_endpoint(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_all_country(session)

@router.get("/country/{id_country}", response_model=CountryView, tags=["Country"])
def read_country_endpoint(id_country: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return get_country_by_id(id_country, session)

@router.post("/admin/country", response_model=CountryView, tags=["Admin"])
def add_country_endpoint(country: CountryCreate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return add_country(session, country)

@router.patch("/admin/country/{id_country}", response_model=CountryView, tags=["Admin"])
def update_country_endpoint(id_country: int, country_update: CountryUpdate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return update_country_by_id(id_country, country_update, session)

@router.delete("/admin/country/{id_country}", tags=["Admin"])
def delete_country_endpoint(id_country: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return delete_country_by_id(id_country, session)