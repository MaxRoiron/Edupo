from ...core import get_session, verify_password, create_access_token
from ..users import UserCreate, UserView, get_user_by_email, add_user, get_current_user, User, UserUpdate, update_user, Token, LoginRequest, delete_user_by_email

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session

router = APIRouter()

@router.post("/register", response_model=Token, tags=["OAuth"])
async def register(user: UserCreate, session: Session = Depends(get_session)) -> Token:
    db_user = get_user_by_email(session, user.email)
    if db_user is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already used by an account")
    db_user = add_user(session=session, user=user)
    access_token = create_access_token(data={"user_id": db_user.id})
    return Token(
        access_token=access_token,
        token_type="bearer"
    )

@router.post("/login", response_model=Token, tags=["OAuth"])
async def login(login: LoginRequest, session: Session = Depends(get_session)) -> Token:
    db_user = get_user_by_email(session=session, email=login.email)
    if db_user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    if verify_password(login.password, db_user.hashed_password) is False:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    access_token = create_access_token(data={"user_id": db_user.id})
    return Token(
        access_token=access_token,
        token_type="bearer"
    )



@router.get("/me", response_model=UserView, tags=["User"])
async def read_me(current_user: User = Depends(get_current_user)):
    return UserView(
        id=current_user.id,
        username=current_user.username,
        email=current_user.email,
        role=current_user.role,
        ggid=current_user.ggid,
        created_at=current_user.created_at
    )


@router.patch("/me", response_model=UserView, tags=["User"])
async def patch_me(user_update: UserUpdate, current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    return update_user(session=session, user=current_user, user_update=user_update)


@router.delete("/me", tags=["User"])
async def delete_user(current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if current_user.role == "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin account can't be deleted themself")
    return delete_user_by_email(email=current_user.email, user=current_user, session=session)

@router.delete("/admin/{user_email}", tags=["Admin"])
async def delete_user(user_email: str, current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    if current_user.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="You don't have the required authorization")
    return delete_user_by_email(email=user_email, user=current_user, session=session)