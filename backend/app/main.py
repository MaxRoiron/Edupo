from app import router_oauth
from .core import engine
from .api import api_router
from .modules import *

import os
from sqlmodel import SQLModel
from fastapi import FastAPI
from contextlib import asynccontextmanager
from authlib.integrations.starlette_client import OAuth
from starlette.middleware.sessions import SessionMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    SQLModel.metadata.create_all(engine)
    yield

app = FastAPI(lifespan=lifespan)
app.add_middleware(SessionMiddleware, secret_key=os.getenv("MIDDLEWARE_SECRET_KEY"))

@app.get("/")
def read_root():
    return {"message": "Hello World"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}


app.include_router(router_oauth, prefix="", tags=["OAuth"])
app.include_router(api_router)
