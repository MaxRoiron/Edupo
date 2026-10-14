from ..political_party import Domain
from ..country import Country
from ..institution import Institution

from sqlmodel import SQLModel, Field, Relationship
from sqlalchemy import Column, JSON, UniqueConstraint, Index
import datetime


class Law(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    title: str = Field(index=True)
    legacy_data: dict | None = Field(default=None, sa_column=Column(JSON))
    official_title: str | None = None
    short_title: str | None = None
    merged_into_id: int | None = Field(default=None, foreign_key="law.id")
    activity_at: datetime.datetime | None = Field(default=None, index=True)
    source_key: str | None = Field(default=None, unique=True, index=True)
    source: str = Field(default="manual")
    source_urls: list[str] = Field(
        default_factory=list, sa_column=Column(JSON, nullable=False)
    )
    description_source_url: str | None = None
    status: str = Field(default="unknown", index=True)
    relevance: int = Field(default=0)
    updated_at: datetime.datetime = Field(
        default_factory=lambda: datetime.datetime.now(datetime.UTC)
    )
    last_seen_at: datetime.datetime | None = None
    published_at: datetime.datetime | None = None
    __table_args__ = (Index("ix_law_feed", "is_active", "status", "updated_at"),)
    description: str
    domain_id: int = Field(index=True, foreign_key="domain.id")
    source_url: str | None = Field(default=None, index=True)
    vote_date: datetime.datetime | None = Field(default=None)
    scrutin_id: str | None = Field(default=None, index=True, unique=True)
    category: str | None = Field(default=None)
    created_at: datetime.datetime = Field(
        default_factory=lambda: datetime.datetime.now(datetime.UTC), nullable=False
    )
    country_id: int = Field(index=True, foreign_key="country.id")
    is_active: bool = Field(default=True)
    hidden_by_admin: bool = Field(default=False)

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


class LawScrutin(SQLModel, table=True):
    """All official readings of one legislative text, including raw evidence."""

    id: int | None = Field(default=None, primary_key=True)
    uid: str = Field(unique=True, index=True)
    law_id: int = Field(foreign_key="law.id", index=True)
    vote_date: datetime.datetime
    source_url: str
    payload: dict = Field(sa_column=Column(JSON, nullable=False))
    law: Law = Relationship(
        sa_relationship_kwargs={"foreign_keys": "LawScrutin.law_id"}
    )


class LawSyncState(SQLModel, table=True):
    source: str = Field(primary_key=True)
    last_success_at: datetime.datetime | None = None
    last_attempt_at: datetime.datetime | None = None
    error: str | None = None
    etag: str | None = None
    modified: str | None = None
    content_hash: str | None = None
