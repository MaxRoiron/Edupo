from app.modules.user_data import GenderIdentities

from sqlmodel import Session, select
from fastapi import status

def add_gender_identity(session: Session):
    data = GenderIdentities(name="test")
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def test_post_gender_identity(auth_admin, session):
    assert auth_admin is not None
    response = auth_admin.post(
        "/admin/user_data/gender",
        json={
            "name": "test"
        }
    )
    assert response.status_code == status.HTTP_201_CREATED
    assert session.exec(select(GenderIdentities).where(GenderIdentities.name == "test")).first() is not None

def test_post_gender_identity_forbidden(auth_user):
    assert auth_user is not None
    response = auth_user.post(
        "/admin/user_data/gender",
        json={
            "name": "test"
        }
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_get_gender_identity(auth_user):
    assert auth_user is not None
    response = auth_user.get("/user_data/gender")
    assert response.status_code == status.HTTP_200_OK

def test_get_gender_identity_by_id(auth_user, session):
    assert auth_user is not None
    data = add_gender_identity(session=session)
    response = auth_user.get(f"/user_data/gender/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_patch_gender_identity(auth_admin, session):
    assert auth_admin is not None
    data = add_gender_identity(session=session)
    response = auth_admin.patch(
        f"/admin/user_data/gender/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_200_OK

def test_patch_gender_identity_forbidden(auth_user, session):
    assert auth_user is not None
    data = add_gender_identity(session=session)
    response = auth_user.patch(
        f"/admin/user_data/gender/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_delete_gender_identity(auth_admin, session):
    assert auth_admin is not None
    data = add_gender_identity(session=session)
    response = auth_admin.delete(f"/admin/user_data/gender/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_delete_gender_identity_forbidden(auth_user, session):
    assert auth_user is not None
    data = add_gender_identity(session=session)
    response = auth_user.delete(f"/admin/user_data/gender/{data.id}")
    assert response.status_code == status.HTTP_403_FORBIDDEN