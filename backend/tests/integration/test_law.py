from app.modules import Law, Country, Domain

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

def add_domain(session: Session):
    data = Domain(
        name="testDomain"
    )
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def add_law(session: Session):
    country = add_country(session=session)
    domain = add_domain(session=session)
    data = Law(
        title="testLaw",
        description="testLawDescription",
        domain_id=domain.id,
        country_id=country.id
    )
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def test_post_law(auth_admin, session):
    assert auth_admin is not None
    country = add_country(session=session)
    domain = add_domain(session=session)
    response = auth_admin.post(
        "/admin/law",
        json={
            "title": "testLaw",
            "description": "testLawDescription",
            "domain_id": domain.id,
            "country_id": country.id,
            "is_active": True
        }
    )
    assert response.status_code == status.HTTP_201_CREATED
    assert session.exec(select(Law).where(Law.title == "testLaw")).first() is not None

def test_post_law_forbidden(auth_user, session):
    assert auth_user is not None
    country = add_country(session=session)
    domain = add_domain(session=session)
    response = auth_user.post(
        "/admin/law",
        json={
            "title": "testLaw",
            "description": "testLawDescription",
            "domain_id": domain.id,
            "country_id": country.id,
            "is_active": True
        }
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_get_law(auth_user):
    assert auth_user is not None
    response = auth_user.get("/law")
    assert response.status_code == status.HTTP_200_OK

def test_get_law_by_id(auth_user, session):
    assert auth_user is not None
    data = add_law(session=session)
    response = auth_user.get(f"/law/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_patch_law(auth_admin, session):
    assert auth_admin is not None
    data = add_law(session=session)
    response = auth_admin.patch(
        f"/admin/law/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_200_OK

def test_patch_law_forbidden(auth_user, session):
    assert auth_user is not None
    data = add_law(session=session)
    response = auth_user.patch(
        f"/admin/law/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_delete_law(auth_admin, session):
    assert auth_admin is not None
    data = add_law(session=session)
    response = auth_admin.delete(f"/admin/law/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_delete_law_forbidden(auth_user, session):
    assert auth_user is not None
    data = add_law(session=session)
    response = auth_user.delete(f"/admin/law/{data.id}")
    assert response.status_code == status.HTTP_403_FORBIDDEN