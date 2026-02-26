import os
from sqlmodel import Session
from ...core import get_session, create_access_token
from ..users import get_user_by_ggid, User, Token
from fastapi import Request, APIRouter, Depends
from authlib.integrations.starlette_client import OAuth
from passlib.pwd import genword

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
@router.get("/google/login")
async def login(request: Request):
    # L'URL callback de google console cloud
    redirect_uri = "http://localhost:8000/auth/google/callback"
    return await oauth.google.authorize_redirect(request, redirect_uri)

# Route callback de OAuth dans google console cloud
@router.get("/google/callback")
async def auth_google_callback(request: Request, session: Session = Depends(get_session)):
    # Récupération du token et des infos utilisateur
    token = await oauth.google.authorize_access_token(request)
    user_info = token.get('userinfo')
    ggid = user_info.get('sub')

    # Vérifier si l'utilisateur existe déjà via son Google ID
    db_user = get_user_by_ggid(session, ggid)

    if db_user is None:
        # Créer un nouvel utilisateur avec les infos Google
        db_user = User(
            username=user_info.get('name', ''),
            email=user_info.get('email', ''),
            hashed_password=genword(entropy=80),  # Mot de passe aléatoire
            role='user',
            ggid=ggid
        )
        session.add(db_user)
        session.commit()
        session.refresh(db_user)

    # Générer et retourner le token d'accès
    access_token = create_access_token(data={"user_id": db_user.id})
    return Token(
        access_token=access_token,
        token_type="bearer"
    )