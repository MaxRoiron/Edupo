# 🎓 Édupo

Édupo est une plateforme moderne dédiée à l'apprentissage, combinant un backend performant en FastAPI et un frontend réactif en Next.js.

## 🏗️ Architecture du Projet

Le projet est structuré pour séparer clairement les responsabilités :
- **`backend/`** : API REST, Logique métier, Base de données (PostgreSQL, SQLModel).
- **`mobile/`** : Application Flutter, lois, programmes et avis citoyens.
- **`front/`** : Interface utilisateur (Next.js 16, TypeScript, Tailwind).
- **`docs/`** : Documentation technique complète et guides de développement.

---

## 🚀 Démarrage Rapide

La méthode la plus simple pour lancer tout l'écosystème est d'utiliser Docker.

### 1. Prérequis
- [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/) installés.
- Un fichier `.env` configuré dans le dossier `backend/`.

### 2. Lancement
Depuis la racine du projet, exécutez :
```bash
docker compose up -d --build
```
- Docker lance PostgreSQL et l’API ; les migrations sont appliquées avant le démarrage.
- Pour le **Frontend**, lancez `npm install` puis `npm run dev` depuis `front/` : [http://localhost:3000](http://localhost:3000)
- Le **Backend** (API) sera accessible sur : [http://localhost:8000](http://localhost:8000)
- La **Documentation API (Swagger)** : [http://localhost:8000/docs](http://localhost:8000/docs)

---

## 📚 Documentation

Pour plus de détails sur le développement, les standards de code et la maintenance, consultez notre centre de documentation :

👉 **[Voir la documentation technique (docs/)](./docs/README.md)**

- [Collecte des lois, statuts, questions et API](./docs/backend/lois.md)
- [Rapport détaillé des corrections du 6 octobre 2026](./docs/backend/rapport_corrections_lois.md)
- [Optimisation du chargement et du défilement du 14 octobre 2026](./docs/backend/rapport_optimisation_lois.md)

---

## 🛠️ Stack Technique

| Backend (API) | Frontend (Client) | Infra & Outils |
| :--- | :--- | :--- |
| **FastAPI** | **Next.js 16 (App Router)** | **Docker** |
| **SQLModel / SQLAlchemy** | **TypeScript** | **Alembic** (Migrations) |
| **PostgreSQL 17** | **Tailwind CSS** | **Pytest** |
| **JWT / OAuth2** | **Lucide Icons** | **Uvicorn** |

---

## 🌳 Flux de Développement (Git)
Nous suivons une hiérarchie de branches simple :
- `main` : Version stable de production.
- `dev` : Branche d'intégration pour les nouvelles fonctionnalités.
- `front` / `back` : Branches thématiques pour les développements spécifiques.
