from app import app
from app.core import get_session

import pytest
from sqlmodel import SQLModel, create_engine, Session
from fastapi.testclient import TestClient

DATABASE_URL = "postgresql+psycopg2://test:test@localhost:5432/test_db"

engine = create_engine(url=DATABASE_URL)

@pytest.fixture(name="session")
def session_fixture():
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
    SQLModel.metadata.drop_all(engine)

@pytest.fixture(name="client")
def client_fixture(session: Session):
    def override_get_session():
        return session

    app.dependency_overrides[get_session] = override_get_session

    client = TestClient(app=app)
    yield client
    app.dependency_overrides.clear()