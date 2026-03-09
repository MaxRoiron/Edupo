from app.modules.users import User

from fastapi import status

def test_post_data(auth_user):
    assert auth_user is not None
    response = auth_user.post(
        "/me/data",
        json={}
    )
    assert response.status_code == status.HTTP_201_CREATED

def test_post_data_already_created(auth_user_with_user_data):
    assert auth_user_with_user_data is not None
    response = auth_user_with_user_data.post(
        "/me/data",
        json={}
    )
    assert response.status_code == status.HTTP_409_CONFLICT

def test_get_data(auth_user_with_user_data):
    assert auth_user_with_user_data is not None
    response = auth_user_with_user_data.get("/me/data")
    assert response.status_code == status.HTTP_200_OK

def test_get_data_no_data(auth_user):
    assert auth_user is not None
    response = auth_user.get("/me/data")
    assert response.status_code == status.HTTP_404_NOT_FOUND

def test_patch_data(auth_user):
    assert auth_user is not None
    response = auth_user.patch(
        "/me/data",
        json={}
    )
    assert response.status_code == status.HTTP_404_NOT_FOUND

def test_patch_data_already_created(auth_user_with_user_data):
    assert auth_user_with_user_data is not None
    response = auth_user_with_user_data.patch(
        "/me/data",
        json={}
    )
    assert response.status_code == status.HTTP_200_OK

def test_put_data(auth_user_with_user_data):
    assert auth_user_with_user_data is not None
    response = auth_user_with_user_data.put(
        "/me/data/reset"
    )
    assert response.status_code == status.HTTP_200_OK

def test_put_data_user(auth_user_with_user_data):
    assert auth_user_with_user_data is not None
    response = auth_user_with_user_data.put(
        "/admin/user@test.com/reset"
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN

def test_put_data_admin(auth_admin, test_user_with_user_data):
    assert auth_admin is not None
    assert test_user_with_user_data is not None
    response = auth_admin.put(
        "/admin/user@test.com/reset"
    )
    assert response.status_code == status.HTTP_200_OK