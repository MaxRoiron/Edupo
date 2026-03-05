from app import app

import os
os.environ["ENV_FILE"] = os.path.join(os.path.dirname(__file__), ".env.test")
from app.core import get_session, settings

import pytest
from sqlmodel import SQLModel, create_engine, Session
from fastapi.testclient import TestClient

engine = create_engine(url=settings.DATABASE_URL)

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