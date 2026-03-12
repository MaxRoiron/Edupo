from ..law import Vote, Law

from sqlmodel import SQLModel, Field, Relationship

class UserVote(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    user_id: int = Field(index=True, foreign_key="user.id")
    law_id: int = Field(index=True, foreign_key="law.id")
    position_id: int = Field(index=True, foreign_key="vote.id")

    position: Vote = Relationship()
    law: Law = Relationship()