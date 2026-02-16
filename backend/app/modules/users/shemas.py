from sqlmodel import SQLModel

class UserCreate(SQLModel):
    username: str
    email: str
    password: str

class UserView(SQLModel):
    id: int
    username: str
    email: str
    role: str

class UserUpdate(SQLModel):
    username: str | None = None
    email: str | None = None
    password: str | None = None
    role: str | None = None

class Token(SQLModel):
    access_token: str
    token_type: str

class TokenData(SQLModel):
    email: str | None = None