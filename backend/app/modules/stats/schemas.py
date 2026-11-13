from pydantic import BaseModel

class PartyMatchResult(BaseModel):
    party_id: int
    party_name: str
    party_abbreviation: str | None
    match_percentage: float
    common_votes_count: int
