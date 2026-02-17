from ..modules import users_router

from fastapi import APIRouter

api_router = APIRouter()

api_router.include_router(users_router, tags=["user"])
