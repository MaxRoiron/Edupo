from ...core import get_session
from .shemas import InstitutionCreate, InstitutionUpdate, InstitutionView, InstitutionTypeCreate, InstitutionTypeUpdate, InstitutionTypeView, PowerCreate, PowerUpdate, PowerView
from .model import Institution, InstitutionType, Power
from .services import (
    read_all_institution, read_institution, add_institution, delete_institution_by_id, update_institution_by_id,
    read_all_institution_type, read_institution_type, add_institution_type, delete_institution_type_by_id, update_institution_type_by_id,
    read_all_power, read_power, add_power, delete_power_by_id, update_power_by_id
)
from ..users import User, get_current_user

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session

router = APIRouter()

@router.get("/institution", response_model=list[InstitutionView], tags=["Institution"])
def get_all_institution(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_all_institution(session=session)

@router.get("/institution/{id_institution}", response_model=InstitutionView, tags=["Institution"])
def get_institution(id_institution: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_institution(session=session, id_institution=id_institution)

@router.post("/admin/institution", response_model=InstitutionView, status_code=status.HTTP_201_CREATED, tags=["Admin"])
def post_institution(institution: InstitutionCreate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return add_institution(session=session, institution=institution)

@router.delete("/admin/institution/{id_institution}", tags=["Admin"])
def delete_institution(id_institution: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return delete_institution_by_id(id_institution=id_institution, session=session)

@router.patch("/admin/institution/{id_institution}", response_model=InstitutionView, tags=["Admin"])
def patch_institution(id_institution: int, institution_update: InstitutionUpdate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return update_institution_by_id(id_institution=id_institution, institution_update=institution_update, session=session)

@router.get("/institution_type", response_model=list[InstitutionTypeView], tags=["Institution"])
def get_all_institution_type(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_all_institution_type(session=session)

@router.get("/institution_type/{id_institution_type}", response_model=InstitutionTypeView, tags=["Institution"])
def get_institution_type(id_institution_type: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_institution_type(session=session, id_institution_type=id_institution_type)

@router.post("/admin/institution_type", response_model=InstitutionTypeView, status_code=status.HTTP_201_CREATED, tags=["Admin"])
def post_institution_type(institution_type: InstitutionTypeCreate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return add_institution_type(session=session, institution_type=institution_type)

@router.delete("/admin/institution_type/{id_institution_type}", tags=["Admin"])
def delete_institution_type(id_institution_type: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return delete_institution_type_by_id(id_institution_type=id_institution_type, session=session)

@router.patch("/admin/institution_type/{id_institution_type}", response_model=InstitutionTypeView, tags=["Admin"])
def patch_institution_type(id_institution_type: int, institution_type_update: InstitutionTypeUpdate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return update_institution_type_by_id(id_institution_type=id_institution_type, institution_type_update=institution_type_update, session=session)

@router.get("/power", response_model=list[PowerView], tags=["Institution"])
def get_all_power(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_all_power(session=session)

@router.get("/power/{id_power}", response_model=PowerView, tags=["Institution"])
def get_power(id_power: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_power(session=session, id_power=id_power)

@router.post("/admin/power", response_model=PowerView, status_code=status.HTTP_201_CREATED, tags=["Admin"])
def post_power(power: PowerCreate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return add_power(session=session, power=power)

@router.delete("/admin/power/{id_power}", tags=["Admin"])
def delete_power(id_power: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return delete_power_by_id(id_power=id_power, session=session)

@router.patch("/admin/power/{id_power}", response_model=PowerView, tags=["Admin"])
def patch_power(id_power: int, power_update: PowerUpdate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return update_power_by_id(id_power=id_power, power_update=power_update, session=session)
