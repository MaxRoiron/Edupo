import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from authlib.integrations.starlette_client import OAuth
from starlette.middleware.sessions import SessionMiddleware
from .core import init_db

#import router
from app import router_oauth

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield

app = FastAPI(lifespan=lifespan)
app.add_middleware(SessionMiddleware, secret_key=os.getenv("MIDDLEWARE_SECRET_KEY"))

@app.get("/")
def read_root():
    return {"message": "Hello World"}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

#Include router
app.include_router(router_oauth, prefix="", tags=["OAuth"])