# 🎓 Édupo — Liste complète de TOUTES les features

> [!NOTE]
> Ce document recense de manière exhaustive chaque feature de l'application Édupo, couvrant le **backend (FastAPI)**, la **base de données (PostgreSQL)**, l'**app mobile (Flutter)** et le **frontend web (Next.js)**.

---

## 📐 Architecture Globale

| Composant | Technologie | Rôle |
|---|---|---|
| **Backend API** | FastAPI (Python 3.11) | REST API, logique métier, scraping |
| **Base de données** | PostgreSQL 17 (Alpine) | Stockage persistant |
| **ORM** | SQLModel / SQLAlchemy | Modèles + requêtes DB |
| **Migrations** | Alembic | Versionnement du schéma DB |
| **App Mobile** | Flutter (Dart 3.11) | Client Android / iOS / Web / Desktop |
| **Frontend Web** | Next.js 15 (App Router) + TypeScript + Tailwind CSS 4 | Interface web |
| **Infra** | Docker + Docker Compose | Orchestration des services |
| **Tests** | Pytest + pytest-cov | Tests unitaires et d'intégration |
| **Serveur ASGI** | Uvicorn | Serveur HTTP async |

---

## 🗄️ 1. Base de données — Modèles & schéma complet

### 1.1 [User](file:///home/max/Edupo/backend/app/modules/users/model.py#5-15) — Utilisateurs
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | Auto-incrément |
| `username` | `str` | Indexé, non null |
| [email](file:///home/max/Edupo/backend/app/modules/users/services.py#15-17) | `str` | Indexé, unique, non null |
| `hashed_password` | `str` | Hash bcrypt |
| `role` | `str` | `"user"` ou `"admin"`, indexé |
| [ggid](file:///home/max/Edupo/backend/app/modules/users/services.py#12-14) | `str?` | Google ID (OAuth) |
| `created_at` | `datetime` | Timestamp UTC auto |

- **Relation** : [User](file:///home/max/Edupo/backend/app/modules/users/model.py#5-15) → [UserData](file:///home/max/Edupo/backend/app/modules/user_data/model.py#19-31) (one-to-one, cascade delete)

### 1.2 [UserData](file:///home/max/Edupo/backend/app/modules/user_data/model.py#19-31) — Données personnelles utilisateur
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| [age](file:///home/max/Edupo/mobile/lib/main.dart#140-157) | `int?` | Nullable |
| `phone_number` | `str?` | Nullable |
| `user_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK(user.id) | Unique |
| `professional_status_id` | `int?` FK | → ProfessionalStatus |
| `social_status_id` | `int?` FK | → SocialStatus |
| `gender_identity_id` | `int?` FK | → GenderIdentities |

- **Relations** : vers [ProfessionalStatus](file:///home/max/Edupo/backend/app/modules/user_data/model.py#4-7), [SocialStatus](file:///home/max/Edupo/backend/app/modules/user_data/model.py#9-12), [GenderIdentities](file:///home/max/Edupo/backend/app/modules/user_data/model.py#14-17)

### 1.3 [ProfessionalStatus](file:///home/max/Edupo/backend/app/modules/user_data/model.py#4-7) — Statuts professionnels
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `name` | `str` | Indexé (ex: "Étudiant(e)", "Salarié(e)", "Cadre"…) |

- **28 statuts** prédéfinis dans le seed (de "Étudiant(e)" à "Autre")

### 1.4 [SocialStatus](file:///home/max/Edupo/backend/app/modules/user_data/model.py#9-12) — Statuts sociaux
| Champ | Type |
|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK |
| `name` | `str` (indexé) |

### 1.5 [GenderIdentities](file:///home/max/Edupo/backend/app/modules/user_data/model.py#14-17) — Identités de genre
| Champ | Type |
|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK |
| `name` | `str` (indexé) |

- **13 identités** prédéfinies (Homme, Femme, Non-binaire, Transgenre, etc.)

### 1.6 [Country](file:///home/max/Edupo/backend/app/modules/country/model.py#3-7) — Pays
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `name` | `str` | Unique, indexé |
| `iso_code` | `str` | Unique, indexé (ex: "FR") |

### 1.7 [Institution](file:///home/max/Edupo/backend/app/modules/institution/model.py#17-28) — Institutions politiques
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `name` | `str` | Indexé |
| `description` | `str?` | |
| `country_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Country |
| `power_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Power |
| `institution_type_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → InstitutionType |

### 1.8 [Power](file:///home/max/Edupo/backend/app/modules/institution/model.py#5-9) — Pouvoirs (Exécutif, Législatif, Judiciaire)
| Champ | Type |
|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK |
| `name` | `str` (unique, indexé) |
| `description` | `str?` |

### 1.9 [InstitutionType](file:///home/max/Edupo/backend/app/modules/institution/model.py#11-15) — Types d'institution
| Champ | Type |
|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK |
| `name` | `str` (unique, indexé) |
| `description` | `str?` |

### 1.10 [PoliticalParty](file:///home/max/Edupo/backend/app/modules/political_party/model.py#5-15) — Partis politiques
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `name` | `str` | Indexé |
| `abbreviation` | `str?` | Indexé |
| `description` | `str?` | |
| `ideology_summary` | `str?` | |
| `country_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Country |

- **Relation** : [PoliticalParty](file:///home/max/Edupo/backend/app/modules/political_party/model.py#5-15) → `PoliticalProgram[]` (one-to-many)

### 1.11 [PoliticalProgram](file:///home/max/Edupo/backend/app/modules/political_party/model.py#37-46) — Programmes politiques
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `name` | `str` | Indexé |
| `party_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → PoliticalParty |
| `year` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) | Indexé |
| `election_type_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → ElectionType |

### 1.12 [PoliticalTopic](file:///home/max/Edupo/backend/app/modules/political_party/model.py#23-30) — Sujets de programme
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `description` | `str` | |
| `program_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → PoliticalProgram |
| `domain_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Domain |

### 1.13 [ElectionType](file:///home/max/Edupo/backend/app/modules/political_party/model.py#32-35) — Types d'élection
| Champ | Type |
|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK |
| `name` | `str` |

### 1.14 [Domain](file:///home/max/Edupo/backend/app/modules/political_party/model.py#17-21) — Domaines thématiques
| Champ | Type |
|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK |
| `name` | `str` (indexé) |
| `description` | `str?` |

### 1.15 [PoliticalFigure](file:///home/max/Edupo/backend/app/modules/political_figure/model.py#7-16) — Personnalités politiques
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `name` | `str` | Indexé |
| `last_name` | `str` | Indexé |
| `party_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → PoliticalParty |
| `country_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Country |

### 1.16 [PoliticalRole](file:///home/max/Edupo/backend/app/modules/political_figure/model.py#18-26) — Rôles / mandats des figures politiques
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `name` | `str` | Indexé |
| `start_date` | `datetime` | |
| `end_date` | `datetime?` | Nullable (en cours) |
| `figure_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → PoliticalFigure |

### 1.17 [Law](file:///home/max/Edupo/backend/app/modules/law/model.py#8-24) — Lois
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `title` | `str` | Indexé |
| `subtitle` | `str?` | |
| `description` | `str` | Texte descriptif complet |
| `domain_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Domain |
| `source_url` | `str?` | Lien vers la source, indexé |
| `vote_date` | `datetime?` | Date du vote |
| `scrutin_id` | `str?` | ID du scrutin (nosdeputes.fr), indexé |
| `category` | `str?` | Catégorie thématique |
| `created_at` | `datetime` | Timestamp auto |
| `country_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Country |
| `is_active` | `bool` | Par défaut `true` |

### 1.18 [Vote](file:///home/max/Edupo/backend/app/modules/law/model.py#25-28) — Positions de vote
| Champ | Type |
|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK |
| `position` | `str` (unique, indexé — ex: "Pour", "Contre", "Abstention") |

### 1.19 [VoteResult](file:///home/max/Edupo/backend/app/modules/law/model.py#29-41) — Résultats de vote par institution
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `law_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Law |
| `institution_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Institution |
| `total_for` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) | |
| `total_abstention` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) | |
| `total_against` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) | |
| `adopted` | `bool` | |
| `vote_date` | `datetime` | |

