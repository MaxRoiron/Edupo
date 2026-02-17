from ..modules import users_router, oauth_router

from fastapi import APIRouter

api_router = APIRouter()

api_router.include_router(users_router, tags=["user"])
api_router.include_router(oauth_router, prefix="", tags=["OAuth"])
