from ..country import Country

from sqlmodel import SQLModel, Field, Relationship

class Power(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True)
    description: str | None = Field(default=None)


class InstitutionType(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True, unique=True)
    description: str | None = Field(default=None)


class Institution(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    description: str | None = Field(default=None)
    country_id: int = Field(index=True, foreign_key="country.id")
    power_id: int = Field(index=True, foreign_key="power.id")
    institution_type_id: int = Field(index=True, foreign_key="institutiontype.id")

    country: Country = Relationship()
    power: Power = Relationship()
    institution_type: InstitutionType = Relationship()