### 1.20 [UserVote](file:///home/max/Edupo/backend/app/modules/user_vote/model.py#5-13) — Votes des utilisateurs sur les lois
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `user_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → User |
| `law_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Law |
| `position_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Vote |

### 1.21 [PartyVote](file:///home/max/Edupo/backend/app/modules/political_party/model.py#48-56) — Votes des partis sur les lois
| Champ | Type | Détails |
|---|---|---|
| [id](file:///home/max/Edupo/backend/app/modules/users/services.py#9-11) | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) PK | |
| `user_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → User |
| `law_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Law |
| `position_id` | [int](file:///home/max/Edupo/mobile/lib/models/political_party.dart#3-16) FK | → Vote |

---

## ⚙️ 2. Backend API — Endpoints & features

### 2.1 🔐 Authentification & Gestion Utilisateur

| Endpoint | Méthode | Auth | Description |
|---|---|---|---|
| `POST /register` | POST | ❌ | Inscription (username, email, password). Retourne un JWT. Hash bcrypt du mot de passe. |
| `POST /login` | POST | ❌ | Connexion email/password. Retourne un JWT Bearer. |
| `GET /me` | GET | ✅ | Récupère le profil de l'utilisateur connecté (id, username, email, role, ggid, created_at). |
| `PATCH /me` | PATCH | ✅ | Met à jour le profil (username, email, password, role, ggid). Vérification d'unicité email. |
| `DELETE /me` | DELETE | ✅ | Supprime le compte de l'utilisateur connecté (interdit si admin). |

**Détails sécurité :**
- Hashing : **bcrypt** (via `bcrypt.hashpw`)
- Tokens : **JWT** via `python-jose` (HS256)
- Expiration : **30 minutes** par défaut (configurable)
- Middleware : **OAuth2PasswordBearer** (FastAPI)
- Dependency injection : [get_current_user()](file:///home/max/Edupo/backend/app/modules/users/dependencies.py#10-18) décode le token et vérifie l'existence en DB

### 2.2 🔑 Google OAuth 2.0

| Endpoint | Méthode | Description |
|---|---|---|
| `GET /auth/google/login` | GET | Redirige vers la page de consentement Google |
| `GET /auth/google/callback` | GET | Callback OAuth, crée l'utilisateur si nouveau, retourne JWT |

**Détails :**
- Bibliothèque : **Authlib** (intégration Starlette)
- Scopes : `openid email profile`
- Création automatique du user à partir du Google `sub` (ggid)
- Session middleware pour gérer le flow OAuth

### 2.3 📊 Données utilisateur (UserData)

| Endpoint | Méthode | Auth | Description |
|---|---|---|---|
| `POST /me/data` | POST | ✅ | Crée les données perso (age, phone, genre, profession, statut social) |
| `GET /me/data` | GET | ✅ | Récupère les données perso |
| `PATCH /me/data` | PATCH | ✅ | Met à jour les données perso |
| `PUT /me/data/reset` | PUT | ✅ | Réinitialise les données perso |

### 2.4 📋 Référentiels UserData (statuts, genres)

| Endpoint | Méthode | Auth | Description |
|---|---|---|---|
| `GET /user_data/professional` | GET | ✅ | Liste tous les statuts professionnels |
| `GET /user_data/professional/{id}` | GET | ✅ | Détail d'un statut pro |
| `GET /user_data/social` | GET | ✅ | Liste tous les statuts sociaux |
| `GET /user_data/social/{id}` | GET | ✅ | Détail d'un statut social |
| `GET /user_data/gender` | GET | ✅ | Liste toutes les identités de genre |
| `GET /user_data/gender/{id}` | GET | ✅ | Détail d'une identité de genre |

### 2.5 ⚖️ Lois (Laws)

| Endpoint | Méthode | Auth | Description |
|---|---|---|---|
| `GET /law` | GET | ❌ | Liste toutes les lois (publique) |
| `GET /law/{id}` | GET | ❌ | Détail d'une loi |
| `GET /law/assembly_votes/{scrutin_id}` | GET | ❌ | Récupère les résultats de vote depuis **nosdeputes.fr** Open Data (API proxy) |

### 2.6 🗳️ Votes

| Endpoint | Méthode | Auth | Description |
|---|---|---|---|
| `GET /vote` | GET | ✅ | Liste toutes les positions de vote |
| `GET /vote/{id}` | GET | ✅ | Détail d'une position |

### 2.7 🏛️ Institutions

| Endpoint | Méthode | Auth | Description |
|---|---|---|---|
| `GET /institution` | GET | ✅ | Liste toutes les institutions |
| `GET /institution/{id}` | GET | ✅ | Détail d'une institution |
| `GET /institution_type` | GET | ✅ | Liste les types d'institution |
| `GET /institution_type/{id}` | GET | ✅ | Détail d'un type |
| `GET /power` | GET | ✅ | Liste les pouvoirs (exécutif, législatif, judiciaire) |
| `GET /power/{id}` | GET | ✅ | Détail d'un pouvoir |

### 2.8 🌍 Pays

| Endpoint | Méthode | Auth | Description |
|---|---|---|---|
| `GET /country` | GET | ✅ | Liste tous les pays |
| `GET /country/{id}` | GET | ✅ | Détail d'un pays |

### 2.9 👑 Administration (Admin)

> [!IMPORTANT]
> Tous les endpoints admin requièrent `role == "admin"`.

| Endpoint | Méthode | Description |
|---|---|---|
| `GET /admin/users` | GET | Liste TOUS les utilisateurs avec leurs données (age, genre, profession) |
| `DELETE /admin/{user_email}` | DELETE | Supprime un utilisateur par email |
| `PUT /admin/{user_email}/reset` | PUT | Réinitialise les données d'un utilisateur |
| `POST /admin/law` | POST | Créer une loi |
| `PATCH /admin/law/{id}` | PATCH | Modifier une loi |
| `DELETE /admin/law/{id}` | DELETE | Supprimer une loi |
| `POST /admin/vote` | POST | Créer une position de vote |
| `PATCH /admin/vote/{id}` | PATCH | Modifier un vote |
| `DELETE /admin/vote/{id}` | DELETE | Supprimer un vote |
| `POST /admin/institution` | POST | Créer une institution |
| `PATCH /admin/institution/{id}` | PATCH | Modifier une institution |
| `DELETE /admin/institution/{id}` | DELETE | Supprimer une institution |
| `POST /admin/institution_type` | POST | Créer un type d'institution |
| `PATCH /admin/institution_type/{id}` | PATCH | Modifier un type |
| `DELETE /admin/institution_type/{id}` | DELETE | Supprimer un type |
| `POST /admin/power` | POST | Créer un pouvoir |
| `PATCH /admin/power/{id}` | PATCH | Modifier un pouvoir |
| `DELETE /admin/power/{id}` | DELETE | Supprimer un pouvoir |
| `POST /admin/country` | POST | Créer un pays |
| `PATCH /admin/country/{id}` | PATCH | Modifier un pays |
| `DELETE /admin/country/{id}` | DELETE | Supprimer un pays |
| `POST /admin/user_data/professional` | POST | Créer un statut professionnel |
| `PATCH /admin/user_data/professional/{id}` | PATCH | Modifier un statut |
| `DELETE /admin/user_data/professional/{id}` | DELETE | Supprimer un statut |
| `POST /admin/user_data/social` | POST | Créer un statut social |
| `PATCH /admin/user_data/social/{id}` | PATCH | Modifier un statut |
| `DELETE /admin/user_data/social/{id}` | DELETE | Supprimer un statut |
| `POST /admin/user_data/gender` | POST | Créer une identité de genre |
| `PATCH /admin/user_data/gender/{id}` | PATCH | Modifier une identité |
| `DELETE /admin/user_data/gender/{id}` | DELETE | Supprimer une identité |

### 2.10 🤖 Scraper automatique de lois

> [!IMPORTANT]
> Le scraper tourne en **tâche de fond async** au lancement du serveur, toutes les **6 heures**.

**Source 1 : nosdeputes.fr (API JSON)**
- URL : `https://www.nosdeputes.fr/16/scrutins/json`
- Filtre : scrutins sur "l'ensemble du projet de loi" ou "l'ensemble de la proposition de loi"
- Extraction : titre nettoyé (regex), numéro de scrutin, date, nombre de votants, pour/contre
- Catégorisation automatique : par mots-clés (Justice, Écologie, Économie, Législation)
- Déduplication : par `scrutin_id`

