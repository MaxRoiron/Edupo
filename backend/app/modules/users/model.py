from sqlmodel import SQLModel, Field
import datetime

class User(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    username: str = Field(index=True, nullable=False)
    email: str = Field(index=True, unique=True, nullable=False)
    hashed_password: str = Field(nullable=False)
    role: str = Field(index=True, nullable=False)
    ggid: str | None = Field(default=None)
    created_at: datetime.datetime = Field(default_factory=lambda: datetime.datetime.now(datetime.UTC), nullable=False)