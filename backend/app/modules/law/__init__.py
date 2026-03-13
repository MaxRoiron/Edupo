from .model import Law, VoteResult, Vote
from .shemas import LawCreate, LawUpdate, LawView
from .shemas import VoteResultCreate, VoteResultTypeUpdate, VoteResultTypeView
from .shemas import VoteCreate, VoteUpdate, Voteview
from .services import read_all_law
# from .services import ...
from .router import router as law_router