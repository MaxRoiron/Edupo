from pydantic import BaseModel

class PowerCreate(BaseModel):
    name: str
    description: str | None = None

class PowerUpdate(BaseModel):
    name: str | None = None
    description: str | None = None

class PowerView(BaseModel):
    id: int
    name: str
    description: str | None


class InstitutionTypeCreate(BaseModel):
    name: str
    description: str | None = None

class InstitutionTypeUpdate(BaseModel):
    name: str | None = None
    description: str | None = None

class InstitutionTypeView(BaseModel):
    id: int
    name: str
    description: str | None


class InstitutionCreate(BaseModel):
    name: str
    description: str | None = None
    country_id: int
    power_id: int
    institution_type_id: int

class InstitutionUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    country_id: int | None = None
    power_id: int | None = None
    institution_type_id: int | None = None

class InstitutionView(BaseModel):
    id: int
    name: str
    description: str | None
    country_id: int
    power_id: int
    institution_type_id: int