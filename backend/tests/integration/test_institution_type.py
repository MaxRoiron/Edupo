from app.modules import InstitutionType

from sqlmodel import Session
from fastapi import status

def add_institution_type(session: Session):
    data = InstitutionType(
        name="testInstitutionType"
    )
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def test_get_all_institution_type(auth_user, session):
    assert auth_user is not None
    data = add_institution_type(session=session)
    response = auth_user.get("/institution_type")
    assert response.status_code == status.HTTP_200_OK

def test_get_institution_type(auth_user, session):
    assert auth_user is not None
    data = add_institution_type(session=session)
    response = auth_user.get(f"/institution_type/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_post_institution_type_error(auth_user, session):
    assert auth_user is not None
    response = auth_user.post(
        "/admin/institution_type",
        json={
            "name": "testInstitution"
        }
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_post_institution_type(auth_admin, session):
    assert auth_admin is not None
    response = auth_admin.post(
        "/admin/institution_type",
        json={
            "name": "testInstitution"
        }
    )
    assert response.status_code == status.HTTP_201_CREATED

def test_patch_institution_type_error(auth_user, session):
    assert auth_user is not None
    data = add_institution_type(session=session)
    response = auth_user.patch(
        f"/admin/institution_type/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_patch_institution_type(auth_admin, session):
    assert auth_admin is not None
    data = add_institution_type(session=session)
    response = auth_admin.patch(
        f"/admin/institution_type/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_200_OK

def test_delete_institution_type_error(auth_user, session):
    assert auth_user is not None
    data = add_institution_type(session=session)
    response = auth_user.delete(f"/admin/institution_type/{data.id}")
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_delete_institution_type(auth_admin, session):
    assert auth_admin is not None
    data = add_institution_type(session=session)
    response = auth_admin.delete(f"/admin/institution_type/{data.id}")
    assert response.status_code == status.HTTP_200_OK