**Source 2 : vie-publique.fr (flux RSS XML)**
- URL : `https://www.vie-publique.fr/lois-feeds.xml`
- Filtre : éléments contenant "projet de loi" ou "proposition de loi"
- ID déterministe : hash SHA-256 du lien source
- Catégorisation automatique par mots-clés
- Nettoyage HTML des descriptions

### 2.11 🌐 CORS & Middleware

- **CORS** : `allow_origins=["*"]`, toutes méthodes et headers autorisés
- **Session Middleware** : pour le flow OAuth Google (Starlette `SessionMiddleware`)
- **Health check** : `GET /health` → `{"status": "healthy"}`

### 2.12 📖 Documentation API

- **Swagger UI** auto-générée : `http://localhost:8000/docs`
- Tags organisés : OAuth, User, Law, Vote, Institution, Country, UserData Content, Admin

---

## 🗃️ 3. Base de données — Infrastructure

### 3.1 Configuration
- **SGBD** : PostgreSQL 17 Alpine
- **Port** : 5432
- **Persistence** : Volume Docker (./docker/postgres_data)
- **Connexion** : `postgresql+psycopg2://` via pydantic-settings

### 3.2 Migrations Alembic
9 migrations versionnées :
1. `2fe988ec8e4f` — Migration initiale
2. `567e91a6cf48` — Ajout `created_at` à User
3. `55c1c776a374` — Tables Country et Institution
4. `3c856eb39c05` — Tables UserData (ProfessionalStatus, SocialStatus, GenderIdentities)
5. `e68dac8d0026` — Ajout `phone_number` à UserData
6. `b22edfd6f5ba` — Tables Political (PoliticalFigure, PoliticalRole, PoliticalParty, etc.)
7. `cf648fe60467` — Tables Law et système de vote (Law, Vote, VoteResult, UserVote, PartyVote)
8. `1f726fc15d84` — Ajout `vote_date`, `scrutin_id`, `category` à Law
9. `234647c8e9eb` — Merge de branches

