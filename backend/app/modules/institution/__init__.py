from .model import Power, Institution, InstitutionType
from .shemas import PowerCreate, PowerUpdate, PowerView
from .shemas import InstitutionCreate, InstitutionTypeUpdate, InstitutionTypeView
from .shemas import InstitutionCreate, InstitutionUpdate, InstitutionView
from .services import read_all_institution, read_institution, read_all_institution_type, read_institution_type, add_institution, delete_institution_by_id, update_institution_by_id, add_institution_type, delete_institution_type_by_id, update_institution_type_by_id, read_all_power, read_power, add_power, delete_power_by_id, update_power_by_id
# from .services import ...
from .router import router as institution_router