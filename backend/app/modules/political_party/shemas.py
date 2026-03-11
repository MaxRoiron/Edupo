from pydantic import BaseModel

class PoliticalPartyCreate(BaseModel):
    name: str
    abbreviation: str | None = None
    description: str | None = None
    ideology_summary: str | None = None
    country_id: int

class PoliticalPartyUpdate(BaseModel):
    name: str | None = None
    abbreviation: str | None = None
    description: str | None = None
    ideology_summary: str | None = None
    country_id: int | None = None

class PoliticalPartyView(BaseModel):
    id: int
    name: str | None
    abbreviation: str | None
    description: str | None
    ideology_summary: str | None
    country_id: int | None


class DomainCreate(BaseModel):
    name: str
    description: str | None = None

class DomainUpdate(BaseModel):
    name: str | None = None
    description: str | None = None

class DomainView(BaseModel):
    id: int
    name: str
    description: str | None


class PoliticalTopicCreate(BaseModel):
    desciption: str
    program_id: int
    domain_id: int

class PoliticalTopicUpdate(BaseModel):
    desciption: str | None = None
    program_id: int | None = None
    domain_id: int | None = None

class PoliticalTopicView(BaseModel):
    id: int
    desciption: str
    program_id: int
    domain_id: int


class ElectionTypeCreate(BaseModel):
    name: str

class ElectionTypeUpdate(BaseModel):
    name: str | None = None

class ElectionTypeView(BaseModel):
    id: int
    name: str


class PoliticalProgramCreate(BaseModel):
    name: str
    party_id: int
    year: int
    election_type_id: int

class PoliticalProgramUpdate(BaseModel):
    name: str | None = None
    party_id: int | None = None
    year: int | None = None
    election_type_id: int | None = None

class PoliticalProgramView(BaseModel):
    id: int
    name: str
    party_id: int
    year: int
    election_type_id: int