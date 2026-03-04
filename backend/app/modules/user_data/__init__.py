from .model import UserData, ProfessionalStatus, SocialStatus, GenderIdentities
from .shemas import ProfessionalStatusCreate, ProfessionalStatusUpdate, ProfessionalStatusView, SocialStatusCreate, SocialStatusUpdate, SocialStatusView, GenderIdentitiesCreate, GenderIdentitiesUpdate, GenderIdentitiesView, UserDataCreate, UserDataUpdate, UserDataView
from .services import add_user_data, update_user_data, reset_user_data
from .services import add_professional_status, update_professional_status_by_id, delete_professional_status_by_id, get_professional_status_by_id, read_all_professional_status
from .services import  add_social_status, update_social_status_by_id, delete_social_status_by_id, get_social_status_by_id, read_all_social_status
from .router import router as user_data_router