from app.modules import Country

from sqlmodel import Session, select
from fastapi import status

def add_country(session: Session):
    data = Country(
        name="testCountry",
        iso_code="TC"
    )
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def test_get_all_country(auth_user, session):
    assert auth_user is not None
    data = add_country(session=session)
    response = auth_user.get("/country")
    assert response.status_code == status.HTTP_200_OK

def test_get_country(auth_user, session):
    assert auth_user is not None
    data = add_country(session=session)
    response = auth_user.get(f"/country/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_post_country_error(auth_user):
    assert auth_user is not None
    response = auth_user.post(
        "/admin/country",
        json={
            "name": "testCountry",
            "iso_code": "TC"
        }
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_post_country(auth_admin):
    assert auth_admin is not None
    response = auth_admin.post(
        "/admin/country",
        json={
            "name": "testCountry",
            "iso_code": "TC"
        }
    )
    assert response.status_code == status.HTTP_201_CREATED

def test_patch_country_error(auth_user, session):
    assert auth_user is not None
    data = add_country(session=session)
    response = auth_user.patch(
        f"/admin/country/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_patch_country(auth_admin, session):
    assert auth_admin is not None
    data = add_country(session=session)
    response = auth_admin.patch(
        f"/admin/country/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_200_OK

def test_delete_country_error(auth_user, session):
    assert auth_user is not None
    data = add_country(session=session)
    response = auth_user.delete(f"/admin/country/{data.id}")
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_delete_country(auth_admin, session):
    assert auth_admin is not None
    data = add_country(session=session)
    response = auth_admin.delete(f"/admin/country/{data.id}")
    assert response.status_code == status.HTTP_200_OK