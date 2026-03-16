from ...core import get_session
from ..users import User, get_current_user
from fastapi import APIRouter, Depends, HTTPException, status
from .shemas import PoliticalFigureCreate, PoliticalFigureUpdate, PoliticalFigureView
from .shemas import PoliticalRoleCreate, PoliticalRoleUpdate, PoliticalRoleView
from .services import read_all_political_figure, read_political_figure, add_political_figure, update_political_figure, delete_political_figure
from .services import read_all_political_role, read_political_role, add_political_role, update_political_role, delete_political_role

from sqlmodel import Session

router = APIRouter()

@router.get("/political-figure", response_model=list[PoliticalFigureView], tags=["Political Figure"])
def read_all_political_figure_endpoint(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_all_political_figure(session)

@router.get("/political-figure/{id_political_figure}", response_model=PoliticalFigureView, tags=["Political Figure"])
def read_political_figure_endpoint(id_political_figure: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    return read_political_figure(session, id_political_figure)

@router.post("/admin/political-figure", response_model=PoliticalFigureView, tags=["Admin"])
def add_political_figure_endpoint(political_figure: PoliticalFigureCreate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if user.role == "admin":
        return add_political_figure(session, political_figure)
    else:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to add a political figure")

@router.patch("/admin/political-figure/{id_political_figure}", tags=["Admin"])
def update_political_figure_endpoint(id_political_figure: int, political_figure: PoliticalFigureUpdate, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.role == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to update a political figure")
    return update_political_figure(session, id_political_figure, political_figure)

@router.delete("/admin/political-figure/{id_political_figure}", tags=["Admin"])
def delete_political_figure_endpoint(id_political_figure: int, session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    if not user.role == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have permission to delete a political figure")
    return delete_political_figure(session, id_political_figure)
