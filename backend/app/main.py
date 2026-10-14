from .core import engine
from .api import api_router
from .modules import *

import os
from sqlmodel import SQLModel
import asyncio
from fastapi import FastAPI
from contextlib import asynccontextmanager, suppress
from app.core.config import settings
from fastapi.middleware.cors import CORSMiddleware
from authlib.integrations.starlette_client import OAuth
from starlette.middleware.sessions import SessionMiddleware
from app.modules.law.scraper import periodic_law_scraper


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = (
        asyncio.create_task(periodic_law_scraper())
        if settings.LAW_SYNC_ENABLED
        else None
    )
    yield
    if task is not None:
        task.cancel()
        with suppress(asyncio.CancelledError):
            await task
    # Finish any in-flight worker before releasing the server process.
    from app.modules.law.scraper import _task

    if _task is not None and not _task.done():
        await asyncio.shield(_task)


app = FastAPI(lifespan=lifespan)

# CORS — autorise les requêtes depuis le mobile/web Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, restreindre aux domaines autorisés
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(SessionMiddleware, secret_key=os.getenv("MIDDLEWARE_SECRET_KEY"))


@app.get("/")
def read_root():
    return {"message": "Hello World"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}


app.include_router(api_router)
