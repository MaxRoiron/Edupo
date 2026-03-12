from pydantic import BaseModel

class UserVoteCreate(BaseModel):
    user_id: int
    law_id: int
    position_id: int

class UserVoteUpdate(BaseModel):
    user_id: int | None = None
    law_id: int | None = None
    position_id: int | None = None

class UserVoteView(BaseModel):
    id: int
    user_id: int
    law_id: int
    position_id: int