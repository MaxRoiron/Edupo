from pydantic import BaseModel
from typing import Literal
import datetime


class LawCreate(BaseModel):
    title: str
    description: str
    domain_id: int
    source_url: str | None = None
    vote_date: datetime.datetime | None = None
    scrutin_id: str | None = None
    category: str | None = None
    country_id: int
    is_active: bool
    status: Literal[
        "pending", "adopted", "rejected", "promulgated", "withdrawn", "unknown"
    ] = "unknown"


class LawUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    domain_id: int | None = None
    source_url: str | None = None
    vote_date: datetime.datetime | None = None
    scrutin_id: str | None = None
    category: str | None = None
    country_id: int | None = None
    is_active: bool | None = None
    status: (
        Literal["pending", "adopted", "rejected", "promulgated", "withdrawn", "unknown"]
        | None
    ) = None


class LawView(BaseModel):
    id: int
    title: str
    description: str
    domain_id: int
    source_url: str | None
    vote_date: datetime.datetime | None
    scrutin_id: str | None
    category: str | None
    country_id: int
    is_active: bool
    official_title: str | None = None
    short_title: str | None = None
    status: str = "unknown"
    source: str = "manual"
    source_urls: list[str] = []
    description_source_url: str | None = None
    updated_at: datetime.datetime | None = None
    published_at: datetime.datetime | None = None


class CitizenVoteInput(BaseModel):
    position: Literal["pour", "contre", "abstention"]


class CitizenVoteView(BaseModel):
    law_id: int
    position: str | None = None


class VoteCreate(BaseModel):
    position: str


class VoteUpdate(BaseModel):
    position: str | None = None


class Voteview(BaseModel):
    id: int
    position: str


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
