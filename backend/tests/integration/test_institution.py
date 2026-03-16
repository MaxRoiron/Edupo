from app.modules import Country, Power, InstitutionType, Institution

from sqlmodel import Session
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

def add_power(session: Session):
    data = Power(
        name="testPower"
    )
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def add_institution_type(session: Session):
    data = InstitutionType(
        name="testInstitutionType"
    )
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def add_institution(session: Session):
    country = add_country(session=session)
    power = add_power(session=session)
    institution_type = add_institution_type(session=session)
    data = Institution(
        name="testInstitution",
        country_id=country.id,
        power_id=power.id,
        institution_type_id=institution_type.id
    )
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def test_get_all_institution(auth_user, session):
    assert auth_user is not None
    data = add_institution(session=session)
    response = auth_user.get("/institution")
    assert response.status_code == status.HTTP_200_OK

def test_get_institution(auth_user, session):
    assert auth_user is not None
    data = add_institution(session=session)
    response = auth_user.get(f"/institution/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_post_institution_error(auth_user, session):
    assert auth_user is not None
    country = add_country(session=session)
    power = add_power(session=session)
    institution_type = add_institution_type(session=session)
    response = auth_user.post(
        "/admin/institution",
        json={
            "name": "testInstitution",
            "country_id": country.id,
            "power_id": power.id,
            "institution_type_id": institution_type.id
        }
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_post_institution(auth_admin, session):
    assert auth_admin is not None
    country = add_country(session=session)
    power = add_power(session=session)
    institution_type = add_institution_type(session=session)
    response = auth_admin.post(
        "/admin/institution",
        json={
            "name": "testInstitution",
            "country_id": country.id,
            "power_id": power.id,
            "institution_type_id": institution_type.id
        }
    )
    assert response.status_code == status.HTTP_201_CREATED

def test_patch_institution_error(auth_user, session):
    assert auth_user is not None
    data = add_institution(session=session)
    response = auth_user.patch(
        f"/admin/institution/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_patch_institution(auth_admin, session):
    assert auth_admin is not None
    data = add_institution(session=session)
    response = auth_admin.patch(
        f"/admin/institution/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_200_OK

def test_delete_institution_error(auth_user, session):
    assert auth_user is not None
    data = add_institution(session=session)
    response = auth_user.delete(f"/admin/institution/{data.id}")
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_delete_institution(auth_admin, session):
    assert auth_admin is not None
    data = add_institution(session=session)
    response = auth_admin.delete(f"/admin/institution/{data.id}")
    assert response.status_code == status.HTTP_200_OK