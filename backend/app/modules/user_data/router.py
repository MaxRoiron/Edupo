from ...core import get_session
from ..user_data import UserDataCreate, UserDataUpdate, UserDataView, get_user_data_by_user_id, add_user_data, update_user_data, reset_user_data
from ..users import User, get_current_user, get_user_by_email

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session

router = APIRouter()

@router.post("/me/data", response_model=UserDataView, tags=["User"])
async def post_user_data(user_data: UserDataCreate, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    db_user_data = get_user_data_by_user_id(session=session, user=user)
    if db_user_data is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="User's data already created")
    return add_user_data(session=session, user_data=user_data)

@router.get("/me/data", response_model=UserDataView, tags=["User"])
async def get_user_data(user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    user_data = get_user_data_by_user_id(session=session, user=user)
    if user_data is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User's data can't be found")
    return UserDataView(
        id=user_data.id,
        age=user_data.age,
        professional_status_id=user_data.professional_status_id,
        social_status_id=user_data.social_status_id,
        gender_identity_id=user_data.gender_identity_id
    )

@router.patch("/me/data", response_model=UserDataView, tags=["User"])
async def patch_user_data(data: UserDataUpdate, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    user_data = get_user_data_by_user_id(session=session, user=user)
    if user_data is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User's data can't be found")
    return update_user_data(session=session, user_data=user_data, data_update=data)

@router.put("/me/data/reset", response_model=UserDataView, tags=["User"])
async def reset_user_datas(current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return reset_user_data(email=current_user.email, session=session, user=current_user)

@router.put("/admin/{user_email}/reset", response_model=UserDataView, tags=["Admin"])
async def reset_user_datas(user_email: str, current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    user_to_reset = get_user_by_email(session=session, email=user_email)
    return reset_user_data(session=session, user_data=user_to_reset.user_data)