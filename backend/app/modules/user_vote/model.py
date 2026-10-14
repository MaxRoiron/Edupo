from ..law import Vote, Law

from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import UniqueConstraint


class UserVote(SQLModel, table=True):
    __table_args__ = (
        UniqueConstraint("user_id", "law_id", name="uq_uservote_user_law"),
    )
    id: int = Field(default=None, primary_key=True)
    user_id: int = Field(index=True, foreign_key="user.id", ondelete="CASCADE")
    law_id: int = Field(index=True, foreign_key="law.id")
    position_id: int = Field(index=True, foreign_key="vote.id")

    position: Vote = Relationship()
    law: Law = Relationship()
