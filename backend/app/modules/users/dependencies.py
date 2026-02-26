from ...core import get_session, decode_access_token
from ..users import get_user_by_id, User

from sqlmodel import Session
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

oauth2_sheme = OAuth2PasswordBearer(tokenUrl="/user/login")

def get_current_user(token: str = Depends(oauth2_sheme), session: Session = Depends(get_session)) -> User:
    payload = decode_access_token(token=token)
    if payload is None or payload.get("user_id", None) is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    user = get_user_by_id(session=session, id=payload.get("user_id"))
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user