### 3.3 Seed Data
**[seed_data.py](file:///home/max/Edupo/backend/seed_data.py)** — Peuple les statuts professionnels (28) et identités de genre (13)

**[seed_real_laws.py](file:///home/max/Edupo/backend/seed_real_laws.py)** — Peuple 20 lois réelles :
- **10 lois déjà votées** : Majorité numérique, Permis de conduire, Repas 1€, Pouvoir d'achat, Harcèlement scolaire, Climat, IVG Constitution, Puffs, Influenceurs, Immigration
- **10 lois à venir** : Fin de vie, SNU, Cannabis, 4 jours, Transports -26 ans, IA Act, Droit à l'erreur étudiant, Congé menstruel, Revenu universel jeune, Fast-fashion

---

## 📱 4. Application Mobile (Flutter)

### 4.1 Navigation & Structure

- **Bottom Navigation Bar** custom avec 3 onglets :
  1. 🏠 **Accueil** — Liste des lois
  2. 📄 **Programmes** — Programmes politiques
  3. 🏛️ **Structure** — Organisation institutionnelle (placeholder "Bientôt disponible")
- **Animations de transition** : slide horizontal entre onglets
- **Thème** : couleurs République française (bleu, blanc, rouge)
- **Status bar** transparente pour header immersif

### 4.2 Écran d'accueil (HomeScreen)

- **Hero Header** avec logo Édupo (gradient bleu)
- **Bouton profil** en haut à droite :
  - Si connecté → navigue vers le profil
  - Si déconnecté → popup menu (Se connecter / Créer un compte)
- **Toggle Tabs** : "À venir" / "Déjà votées"
- **Liste de lois** chargée depuis l'API backend (`GET /law`)
- **Algorithme de scoring** : tri des lois par pertinence pour les 12-30 ans
  - Mots-clés jeunesse (+3 pts) : "étudiant", "numérique", "climat", "emploi", "smic"…
  - Malus (-5 pts) : "ratification", "ordonnance", "approbation"…
  - Top 10 pour "À venir" (dans les 60 jours), Top 15 pour "Déjà votées"
- **Animations** : fade-in + translate-up au chargement des cards
- **Pull-to-refresh** : `BouncingScrollPhysics`

### 4.3 Law Cards (Widget)

- Design moderne avec coins arrondis et ombres
- **Badge d'urgence** coloré dynamiquement :
  - 🟢 Vert : loi clôturée
  - 🟠 Orange : ≤ 21 jours
  - 🔵 Bleu clair : 22-45 jours
  - 🔷 Bleu foncé : > 45 jours
- Labels temporels intelligents : "Aujourd'hui", "Dans X jours", "Dans X semaines"
- Affichage : titre, sous-titre, date, catégorie

### 4.4 Détail d'une loi (LawDetailScreen)

- Écran détaillé avec la description complète
- **Hémicycle interactif** ([HemicycleChart](file:///home/max/Edupo/mobile/lib/widgets/hemicycle_chart.dart#4-162)) affichant les résultats de vote de l'Assemblée nationale :
  - Récupération temps réel depuis **nosdeputes.fr Open Data** (directement depuis le mobile)
  - Visualisation en demi-cercle avec les sièges colorés par groupe politique
  - 12 rangées concentriques de sièges
  - Filtre interactif : Pour / Contre / Abstention
  - Couleurs par parti : RN (bleu marine), LFI (rouge), LR (bleu), RE (jaune), DEM (orange), SOC (rouge), HOR (bleu ciel), ECO (vert), GDR (bordeaux), LIOT (jaune)
- Statistiques de vote : total pour, contre, abstentions

### 4.5 Programmes politiques (ProgramsScreen)

- **Liste des 7 partis politiques français** avec données hardcodées ultra-détaillées :
  1. La France Insoumise (LFI)
  2. Parti Socialiste (PS)
  3. Europe Écologie Les Verts (EELV)
  4. Renaissance (RE)
  5. Les Républicains (LR)
  6. Rassemblement National (RN)
  7. Reconquête (R!)
  8. Parti Communiste Français (PCF)
- Pour chaque parti : nom, abréviation, leader, idéologie, positionnement, couleurs, icône, résumé

### 4.6 Détail d'un programme (ProgramDetailScreen)

- **Points de programme** (5-6 par parti) avec :
  - Titre + description courte
  - `detailedContent` : article complet de plusieurs paragraphes (contenu éducatif détaillé avec chiffres, contexte historique, comparaisons internationales)
- **Questions critiques** (3-5 par parti) avec :
  - Question posée
  - Analyse courte
  - `detailedAnalysis` : réponse approfondie de plusieurs paragraphes
  - Catégorie : `economic`, [social](file:///home/max/Edupo/backend/app/modules/user_data/router.py#97-100), `impact`

### 4.7 Lecteur de texte (TextReaderScreen)

- Écran plein écran pour lire un article détaillé
- Texte avec mise en forme

### 4.8 Authentification Mobile

#### Login (LoginScreen)
- Formulaire email + mot de passe
- Appel API `POST /login`
- Stockage sécurisé du JWT via `flutter_secure_storage`
- Gestion d'erreurs (credentials invalides, erreur réseau)

#### Inscription (RegisterScreen)
- Formulaire username + email + mot de passe
- Appel API `POST /register`
- Stockage sécurisé du JWT
- Gestion des conflits email

### 4.9 Profil utilisateur (ProfileScreen)

- Affichage des infos : username, email, rôle, date de création
- Gestion des données personnelles :
  - Âge
  - Numéro de téléphone
  - Genre (dropdown chargé depuis l'API)
  - Profession (dropdown chargé depuis l'API)
- Création et mise à jour des données (POST/PATCH `/me/data`)
- Bouton de déconnexion (suppression du token)

### 4.10 Administration mobile (AdminUsersScreen)

- **Uniquement visible pour les admins**
- Liste de tous les utilisateurs avec :
  - Username, email, rôle
  - Âge, genre, profession
  - Date de création

### 4.11 Services & Configuration réseau

- **ApiConfig** : détection automatique de la plateforme
  - Web → `http://127.0.0.1:8000`
  - Émulateur Android → `http://10.0.2.2:8000`
  - iOS / Linux / Desktop → `http://127.0.0.1:8000`
- **AuthService** : stockage sécurisé du token JWT (FlutterSecureStorage)
- **ApiService** : 12 méthodes API (register, login, getMe, getUserData, createUserData, updateUserData, getProfessionalStatuses, getGenders, getAllUsers, getAssemblyVotes, getAllLaws)
- **HttpClient** : client HTTP abstrait

### 4.12 Thème & Design

- Palette "République française" :
  - `frBlue` : bleu officiel
  - `frRed` : rouge officiel
  - Couleurs d'accent : vert, orange, bleu clair
- Typographie cohérente
- Coins arrondis (12-28px)
- Glassmorphism subtil
- Ombres portées douces

---

## 🌐 5. Frontend Web (Next.js 15)

### 5.1 Pages

| Route | Description |
|---|---|
| `/` | Page d'accueil |
| `/login` | Page de connexion (formulaire email/password avec CSS modules) |
| `/register` | Page d'inscription (formulaire username/email/password) |
| `/dashboard` | Tableau de bord (placeholder) |
| `/laws/[id]` | Détail d'une loi (page dynamique) |
| `/projects` | Liste de projets/lois (données statiques Next.js) |
| `/projects/[id]` | Détail d'un projet |

### 5.2 Composants

- **Header** ([layout/header.tsx](file:///home/max/Edupo/front/src/components/layout/header.tsx)) : barre de navigation avec liens
- **LawCard** ([LawCard.tsx](file:///home/max/Edupo/front/src/components/LawCard.tsx)) : carte affichant une loi avec catégorie, résumé et lien
- **Layout** ([layout.tsx](file:///home/max/Edupo/front/src/app/layout.tsx)) : structure globale HTML avec metadata

### 5.3 Services & Libs

- **ProjectsServices** : service pour les projets/lois
- **laws.ts** : 4 lois françaises hardcodées (programmation militaire, industrie verte, plein emploi, immigration)
- **types/index.ts** : interface TypeScript [Law](file:///home/max/Edupo/backend/app/modules/law/model.py#8-24)

### 5.4 Styles

- **globals.css** : styles globaux
- **CSS Modules** : styles scopés par composant (LawCard, Login, Register, Page)
- **Tailwind CSS 4** : utilitaires CSS
- **PostCSS** configuré

---

## 🐳 6. Infrastructure & DevOps

### 6.1 Docker Compose
```yaml
services:
  db:         # PostgreSQL 17 Alpine, port 5432, volume persistant
  backend:    # FastAPI (Dockerfile), port 8000, hot-reload, depends_on: db
```

### 6.2 Dockerfile Backend
- Base : `python:3.11-slim`
- Installation des dépendances via [requirements.txt](file:///home/max/Edupo/backend/requirements.txt)
- Commande : `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`

### 6.3 Variables d'environnement
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_SERVER`, `POSTGRES_PORT`, `POSTGRES_DB`
- `SECRET_KEY`, `ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REDIRECT_URI`
- `MIDDLEWARE_SECRET_KEY`

---

## 🧪 7. Tests

### 7.1 Tests d'intégration (12 fichiers)

| Fichier | Couverture |
|---|---|
| [test_auth.py](file:///home/max/Edupo/backend/tests/integration/test_auth.py) | Register + Login |
| [test_user.py](file:///home/max/Edupo/backend/tests/integration/test_user.py) | CRUD utilisateur |
| [test_user_data.py](file:///home/max/Edupo/backend/tests/integration/test_user_data.py) | Données personnelles |
| [test_country.py](file:///home/max/Edupo/backend/tests/integration/test_country.py) | CRUD pays |
| [test_institution.py](file:///home/max/Edupo/backend/tests/integration/test_institution.py) | CRUD institutions |
| [test_institution_type.py](file:///home/max/Edupo/backend/tests/integration/test_institution_type.py) | Types d'institution |
| [test_power.py](file:///home/max/Edupo/backend/tests/integration/test_power.py) | Pouvoirs |
| [test_law.py](file:///home/max/Edupo/backend/tests/integration/test_law.py) | CRUD lois |
| [test_vote.py](file:///home/max/Edupo/backend/tests/integration/test_vote.py) | CRUD votes |
| [test_professional_status.py](file:///home/max/Edupo/backend/tests/integration/test_professional_status.py) | Statuts professionnels |
| [test_social_status.py](file:///home/max/Edupo/backend/tests/integration/test_social_status.py) | Statuts sociaux |
| [test_gender_identity.py](file:///home/max/Edupo/backend/tests/integration/test_gender_identity.py) | Identités de genre |

### 7.2 Tests unitaires

| Fichier | Couverture |
|---|---|
| [test_country_services.py](file:///home/max/Edupo/backend/tests/unit/test_country_services.py) | Services métier Country |

### 7.3 Configuration tests
- [conftest.py](file:///home/max/Edupo/backend/tests/conftest.py) : fixtures partagées (DB test, client FastAPI)
- [pytest.ini](file:///home/max/Edupo/backend/pytest.ini) : configuration pytest
- [.coveragerc](file:///home/max/Edupo/backend/.coveragerc) : couverture de code
- [docker-compose.test.yml](file:///home/max/Edupo/backend/docker-compose.test.yml) : environnement PostgreSQL pour les tests
- [tests.sh](file:///home/max/Edupo/backend/tests.sh) + [clean.sh](file:///home/max/Edupo/backend/clean.sh) : scripts de lancement/nettoyage

---

## 📚 8. Documentation

| Fichier/Dossier | Contenu |
|---|---|
| [docs/README.md](file:///home/max/Edupo/docs/README.md) | Index de la documentation technique |
| [docs/dossier_projet.md](file:///home/max/Edupo/docs/dossier_projet.md) | Dossier projet complet (~20k caractères) |
| `docs/backend/` | Documentation backend |
| `docs/frontend/` | Documentation frontend |
| `docs/decisions/` | ADR (Architecture Decision Records) |
| `docs/infrastructure/` | Documentation infra |

---

## 🔢 Résumé chiffré

| Métrique | Valeur |
|---|---|
| **Tables DB** | 21 tables |
| **Endpoints API** | ~50+ routes |
| **Modules backend** | 9 modules métier |
| **Écrans mobile** | 9 écrans |
| **Partis politiques** | 8 partis détaillés (166k+ de contenu) |
| **Lois seed** | 20 lois réelles (10 passées + 10 futures) |
| **Tests** | 13 fichiers de tests |
| **Migrations** | 9 migrations Alembic |
| **Dépendances backend** | 44 packages Python |
| **Dépendances mobile** | 3 packages Dart principaux |
