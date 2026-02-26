from pydantic import BaseModel

class UserCreate(BaseModel):
    username: str
    email: str
    password: str
    ggid: int | None = None

class UserView(BaseModel):
    id: int
    username: str
    email: str
    role: str
    ggid: str | None

class UserUpdate(BaseModel):
    username: str | None = None
    email: str | None = None
    password: str | None = None
    role: str | None = None
    ggid: str | None = None

class LoginRequest(BaseModel):
    email: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: str | None = None