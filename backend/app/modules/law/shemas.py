from pydantic import BaseModel
import datetime

class LawCreate(BaseModel):
    title: str
    subtitle: str | None = None
    description: str
    domain_id: int
    source_url: str | None = None
    country_id: int
    is_active: bool

class LawUpdate(BaseModel):
    title: str | None = None
    subtitle: str | None = None
    description: str | None = None
    domain_id: int | None = None
    source_url: str | None = None
    country_id: int | None = None
    is_active: bool | None = None

class LawView(BaseModel):
    id: int
    title: str
    subtitle: str | None
    description: str
    domain_id: int
    source_url: str | None
    country_id: int
    is_active: bool


class VoteResultCreate(BaseModel):
    law_id: int
    institution_id: int
    total_for: int
    total_abstention: int
    total_against: int
    adopted: bool
    vote_date: datetime.datetime

class VoteResultTypeUpdate(BaseModel):
    law_id: int | None = None
    institution_id: int | None = None
    total_for: int | None = None
    total_abstention: int | None = None
    total_against: int | None = None
    adopted: bool | None = None
    vote_date: datetime.datetime | None = None

class VoteResultTypeView(BaseModel):
    id: int
    law_id: int
    institution_id: int
    total_for: int
    total_abstention: int
    total_against: int
    adopted: bool
    vote_date: datetime.datetime