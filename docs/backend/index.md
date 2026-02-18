# 🚀 Edupo Backend - Documentation & Guide

Bienvenue dans la documentation technique du backend d'Edupo. Ce projet est conçu pour être **scalable**, **propre** et **sécurisé**, en suivant les meilleures pratiques de développement Python modernes.

---

## 🛠 Tech Stack

- **Framework** : [FastAPI](https://fastapi.tiangolo.com/) (Performance et documentation automatique)
- **ORM** : [SQLModel](https://sqlmodel.tiangolo.com/) (Combinaison parfaite de SQLAlchemy et Pydantic)
- **Validation & Settings** : [Pydantic v2](https://docs.pydantic.dev/) & `pydantic-settings`
- **Base de données** : [PostgreSQL 17](https://www.postgresql.org/)
- **Sécurité** : JWT (JSON Web Tokens) & Bcrypt (Hashage) via `passlib` et `python-jose`
- **Infrastructure** : [Docker](https://www.docker.com/) & [Docker Compose](https://docs.docker.com/compose/)
- **Migrations** : [Alembic](https://alembic.sqlalchemy.org/) (Gestion pro des versions de la base de données)

---

## 📂 Architecture du Projet (Feature-based)

Nous utilisons une architecture **orientée fonctionnalités (modules)**. Tout ce qui concerne un domaine métier est regroupé ensemble.

```text
backend/
├── app/
│   ├── core/                # Configuration globale & Infrastructure
│   │   ├── config.py        # Chargement du .env et validation Pydantic
│   │   ├── database.py      # Engine SQLModel et gestion des sessions
│   │   └── security.py      # Utils : Hashage (Bcrypt) et JWT
│   │
│   ├── api/                 # Point central des routes de l'API
│   │   └── main_router.py   # Agrégation de tous les routers (Users, OAuth, etc.)
│   │
│   ├── modules/             # Cœur métier (Logique par fonctionnalité)
│   │   └── users/           # Module Utilisateurs
│   │       ├── model.py     # Modèles de données (Tables SQLModel)
│   │       ├── shemas.py    # Modèles Pydantic (Input/Output API)
│   │       ├── services.py  # Logique métier pure (CRUD, etc.)
│   │       ├── router.py    # Endpoints spécifiques (Register, Login, Me...)
│   │       └── dependencies.py # Dépendances (ex: get_current_user)
│   │
│   └── main.py              # Point d'entrée de l'application FastAPI
│
├── migrations/              # Scripts de migration Alembic
├── alembic.ini              # Configuration Alembic
├── requirements.txt         # Dépendances Python
└── clean.sh                 # Script de nettoyage (__pycache__)
```

---

## ⚙️ Installation et Lancement

### 1. Variables d'Environnement
Créez un fichier `.env` dans le dossier `backend/`. 
Indispensable pour la sécurité :
```env
POSTGRES_USER=...
POSTGRES_PASSWORD=...
POSTGRES_SERVER=db  # 'localhost' hors docker, 'db' dans docker
POSTGRES_PORT=5432
POSTGRES_DB=...
SECRET_KEY=...      # Clé pour signer les JWT
```

### 2. Docker Compose (Base + Backend)
Depuis la racine :
```bash
docker compose up -d
```
Cela lance PostgreSQL et le serveur FastAPI simultanément.

---

## 🗄️ Gestion de la Base de Données (Alembic)

La base de données est gérée par **Alembic**. Ne tentez pas de modifier les tables manuellement.

**Workflow rapide :**
```bash
cd backend
python -m alembic revision --autogenerate -m "Description"
python -m alembic upgrade head
```

👉 Pour les procédures avancées (renommer une colonne, réinitialiser la DB), consultez le guide dédié : **[database.md](./database.md)**.

---

## 📖 Développement & Outils

- **Documentation Interactives** : [http://localhost:8000/docs](http://localhost:8000/docs)
- **Nettoyage** : `./clean.sh` supprime tous les `__pycache__`.
- **Imports** : Utilisez des **imports relatifs** (ex: `from ...core import get_session`).

---

## 🔒 Sécurité
- **Mots de passe** : Toujours hashés en base via `bcrypt`.
- **Authentification** : Système de tokens JWT (Bearer).
- **Accès** : Utilisation de la dépendance `get_current_user` pour protéger les routes.
