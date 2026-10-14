from .config import DATABASE_URL

from sqlmodel import create_engine, Session

engine = create_engine(DATABASE_URL, echo=False, pool_pre_ping=True)


def get_session():
    with Session(engine) as session:
        yield session
