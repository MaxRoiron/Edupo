from app.modules.user_data import ProfessionalStatus

from sqlmodel import Session, select
from fastapi import status

def add_professional_status(session: Session):
    data = ProfessionalStatus(name="test")
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def test_post_professional_status(auth_admin, session):
    assert auth_admin is not None
    response = auth_admin.post(
        "/admin/user_data/professional",
        json={
            "name": "test"
        }
    )
    assert response.status_code == status.HTTP_201_CREATED
    assert session.exec(select(ProfessionalStatus).where(ProfessionalStatus.name == "test")).first() is not None

def test_post_professional_status_forbidden(auth_user):
    assert auth_user is not None
    response = auth_user.post(
        "/admin/user_data/professional",
        json={
            "name": "test"
        }
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_get_professional_status(auth_user):
    assert auth_user is not None
    response = auth_user.get("/user_data/professional")
    assert response.status_code == status.HTTP_200_OK

def test_get_professional_status_by_id(auth_user, session):
    assert auth_user is not None
    data = add_professional_status(session=session)
    response = auth_user.get(f"/user_data/professional/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_patch_professional_status(auth_admin, session):
    assert auth_admin is not None
    data = add_professional_status(session=session)
    response = auth_admin.patch(
        f"/admin/user_data/professional/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_200_OK

def test_patch_professional_status_forbidden(auth_user, session):
    assert auth_user is not None
    data = add_professional_status(session=session)
    response = auth_user.patch(
        f"/admin/user_data/professional/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_delete_professional_status(auth_admin, session):
    assert auth_admin is not None
    data = add_professional_status(session=session)
    response = auth_admin.delete(f"/admin/user_data/professional/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_delete_professional_status_forbidden(auth_user, session):
    assert auth_user is not None
    data = add_professional_status(session=session)
    response = auth_user.delete(f"/admin/user_data/professional/{data.id}")
    assert response.status_code == status.HTTP_403_FORBIDDEN