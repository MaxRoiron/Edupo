from app.modules import Power

from sqlmodel import Session
from fastapi import status

def add_power(session: Session):
    data = Power(
        name="testPower"
    )
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def test_get_all_power(auth_user, session):
    assert auth_user is not None
    data = add_power(session=session)
    response = auth_user.get("/power")
    assert response.status_code == status.HTTP_200_OK

def test_get_power(auth_user, session):
    assert auth_user is not None
    data = add_power(session=session)
    response = auth_user.get(f"/power/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_post_power_error(auth_user, session):
    assert auth_user is not None
    response = auth_user.post(
        "/admin/power",
        json={
            "name": "testInstitution"
        }
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_post_power(auth_admin, session):
    assert auth_admin is not None
    response = auth_admin.post(
        "/admin/power",
        json={
            "name": "testInstitution"
        }
    )
    assert response.status_code == status.HTTP_201_CREATED

def test_patch_power_error(auth_user, session):
    assert auth_user is not None
    data = add_power(session=session)
    response = auth_user.patch(
        f"/admin/power/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_patch_power(auth_admin, session):
    assert auth_admin is not None
    data = add_power(session=session)
    response = auth_admin.patch(
        f"/admin/power/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_200_OK

def test_delete_power_error(auth_user, session):
    assert auth_user is not None
    data = add_power(session=session)
    response = auth_user.delete(f"/admin/power/{data.id}")
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_delete_power(auth_admin, session):
    assert auth_admin is not None
    data = add_power(session=session)
    response = auth_admin.delete(f"/admin/power/{data.id}")
    assert response.status_code == status.HTTP_200_OK