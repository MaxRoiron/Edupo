from ..political_party import Domain
from ..country import Country
from ..institution import Institution

from sqlmodel import SQLModel, Field, Relationship
import datetime

class Law(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    title: str = Field(index=True)
    description: str
    domain_id: int = Field(index=True, foreign_key="domain.id")
    source_url: str | None = Field(default=None, index=True)
    vote_date: datetime.datetime | None = Field(default=None)
    scrutin_id: str | None = Field(default=None, index=True)
    category: str | None = Field(default=None)
    created_at: datetime.datetime = Field(default_factory=lambda: datetime.datetime.now(datetime.UTC), nullable=False)
    country_id: int = Field(index=True, foreign_key="country.id")
    is_active: bool = Field(default=True)

    domain: Domain = Relationship()
    country: Country = Relationship()

class Vote(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    position: str = Field(index=True, unique=True)

class VoteResult(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    law_id: int = Field(index=True, foreign_key="law.id")
    institution_id: int = Field(index=True, foreign_key="institution.id")
    total_for: int
    total_abstention: int
    total_against: int
    adopted: bool
    vote_date: datetime.datetime

    law: Law = Relationship()
    institution: Institution = Relationship()