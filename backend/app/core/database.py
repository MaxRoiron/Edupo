from .config import DATABASE_URL

from sqlmodel import create_engine, Session

engine = create_engine(DATABASE_URL, echo=True)

def get_session():
    with Session(engine) as session:
        yield session