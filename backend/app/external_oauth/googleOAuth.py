import os
from fastapi import Request, APIRouter
from authlib.integrations.starlette_client import OAuth

router = APIRouter()

# CONFIGURER OAUTH
oauth = OAuth()
oauth.register(
    name='google',
    client_id=os.getenv("GOOGLE_CLIENT_ID"),
    client_secret=os.getenv("GOOGLE_CLIENT_SECRET"),
    server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
    client_kwargs={'scope': 'openid email profile'}
)

# Demande la connexion
@router.get("/login")
async def login(request: Request):
    # L'URL callback de google console cloud
    redirect_uri = "http://localhost:8000/auth/google/callback"
    return await oauth.google.authorize_redirect(request, redirect_uri)

# Route callback de OAuth dans google console cloud
@router.get("/auth/google/callback")
async def auth_google_callback(request: Request):
    # Récupération du token et des infos utilisateur
    token = await oauth.google.authorize_access_token(request)
    user_info = token.get('userinfo')
    
    # Enregistrement de l'utilisateur en base via init_db()
    return {
        "message": "Bienvenue !",
        "user": user_info
    }