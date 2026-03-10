from pydantic import BaseModel

class CountryCreate(BaseModel):
    name: str
    iso_code: str

class CountryUpdate(BaseModel):
    name: str | None = None
    iso_code: str | None = None

class CountryView(BaseModel):
    id: int
    name: str
    iso_code: str