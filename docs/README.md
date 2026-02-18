# 📚 Documentation Technique - Édupo

Bienvenue dans le centre de documentation technique du projet. Ce dossier regroupe tous les guides nécessaires pour comprendre, maintenir et faire évoluer les différents services d'Édupo.

---

## 🗺️ Organisation de la Doc

### 🔙 [Backend (API)](./backend/index.md)
*Tout ce qui concerne le serveur Python, la logique métier et la sécurité.*
- **[Guide Général](./backend/index.md)** : Architecture, services, routers et standards.
- **[Base de données](./backend/database.md)** : Gestion des migrations avec Alembic, schémas et scripts.

### 🎨 [Frontend (Web)](./frontend/index.md)
*Tout ce qui concerne l'interface utilisateur en Next.js.*
- **[Guide Frontend](./frontend/index.md)** : Structure `src/`, composants réutilisables et gestion d'état.

### 🏗️ Infrastructure & Dev
*Les outils transversaux et le déploiement.*
- **[Docker & Déploiement](./infrastructure/docker.md)** : Explication des `Dockerfile` et de la configuration Docker Compose.
- **[Standards de Code](./infrastructure/quality.md)** : (À venir) Linting, tests et CI/CD.

---

## 🛠️ Principes de Contribution

Pour maintenir une documentation utile et lisible :

1.  **Emplacement** : Ne créez pas de fichier à la racine de `docs/`. Utilisez les dossiers thématiques.
2.  **Mise à jour** : Si vous modifiez une fonctionnalité majeure (ex: ajout d'un module backend), mettez à jour l'index correspondant.
3.  **Liens** : Utilisez toujours des liens relatifs pour que la navigation fonctionne sur GitHub comme en local.
4.  **Format** : Utilisez des emojis pour rendre la lecture plus agréable et des blocs de code pour les commandes.

---

🏠 **[Retour vers le projet principal](../README.MD)**
