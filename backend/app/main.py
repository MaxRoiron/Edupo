from .core import engine
from .api import api_router
from .modules import *

import os
from sqlmodel import SQLModel
import asyncio
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from authlib.integrations.starlette_client import OAuth
from starlette.middleware.sessions import SessionMiddleware
from app.modules.law.scraper import periodic_law_scraper

app = FastAPI()

@app.on_event("startup")
async def startup_event():
    # Démarre notre système automatique de mise à jour des lois
    asyncio.create_task(periodic_law_scraper())

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
