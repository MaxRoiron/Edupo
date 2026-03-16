from app.modules import Vote

from sqlmodel import Session, select
from fastapi import status

def add_vote(session: Session):
    data = Vote(
        position="testPosition"
    )
    session.add(data)
    session.commit()
    session.refresh(data)
    return data

def test_post_vote(auth_admin, session):
    assert auth_admin is not None
    response = auth_admin.post(
        "/admin/vote",
        json={
            "position": "testPosition"
        }
    )
    assert response.status_code == status.HTTP_201_CREATED
    assert session.exec(select(Vote).where(Vote.position == "testPosition")).first() is not None

def test_post_vote_forbidden(auth_user):
    assert auth_user is not None
    response = auth_user.post(
        "/admin/vote",
        json={
            "position": "testPosition"
        }
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_get_vote(auth_user):
    assert auth_user is not None
    response = auth_user.get("/vote")
    assert response.status_code == status.HTTP_200_OK

def test_get_vote_by_id(auth_user, session):
    assert auth_user is not None
    data = add_vote(session=session)
    response = auth_user.get(f"/vote/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_patch_vote(auth_admin, session):
    assert auth_admin is not None
    data = add_vote(session=session)
    response = auth_admin.patch(
        f"/admin/vote/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_200_OK

def test_patch_vote_forbidden(auth_user, session):
    assert auth_user is not None
    data = add_vote(session=session)
    response = auth_user.patch(
        f"/admin/vote/{data.id}",
        json={}
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_delete_vote(auth_admin, session):
    assert auth_admin is not None
    data = add_vote(session=session)
    response = auth_admin.delete(f"/admin/vote/{data.id}")
    assert response.status_code == status.HTTP_200_OK

def test_delete_vote_forbidden(auth_user, session):
    assert auth_user is not None
    data = add_vote(session=session)
    response = auth_user.delete(f"/admin/vote/{data.id}")
    assert response.status_code == status.HTTP_403_FORBIDDEN