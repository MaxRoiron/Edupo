from pydantic import BaseModel

class ProfessionalStatusCreate(BaseModel):
    name: str

class ProfessionalStatusUpdate(BaseModel):
    name: str | None = None

class ProfessionalStatusView(BaseModel):
    id: int
    name: str


class SocialStatusCreate(BaseModel):
    name: str

class SocialStatusUpdate(BaseModel):
    name: str | None = None

class SocialStatusView(BaseModel):
    id: int
    name: str


class GenderIdentitiesCreate(BaseModel):
    name: str

class GenderIdentitiesUpdate(BaseModel):
    name: str | None = None

class GenderIdentitiesView(BaseModel):
    id: int
    name: str


class UserDataCreate(BaseModel):
    age: int | None = None
    professional_status_id: int | None = None
    social_status_id: int | None = None
    gender_identity_id: int | None = None

class UserDataUpdate(BaseModel):
    age: int | None = None
    professional_status_id: int | None = None
    social_status_id: int | None = None
    gender_identity_id: int | None = None

class UserDataView(BaseModel):
    id: int
    age: int | None = None
    professional_status_id: int | None = None
    social_status_id: int | None = None
    gender_identity_id: int | None = None