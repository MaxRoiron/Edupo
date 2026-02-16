# 🚀 Edupo Backend - Documentation & Guide

Bienvenue dans la documentation technique du backend d'Edupo. Ce projet est conçu pour être **scalable**, **propre** et **sécurisé**, en suivant les meilleures pratiques de développement Python modernes.

---

## 🛠 Tech Stack

- **Framework** : [FastAPI](https://fastapi.tiangolo.com/) (Performance et documentation automatique)
- **ORM** : [SQLModel](https://sqlmodel.tiangolo.com/) (Combinaison parfaite de SQLAlchemy et Pydantic)
- **Base de données** : [PostgreSQL 17](https://www.postgresql.org/)
- **Validation & Settings** : [Pydantic v2](https://docs.pydantic.dev/)
- **Infrastructure** : [Docker](https://www.docker.com/) & [Docker Compose](https://docs.docker.com/compose/)

---

## 📂 Architecture du Projet (Feature-based)

Nous utilisons une architecture **orientée fonctionnalités (modules)**. Contrairement à une structure technique classique (tous les modèles dans un dossier, tous les routers dans un autre), nous regroupons tout ce qui concerne un domaine métier ensemble.

```text
backend/app/
├── core/                # Configuration globale & Infrastructure
│   ├── config.py        # Chargement du .env et validation Pydantic
│   └── database.py      # Engine SQLModel et gestion des sessions
│
├── api/                 # Point central des routes de l'API
│   └── main_router.py   # Agrégation de tous les routers (Users, Courses, etc.)
│
├── modules/             # Cœur métier (Logique par fonctionnalité)
│   └── users/           # Exemple : Module Utilisateurs
│       ├── __init__.py  # Exposition des modèles clés
│       ├── models.py    # Modèles de données (Tables SQLModel)
│       ├── schemas.py   # Modèles Pydantic (Input/Output API)
│       ├── service.py   # Logique métier pure
│       └── router.py    # Endpoints spécifiques (GET /users, ...)
│
└── main.py              # Point d'entrée de l'application FastAPI
```

### Pourquoi ce choix ?
- **Cohésion forte** : Tout ce qui touche à l'utilisateur est dans le dossier `users/`.
- **Scalabilité** : Plusieurs développeurs peuvent travailler sur des fonctionnalités différentes sans se marcher dessus.
- **Microservices-Ready** : Chaque module est pré-découpé et peut être extrait facilement plus tard.

---

## ⚙️ Installation et Lancement

### 1. Variables d'Environnement
Copiez le modèle de configuration (ou demandez-le aux admins) dans un fichier `.env` à la racine de `backend/`. 
**Note** : Ce fichier est ignoré par Git pour votre sécurité.

### 2. Lancer la Base de Données (Docker)
Depuis la racine du projet (`Edupo/`) :
```bash
docker-compose up -d
```
*Le dossier `docker/postgres_data` est utilisé pour la persistance locale.*

### 3. Lancer le serveur FastAPI
Depuis la racine du projet (`Edupo/`) :
```bash
# Assurez-vous d'avoir activé votre venv
uvicorn backend.app.main:app --reload
```

---

## 📖 Développement & Outils

- **Documentation Interactives** : 
  - Swagger UI : [http://localhost:8000/docs](http://localhost:8000/docs)
  - Redoc : [http://localhost:8000/redoc](http://localhost:8000/redoc)
- **Logs SQL** : En mode développement, toutes les requêtes SQL sont affichées dans votre terminal (grâce à `echo=True` dans `core/database.py`).
- **Imports** : Utilisez toujours des **imports relatifs** au sein de l'application (ex: `from ..core import engine`).

---

## 🔒 Sécurité
- Les mots de passe en clair ne sont jamais commités.
- Les données PostgreSQL sont isolées dans le dossier `docker/`, exclu de Git.
- Nous utilisons `PBKDF2` (ou équivalent) pour le hashage des mots de passe (implémentation prévue dans `core/security.py`).
