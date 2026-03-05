from pydantic import BaseModel

class ProfessionalStatusCreate(BaseModel):
    name: str

class ProfessionalStatusUpdate(BaseModel):
    name: str | None

class ProfessionalStatusView(BaseModel):
    id: int
    name: str


class SocialStatusCreate(BaseModel):
    name: str

class SocialStatusUpdate(BaseModel):
    name: str | None

class SocialStatusView(BaseModel):
    id: int
    name: str


class GenderIdentitiesCreate(BaseModel):
    name: str

class GenderIdentitiesUpdate(BaseModel):
    name: str | None

class GenderIdentitiesView(BaseModel):
    id: int
    name: str


class UserDataCreate(BaseModel):
    age: int | None
    user_id: int
    professional_status_id: int | None
    social_status_id: int | None
    gender_identity_id: int | None

class UserDataUpdate(BaseModel):
    age: int | None
    professional_status_id: int | None
    social_status_id: int | None
    gender_identity_id: int | None

class UserDataView(BaseModel):
    id: int
    age: int | None
    user_id: int
    professional_status_id: int | None
    social_status_id: int | None
    gender_identity_id: int | None