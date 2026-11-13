from sqlmodel import Session, select
from ...modules.political_party.model import PoliticalParty, PartyVote
from ...modules.user_vote.model import UserVote
from .schemas import PartyMatchResult

def calculate_user_party_matching(session: Session, user_id: int) -> list[PartyMatchResult]:
    # Get all user votes
    user_votes = session.exec(select(UserVote).where(UserVote.user_id == user_id)).all()
    if not user_votes:
        return []
    
    user_vote_dict = {vote.law_id: vote.position_id for vote in user_votes}
    
    # Get all parties
    parties = session.exec(select(PoliticalParty)).all()
    results = []
    
    for party in parties:
        # Get party votes
        party_votes = session.exec(select(PartyVote).where(PartyVote.party_id == party.id)).all()
        if not party_votes:
            continue
            
        party_vote_dict = {vote.law_id: vote.position_id for vote in party_votes}
        
        # Calculate intersection
        common_laws = set(user_vote_dict.keys()).intersection(set(party_vote_dict.keys()))
        if not common_laws:
            continue
            
        matching_votes = 0
        for law_id in common_laws:
            if user_vote_dict[law_id] == party_vote_dict[law_id]:
                matching_votes += 1
                
        match_percentage = (matching_votes / len(common_laws)) * 100
        
        results.append(
            PartyMatchResult(
                party_id=party.id,
                party_name=party.name,
                party_abbreviation=party.abbreviation,
                match_percentage=round(match_percentage, 2),
                common_votes_count=len(common_laws)
            )
        )
        
    # Sort by match percentage (descending)
    return sorted(results, key=lambda x: x.match_percentage, reverse=True)
