from fastapi import APIRouter, Depends
from sqlmodel import Session
from ...core import get_session
from ..users import User, get_current_user
from .schemas import PartyMatchResult
from .services import calculate_user_party_matching

router = APIRouter()

# ============================================================================
# USER STATS
# ============================================================================

@router.get("/me/stats/match", response_model=list[PartyMatchResult], tags=["User"])
async def get_my_party_matches(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    """
    Returns the percentage of matching votes between the current user and each political party.
    Only considers laws where both the user and the party have voted.
    """
    return calculate_user_party_matching(session, user.id)

# ============================================================================
# GLOBAL STATS
# ============================================================================

@router.get("/stats/laws", response_model={}, tags=["Stats"])
async def get_all_laws_stats(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    """
    Returns the statistics for all laws.
    """
    return {}

@router.get("/stats/laws/{law_id}", response_model={}, tags=["Stats"])
async def get_law_stats(session: Session = Depends(get_session), user: User = Depends(get_current_user)):
    """
    Returns the statistics for a specific law.
    """
    return {}
