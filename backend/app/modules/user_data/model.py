from sqlmodel import SQLModel, Field, Relationship


class ProfessionalStatus(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True)


class SocialStatus(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True)


class GenderIdentities(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str = Field(index=True)


class UserData(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    age: int | None = Field(default=None, nullable=True)
    user_id: int = Field(foreign_key="user.id", unique=True)
    professional_status_id: int | None = Field(default=None, foreign_key="professionalstatus.id")
    social_status_id: int | None = Field(default=None, foreign_key="socialstatus.id")
    gender_identity_id: int | None = Field(default=None, foreign_key="genderidentities.id")

    professional_status: ProfessionalStatus | None = Relationship()
    social_status: SocialStatus | None = Relationship()
    gender_identity: GenderIdentities | None = Relationship()