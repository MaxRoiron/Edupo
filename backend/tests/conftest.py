from app import app
from app.modules.users import User

import os
os.environ["ENV_FILE"] = os.path.join(os.path.dirname(__file__), ".env.test")
from app.core import get_session, settings, create_access_token, get_password_hash

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

@pytest.fixture(name="test_user")
def test_user_fixture(session: Session):
    user = User(
        username="testUser",
        email="user@test.com",
        hashed_password=get_password_hash("userPassword"),
        role="user"
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

@pytest.fixture(name="auth_user")
def auth_user_fixture(client: TestClient, test_user: User):
    token = create_access_token(data={"user_id": test_user.id})
    client.headers.update({"Authorization": f"Bearer {token}"})
    return client

@pytest.fixture(name="test_admin")
def test_admin_fixture(session: Session):
    admin = User(
        username="testAdmin",
        email="admin@test.com",
        hashed_password=get_password_hash("adminPassword"),
        role="admin"
    )
    session.add(admin)
    session.commit()
    session.refresh(admin)
    return admin

@pytest.fixture(name="auth_admin")
def auth_admin_fixture(client: TestClient, test_admin: User):
    token = create_access_token(data={"user_id": test_admin.id})
    client.headers.update({"Authorization": f"Bearer {token}"})
    return client