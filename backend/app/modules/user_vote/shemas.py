from pydantic import BaseModel

class UserVote(BaseModel):
    user_id: int
    law_id: int
    position_id: int

class UserVote(BaseModel):
    user_id: int | None = None
    law_id: int | None = None
    position_id: int | None = None

class UserVote(BaseModel):
    id: int
    user_id: int
    law_id: int
    position_id: int