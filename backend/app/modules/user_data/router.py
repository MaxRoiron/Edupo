from ...core import get_session
from ..user_data import UserDataCreate, UserDataUpdate, UserDataView, add_user_data, update_user_data, reset_user_data
from ..user_data import ProfessionalStatusCreate, ProfessionalStatusUpdate, ProfessionalStatusView, add_professional_status, update_professional_status_by_id, delete_professional_status_by_id, get_professional_status_by_id, read_all_professional_status
from ..user_data import SocialStatusCreate, SocialStatusUpdate, SocialStatusView, add_social_status, update_social_status_by_id, delete_social_status_by_id, get_social_status_by_id, read_all_social_status
from ..user_data import GenderIdentitiesCreate, GenderIdentitiesUpdate, GenderIdentitiesView, add_gender, update_gender_by_id, delete_gender_by_id, get_gender_by_id, read_all_gender
from ..users import User, get_current_user, get_user_by_email

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session

router = APIRouter()

@router.post("/me/data", response_model=UserDataView, status_code=status.HTTP_201_CREATED, tags=["User"])
async def post_user_data(user_data: UserDataCreate, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    db_user_data = user.user_data
    if db_user_data is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="User's data already created")
    return add_user_data(session=session, user_data=user_data, user_id=user.id)

@router.get("/me/data", response_model=UserDataView, tags=["User"])
async def get_user_data(user: User = Depends(get_current_user)):
    user_data = user.user_data
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
    user_data = user.user_data
    if user_data is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User's data can't be found")
    return update_user_data(session=session, user_data=user_data, data_update=data)

@router.put("/me/data/reset", response_model=UserDataView, tags=["User"])
async def reset_user_datas(current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return reset_user_data(session=session, user_data=current_user.user_data)

@router.put("/admin/{user_email}/reset", response_model=UserDataView, tags=["Admin"])
async def reset_user_datas(user_email: str, current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if current_user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    user_to_reset = get_user_by_email(session=session, email=user_email)
    return reset_user_data(session=session, user_data=user_to_reset.user_data)





@router.post("/admin/user_data/professional", response_model=ProfessionalStatusView, status_code=status.HTTP_201_CREATED, tags=["Admin"])
async def post_professional_status(status: ProfessionalStatusCreate, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return add_professional_status(status=status, session=session)

@router.get("/user_data/professional", response_model=list[ProfessionalStatusView], tags=["UserData Content"])
async def get_all_professional_status(status_id: int, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return read_all_professional_status(status_id=status_id, session=session)

@router.get("/user_data/professional/{status_id}", response_model=ProfessionalStatusView, tags=["UserData Content"])
async def get_professional_status(status_id: int, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return get_professional_status_by_id(status_id=status_id, session=session)

@router.patch("/admin/user_data/professional/{status_id}", response_model=ProfessionalStatusView, tags=["Admin"])
async def patch_professional_status(status_id: int, update_data: ProfessionalStatusUpdate, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return update_professional_status_by_id(status_id=status_id, update_data=update_data, session=session)

@router.delete("/admin/user_data/professional/{status_id}", response_model=ProfessionalStatusView, tags=["Admin"])
async def delete_professional_status(status_id: int, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return delete_professional_status_by_id(status_id=status_id, session=session)





@router.post("/admin/user_data/social", response_model=SocialStatusView, status_code=status.HTTP_201_CREATED, tags=["Admin"])
async def post_social_status(status: SocialStatusCreate, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return add_social_status(status=status, session=session)

@router.get("/user_data/social", response_model=list[SocialStatusView], tags=["UserData Content"])
async def get_all_social_status(status_id: int, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return read_all_social_status(status_id=status_id, session=session)

@router.get("/user_data/social/{status_id}", response_model=SocialStatusView, tags=["UserData Content"])
async def get_social_status(status_id: int, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return get_social_status_by_id(status_id=status_id, session=session)

@router.patch("/admin/user_data/social/{status_id}", response_model=SocialStatusView, tags=["Admin"])
async def patch_social_status(status_id: int, update_data: SocialStatusUpdate, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return update_social_status_by_id(status_id=status_id, update_data=update_data, session=session)

@router.delete("/admin/user_data/social/{status_id}", response_model=SocialStatusView, tags=["Admin"])
async def delete_social_status(status_id: int, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return delete_social_status_by_id(status_id=status_id, session=session)





@router.post("/admin/user_data/gender", response_model=GenderIdentitiesView, status_code=status.HTTP_201_CREATED, tags=["Admin"])
async def post_gender(status: GenderIdentitiesCreate, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return add_gender(status=status, session=session)

@router.get("/user_data/gender", response_model=list[GenderIdentitiesView], tags=["UserData Content"])
async def get_all_gender(status_id: int, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return read_all_gender(status_id=status_id, session=session)

@router.get("/user_data/gender/{status_id}", response_model=GenderIdentitiesView, tags=["UserData Content"])
async def get_gender(status_id: int, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return get_gender_by_id(status_id=status_id, session=session)

@router.patch("/admin/user_data/gender/{status_id}", response_model=GenderIdentitiesView, tags=["Admin"])
async def patch_gender(status_id: int, update_data: GenderIdentitiesUpdate, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return update_gender_by_id(status_id=status_id, update_data=update_data, session=session)

@router.delete("/admin/user_data/gender/{status_id}", response_model=GenderIdentitiesView, tags=["Admin"])
async def delete_gender(status_id: int, user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if user.role == "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return delete_gender_by_id(status_id=status_id, session=session)