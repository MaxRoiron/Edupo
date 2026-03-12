# 🚀 Edupo Backend - Documentation & Guide

Bienvenue dans la documentation technique du backend d'Edupo. Ce projet est conçu pour être **scalable**, **propre** et **sécurisé**, en suivant les meilleures pratiques de développement Python modernes.

---

## 🛠 Tech Stack

- **Framework** : [FastAPI](https://fastapi.tiangolo.com/) (Performance et documentation automatique)
- **ORM** : [SQLModel](https://sqlmodel.tiangolo.com/) (Combinaison parfaite de SQLAlchemy et Pydantic)
- **Validation & Settings** : [Pydantic v2](https://docs.pydantic.dev/) & `pydantic-settings`
- **Base de données** : [PostgreSQL 17](https://www.postgresql.org/)
- **Sécurité** : JWT (JSON Web Tokens) & Bcrypt (Hashage) via `bcrypt` et `python-jose`
- **OAuth** : [Authlib](https://docs.authlib.org/) (Google OAuth 2.0)
- **Infrastructure** : [Docker](https://www.docker.com/) & [Docker Compose](https://docs.docker.com/compose/)
- **Migrations** : [Alembic](https://alembic.sqlalchemy.org/) (Gestion pro des versions de la base de données)
- **Tests** : [Pytest](https://docs.pytest.org/) & [pytest-cov](https://pytest-cov.readthedocs.io/)

---

## 📂 Architecture du Projet (Feature-based)

Nous utilisons une architecture **orientée fonctionnalités (modules)**. Tout ce qui concerne un domaine métier est regroupé ensemble.

```text
backend/
├── app/
│   ├── core/                    # Configuration globale & Infrastructure
│   │   ├── config.py            # Chargement du .env et validation Pydantic
│   │   ├── database.py          # Engine SQLModel et gestion des sessions
│   │   └── security.py          # Utils : Hashage (Bcrypt) et JWT
│   │
│   ├── api/                     # Point central des routes de l'API
│   │   └── main_router.py       # Agrégation de tous les routers
│   │
│   ├── modules/                 # Cœur métier (Logique par fonctionnalité)
│   │   ├── users/               # Module Utilisateurs
│   │   │   ├── model.py         # Modèle User (Table SQLModel)
│   │   │   ├── shemas.py        # Schémas Pydantic (UserCreate, UserView, etc.)
│   │   │   ├── services.py      # Logique métier (CRUD utilisateurs)
│   │   │   ├── router.py        # Endpoints (Register, Login, Me, Admin)
│   │   │   └── dependencies.py  # Dépendances (get_current_user)
│   │   │
│   │   ├── user_data/           # Module Données Utilisateur (Profil)
│   │   │   ├── model.py         # Modèles UserData, ProfessionalStatus, etc.
│   │   │   ├── shemas.py        # Schémas Pydantic (Create, Update, View)
│   │   │   ├── services.py      # Logique métier (CRUD données profil)
│   │   │   └── router.py        # Endpoints données utilisateur & admin
│   │   │
│   │   ├── country/             # Module Pays 🆕
│   │   │   ├── model.py         # Modèle Country (name, iso_code)
│   │   │   ├── shemas.py        # Schémas Pydantic (CountryCreate, CountryUpdate, CountryView)
│   │   │   ├── services.py      # Logique métier (à implémenter)
│   │   │   └── router.py        # Endpoints pays (à implémenter)
│   │   │
│   │   ├── political_party/     # Module Partis Politiques
│   │   │   ├── model.py         # Party, Domain, Program, Topic, ElectionType, PartyVote 🆕
│   │   │   ├── shemas.py        # Schémas associés
│   │   │   ├── services.py      # Logique métier (à implémenter)
│   │   │   └── router.py        # Endpoints (à implémenter)
│   │   │
│   │   ├── law/                 # Module Lois 🆕
│   │   │   ├── model.py         # Law, Vote, VoteResult
│   │   │   ├── shemas.py        # Schémas associés
│   │   │   ├── services.py      # Logique métier (à implémenter)
│   │   │   └── router.py        # Endpoints (à implémenter)
│   │   │
│   │   ├── user_vote/           # Module Votes Utilisateurs 🆕
│   │   │   ├── model.py         # UserVote
│   │   │   ├── shemas.py        # Schémas associés
│   │   │   ├── services.py      # Logique métier (à implémenter)
│   │   │   └── router.py        # Endpoints (à implémenter)
│   │   │
│   │   └── external_oauth/      # Module OAuth Externe
│   │       └── googleOAuth.py   # Intégration Google OAuth 2.0
│   │
│   └── main.py                  # Point d'entrée de l'application FastAPI
│
├── migrations/                  # Scripts de migration Alembic
├── tests/                       # Tests d'intégration
│   ├── conftest.py              # Fixtures pytest (sessions, users, admin)
│   └── integration/             # Tests par fonctionnalité
│       ├── test_auth.py         # Tests Register & Login
│       ├── test_user.py         # Tests CRUD utilisateur
│       ├── test_user_data.py    # Tests données profil
│       ├── test_professional_status.py
│       ├── test_social_status.py
│       └── test_gender_identity.py
│
├── alembic.ini                  # Configuration Alembic
├── requirements.txt             # Dépendances Python
├── Dockerfile                   # Image Docker du backend
├── docker-compose.test.yml      # Orchestration pour les tests
├── tests.sh                     # Script pour lancer les tests via Docker
├── pytest.ini                   # Configuration pytest (coverage)
└── clean.sh                     # Script de nettoyage (__pycache__)
```

---

## ⚙️ Installation et Lancement

### 1. Variables d'Environnement
Créez un fichier `.env` dans le dossier `backend/`. 
Indispensable pour la sécurité :
```env
# Base de données
POSTGRES_USER=...
POSTGRES_PASSWORD=...
POSTGRES_SERVER=db            # 'localhost' hors docker, 'db' dans docker
POSTGRES_PORT=5432
POSTGRES_DB=...

# Sécurité
SECRET_KEY=...                # Clé pour signer les JWT
ALGORITHM=HS256               # Algorithme JWT (par défaut HS256)
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Middleware
MIDDLEWARE_SECRET_KEY=...     # Clé pour le SessionMiddleware (OAuth)

# Google OAuth 2.0
GOOGLE_CLIENT_ID=...          # Depuis Google Cloud Console
GOOGLE_CLIENT_SECRET=...      # Depuis Google Cloud Console
```

### 2. Docker Compose (Base + Backend)
Depuis la racine :
```bash
docker compose up -d
```
Cela lance PostgreSQL et le serveur FastAPI simultanément.

---

## 📦 Modules

### 1. Module `users` — Gestion des Utilisateurs

Le module principal pour la création de comptes, l'authentification et la gestion des profils.

**Modèle `User`** :
| Champ | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` (PK) | Identifiant auto-incrémenté |
| `username` | `str` | Nom d'utilisateur (indexé) |
| `email` | `str` | Email unique (indexé) |
| `hashed_password` | `str` | Mot de passe hashé (bcrypt) |
| `role` | `str` | Rôle : `user` ou `admin` (indexé) |
| `ggid` | `str \| None` | Google ID (pour les comptes OAuth) |
| `created_at` | `datetime` | Date de création du compte (auto) |

**Relation** : Un `User` a un `UserData` optionnel (relation 1:1, cascade delete).

### 2. Module `user_data` — Données de Profil

Gère les informations démographiques et sociales des utilisateurs. Contient aussi les **tables de référence** administrables.

**Modèle `UserData`** :
| Champ | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` (PK) | Identifiant auto-incrémenté |
| `age` | `int \| None` | Âge de l'utilisateur |
| `user_id` | `int` (FK → `user.id`) | Lien vers l'utilisateur (unique) |
| `professional_status_id` | `int \| None` (FK) | Statut professionnel |
| `social_status_id` | `int \| None` (FK) | Statut social |
| `gender_identity_id` | `int \| None` (FK) | Identité de genre |

**Tables de référence** (administrables par les admins) :
- `ProfessionalStatus` : (`id`, `name`)
- `SocialStatus` : (`id`, `name`)
- `GenderIdentities` : (`id`, `name`)

### 3. Module `country` — Pays 🆕

Gère la liste des pays référencés dans l'application. Utilisé comme clé étrangère par le module `institution`.

**Modèle `Country`** :
| Champ | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` (PK) | Identifiant auto-incrémenté |
| `name` | `str` | Nom du pays (indexé, unique) |
| `iso_code` | `str` | Code ISO du pays (indexé, unique) |

**Schémas Pydantic** :
- `CountryCreate` : `name`, `iso_code`
- `CountryUpdate` : `name?`, `iso_code?`
- `CountryView` : `id`, `name`, `iso_code`

> ⚠️ **État** : Modèle et schémas définis. Le `router.py` et `services.py` sont encore vides (à implémenter).

### 4. Module `institution` — Institutions 🆕

Gère les institutions politiques. Ce module introduit **3 modèles** liés entre eux et au module `country`.

**Modèle `Power`** (Pouvoirs : Exécutif, Législatif, Judiciaire...) :
| Champ | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` (PK) | Identifiant auto-incrémenté |
| `name` | `str` | Nom du pouvoir (indexé, unique) |
| `description` | `str \| None` | Description optionnelle |

**Modèle `InstitutionType`** (Types d'institutions) :
| Champ | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` (PK) | Identifiant auto-incrémenté |
| `name` | `str` | Nom du type (indexé, unique) |
| `description` | `str \| None` | Description optionnelle |

**Modèle `Institution`** :
| Champ | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` (PK) | Identifiant auto-incrémenté |
| `name` | `str` | Nom de l'institution (indexé) |
| `description` | `str \| None` | Description optionnelle |
| `country_id` | `int` (FK → `country.id`) | Pays de rattachement |
| `power_id` | `int` (FK → `power.id`) | Pouvoir associé |
| `institution_type_id` | `int` (FK → `institutiontype.id`) | Type d'institution |

**Relations** :
- `Institution` → `Country` (N:1)
- `Institution` → `Power` (N:1)
- `Institution` → `InstitutionType` (N:1)

**Schémas Pydantic** :
- `PowerCreate/Update/View`
- `InstitutionTypeCreate/Update/View`
- `InstitutionCreate/Update/View`

> ⚠️ **État** : Modèles et schémas définis. Le `router.py` et `services.py` sont encore vides (à implémenter).

### 5. Module `political_figure` — Personnalités Politiques 🆕

Gère les politiciens et l'historique de leurs fonctions.

**Modèle `PoliticalFigure`** :
| Champ | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` (PK) | Identifiant auto-incrémenté |
| `name` | `str` | Prénom (indexé) |
| `last_name` | `str` | Nom de famille (indexé) |
| `party_id` | `int` (FK) | Parti actuel |
| `country_id` | `int` (FK) | Pays d'origine |

**Modèle `PoliticalRole`** :
| Champ | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` (PK) | Identifiant auto-incrémenté |
| `name` | `str` | Nom du rôle (ex: Ministre) |
| `start_date` | `datetime` | Date de début |
| `end_date` | `datetime \| None` | Date de fin optionnelle |
| `figure_id` | `int` (FK) | Lien vers la personnalité |

### 6. Module `political_party` — Partis et Programmes 🆕

Module complexe gérant les partis, leurs idéologies et leurs programmes par élection.

**Modèle `PoliticalParty`** :
| Champ | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` (PK) | Identifiant auto-incrémenté |
| `name` | `str` | Nom complet |
| `abbreviation` | `str \| None` | Acronyme (ex: LFI, RN) |
| `country_id` | `int` (FK) | Pays d'ancrage |

**Programmes et Thématiques** :
- `PoliticalProgram` : Regroupe les propositions pour une année et un type d'élection.
- `PoliticalTopic` : Un point de programme spécifique lié à un domaine.
- `Domain` : Thématique (Économie, Écologie, International...).
- `ElectionType` : Type de scrutin (Présidentielle, Européennes...).

**Votes des Partis** :
- `PartyVote` : Consigne de vote officielle d'un parti sur une loi. 🆕

### 7. Module `law` — Lois et Scrutins 🆕

Gère les textes de loi et les résultats des votes officiels dans les institutions.

**Modèles** :
- `Law` : Titre, description, domaine, URL source, pays (FK).
- `Vote` : Référentiel des positions (Pour, Contre, Abstention).
- `VoteResult` : Résultats agrégés d'un vote dans une institution spécifique.

### 8. Module `user_vote` — Participation Citoyenne 🆕

Gère les votes exprimés par les utilisateurs de l'application sur les différentes lois.

**Modèle `UserVote`** :
- Lie un utilisateur, une loi et une position de vote.

### 9. Modules en cours de création (placeholders) 🆕

| Module | Objectif prévu |
| :--- | :--- |
| `votes/` | (Ancienne structure, voir `user_vote` et `law`) |

### 6. Module `external_oauth` — OAuth Google

Permet l'authentification via Google. Le flux est le suivant :
1. L'utilisateur est redirigé vers Google (`/auth/google/login`)
2. Après connexion, Google redirige vers le callback (`/auth/google/callback`)
3. Si l'utilisateur n'existe pas, un compte est créé automatiquement avec son `ggid`
4. Un token JWT est retourné

---

## 🌐 API Endpoints

### OAuth & Authentification
| Méthode | Route | Tags | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/register` | OAuth | Inscription (retourne un token JWT) |
| `POST` | `/login` | OAuth | Connexion par email/password |
| `GET` | `/auth/google/login` | OAuth | Redirige vers Google pour OAuth |
| `GET` | `/auth/google/callback` | OAuth | Callback Google (crée le compte si nécessaire) |

### Utilisateur Connecté
| Méthode | Route | Tags | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/me` | User | Récupère le profil de l'utilisateur connecté |
| `PATCH` | `/me` | User | Met à jour le profil (username, email, password) |
| `DELETE` | `/me` | User | Supprime le compte (interdit pour les admins) |
| `POST` | `/me/data` | User | Crée les données de profil |
| `GET` | `/me/data` | User | Récupère les données de profil |
| `PATCH` | `/me/data` | User | Met à jour les données de profil |
| `PUT` | `/me/data/reset` | User | Réinitialise les données de profil |

### Administration
| Méthode | Route | Tags | Description |
| :--- | :--- | :--- | :--- |
| `DELETE` | `/admin/{user_email}` | Admin | Supprime un utilisateur par email |
| `PUT` | `/admin/{user_email}/reset` | Admin | Réinitialise les données d'un utilisateur |

### Données de Référence — Statut Professionnel (`professional`)
| Méthode | Route | Tags | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/admin/user_data/professional` | Admin | Crée un statut professionnel |
| `GET` | `/user_data/professional` | UserData Content | Liste tous les statuts professionnels |
| `GET` | `/user_data/professional/{id}` | UserData Content | Récupère un statut par ID |
| `PATCH` | `/admin/user_data/professional/{id}` | Admin | Met à jour un statut |
| `DELETE` | `/admin/user_data/professional/{id}` | Admin | Supprime un statut |

### Données de Référence — Statut Social (`social`)
| Méthode | Route | Tags | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/admin/user_data/social` | Admin | Crée un statut social |
| `GET` | `/user_data/social` | UserData Content | Liste tous les statuts sociaux |
| `GET` | `/user_data/social/{id}` | UserData Content | Récupère un statut par ID |
| `PATCH` | `/admin/user_data/social/{id}` | Admin | Met à jour un statut |
| `DELETE` | `/admin/user_data/social/{id}` | Admin | Supprime un statut |

### Données de Référence — Identité de Genre (`gender`)
| Méthode | Route | Tags | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/admin/user_data/gender` | Admin | Crée une identité de genre |
| `GET` | `/user_data/gender` | UserData Content | Liste toutes les identités de genre |
| `GET` | `/user_data/gender/{id}` | UserData Content | Récupère une identité par ID |
| `PATCH` | `/admin/user_data/gender/{id}` | Admin | Met à jour une identité |
| `DELETE` | `/admin/user_data/gender/{id}` | Admin | Supprime une identité |

### Endpoints pour `country`, `institution`, `political_figure`, `political_party`, `law` & `user_vote` 🆕
> 🚧 Les routers et services pour ces nouveaux modules sont en cours d'implémentation. Les endpoints seront documentés une fois le développement métier avancé.

### Endpoints Utilitaires
| Méthode | Route | Description |
| :--- | :--- | :--- |
| `GET` | `/` | Message d'accueil (`Hello World`) |
| `GET` | `/health` | Health check (`{"status": "healthy"}`) |

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

## 🧪 Tests

Le backend dispose d'une suite de **tests d'intégration** utilisant `pytest`. Les tests sont exécutés dans un environnement Docker isolé avec une base de données dédiée.

### Lancer les tests
```bash
cd backend
./tests.sh
```

Cette commande :
1. Lance un conteneur PostgreSQL de test (port `5433`)
2. Exécute `pytest` avec couverture de code
3. Détruit les conteneurs de test

### Structure des fixtures (`conftest.py`)
| Fixture | Description |
| :--- | :--- |
| `session` | Session SQLModel de test (crée/supprime les tables) |
| `client` | `TestClient` FastAPI avec session injectée |
| `test_user` | Utilisateur de test (rôle `user`) |
| `auth_user` | Client authentifié (rôle `user`) |
| `test_user_with_user_data` | Utilisateur avec `UserData` |
| `auth_user_with_user_data` | Client authentifié avec données de profil |
| `test_admin` | Utilisateur admin |
| `auth_admin` | Client authentifié (rôle `admin`) |

---

## 📖 Développement & Outils

- **Documentation Interactive** : [http://localhost:8000/docs](http://localhost:8000/docs) (Swagger UI auto-générée)
- **Nettoyage** : `./clean.sh` supprime tous les `__pycache__` et fichiers de coverage.
- **Imports** : Utilisez des **imports relatifs** (ex: `from ...core import get_session`).
- **Couverture de code** : Configurée dans `pytest.ini` (`--cov=app --cov-report=term-missing`).

---

## 🔒 Sécurité

### Authentification par mot de passe
- **Mots de passe** : Toujours hashés en base via `bcrypt`.
- **Tokens JWT** : Générés via `python-jose` avec l'algorithme `HS256`.
- **Expiration** : Configurable via `ACCESS_TOKEN_EXPIRE_MINUTES` (défaut: 30 min).
- **Accès protégé** : Utilisation de la dépendance `get_current_user` pour protéger les routes.

### Authentification OAuth Google
- **Authlib** : Gère le flux OAuth 2.0 avec Google.
- **SessionMiddleware** : Nécessaire pour stocker l'état OAuth en session (clé: `MIDDLEWARE_SECRET_KEY`).
- **Création automatique** : Les utilisateurs Google sont créés automatiquement au premier login.

### Rôles & Permissions
- **`user`** : Accès à ses propres données.
- **`admin`** : Peut supprimer des utilisateurs et gérer les tables de référence.
- Les admins ne peuvent **pas se supprimer eux-mêmes**.

### CORS
- Actuellement configuré en mode permissif (`allow_origins=["*"]`).
- ⚠️ **En production**, restreindre aux domaines autorisés.
