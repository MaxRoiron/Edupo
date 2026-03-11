from ..country import Country
from ..political_party import PoliticalParty

from sqlmodel import SQLModel, Field, Relationship
import datetime

class PoliticalFigure(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    last_name: str = Field(index=True)
    party_id: int = Field(index=True, foreign_key="politicalparty.id")
    country_id: int = Field(index=True, foreign_key="country.id")

    party: PoliticalParty = Relationship()
    country: Country = Relationship()


class PoliticalRole(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    start_date: datetime.datetime
    end_date: datetime.datetime | None = Field(default=None)
    figure_id: int = Field(index=True, foreign_key="politicalfigure.id")

    figure: PoliticalFigure = Relationship()