from ..country import Country

from sqlmodel import SQLModel, Field, Relationship

class PoliticalParty(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    abbreviation: str | None = Field(default=None, index=True)
    description: str | None = Field(default=None)
    ideology_summary: str | None = Field(default=None)
    country_id: int = Field(index=True, foreign_key="country.id")

    country: Country = Relationship()
    programs: list["PoliticalProgram"] = Relationship(back_populates="program")


class Domain(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    description: str | None = Field(default=None)


class PoliticalTopic(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    description: str
    program_id: int = Field(index=True, foreign_key="politicalprogram.id")
    domain_id: int = Field(index=True, foreign_key="domain.id")

    domain: Domain = Relationship()


class ElectionType(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str


class PoliticalProgram(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    party_id: int = Field(index=True, foreign_key="politicalparty.id")
    year: int = Field(index=True)
    election_type_id: int = Field(index=True, foreign_key="electiontype.id")

    party: PoliticalParty = Relationship(back_populates="programs")
    election_type: ElectionType = Relationship()