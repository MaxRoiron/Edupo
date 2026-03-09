from app.modules.users import User

from sqlmodel import select
from fastapi import status

def test_get_user(auth_user):
    response = auth_user.get("/me")
    assert response.status_code == status.HTTP_200_OK

def test_patch_user(auth_user, session):
    assert auth_user is not None
    response = auth_user.patch(
        "/me",
        json={}
    )
    assert response.status_code == status.HTTP_200_OK

def test_delete_user(auth_user, session):
    assert auth_user is not None
    response = auth_user.delete("/me")
    assert response.status_code == status.HTTP_200_OK
    assert session.exec(select(User).where(User.username == "testUser")).first() is None

def test_delete_admin(auth_admin):
    assert auth_admin is not None
    response = auth_admin.delete("/me")
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_admin_delete_user(auth_admin, test_user, session):
    assert test_user is not None
    assert auth_admin is not None
    response = auth_admin.delete("/admin/user@test.com")
    assert response.status_code == status.HTTP_200_OK
    assert session.exec(select(User).where(User.username == "testUser")).first() is None

def test_user_delete_user(auth_user):
    assert auth_user is not None
    response = auth_user.delete("/admin/user@test.com")
    assert response.status_code == status.HTTP_403_FORBIDDEN