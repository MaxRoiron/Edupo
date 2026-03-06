from app.modules.users import User

from sqlmodel import select
from fastapi import status

def test_register_user(client, session):
    response = client.post(
        "/register",
        json={
            "username": "testUser",
            "email": "user@test.com",
            "password": "userPassword"
        }
    )
    assert response.status_code == status.HTTP_201_CREATED

    user = session.exec(
        select(User).where(User.email == "user@test.com")
    ).first()
    assert user is not None

def test_register_user_error(client, test_user):
    assert test_user is not None
    response = client.post(
        "/register",
        json={
            "username": "testUser",
            "email": "user@test.com",
            "password": "userPassword"
        }
    )
    assert response.status_code == status.HTTP_409_CONFLICT

def test_login_user(client, test_user):
    assert test_user is not None
    response = client.post(
        "/login",
        json={
            "email": "user@test.com",
            "password": "userPassword"
        }
    )
    assert response.status_code == status.HTTP_200_OK

def test_login_user_not_registered(client):
    response = client.post(
        "/login",
        json={
            "email": "user@test.com",
            "password": "userPassword"
        }
    )
    assert response.status_code == status.HTTP_401_UNAUTHORIZED

def test_login_user_wrong_password(client):
    response = client.post(
        "/login",
        json={
            "email": "user@test.com",
            "password": "wrongPassword"
        }
    )
    assert response.status_code == status.HTTP_401_UNAUTHORIZED