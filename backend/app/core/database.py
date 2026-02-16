from .config import DATABASE_URL
from sqlmodel import SQLModel, create_engine, Session
# Importation de tous les modèles pour la création des tables
# from ..modules.users.models import User  # À décommenter quand le module users sera créé 

engine = create_engine(DATABASE_URL, echo=True)

def init_db():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session