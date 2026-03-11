from pydantic import BaseModel
import datetime

class PoliticalFigureCreate(BaseModel):
    name: str
    last_name: str
    party_id: int
    country_id: int

class PoliticalFigureUpdate(BaseModel):
    name: str | None = None
    last_name: str | None = None
    party_id: int | None = None
    country_id: int | None = None

class PoliticalFigureView(BaseModel):
    id: int
    name: str
    last_name: str
    party_id: int
    country_id: int


class PoliticalRoleCreate(BaseModel):
    name: str
    start_date: datetime.datetime
    end_date: datetime.datetime | None = None
    figure_id: int

class PoliticalRoleUpdate(BaseModel):
    name: str | None = None
    start_date: datetime.datetime | None = None
    end_date: datetime.datetime | None = None
    figure_id: int | None = None

class PoliticalRoleView(BaseModel):
    id: int
    name: str
    start_date: datetime.datetime
    end_date: datetime.datetime | None
    figure_id: int