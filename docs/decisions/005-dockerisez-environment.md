# ADR 005 — Architecture Dockerisée du projet

## Context
Le projet Édupo comprend:
- Un backend FastAPI
- Une base de donnée PostgreSQL
- Un frontend web (Next.js)
- Une partie mobile développée en Flutter

Le backend doit être accessible à la fois:
- Par le frontend web
- Par l'aplication mobile

Nous avons besoin:
- D'un environnement de développement reproductible
- D'une API accessible de manière cohérente pour plusieurs clients
- D'éviter les problèmes de dépendances locales
- De simplifier le déploiement

Plusieurs approches étaient possibles:
- Installation locale manuelle (Python, Node, PostgreSQL)
- Utilisation partielle de Docker (uniquement la base de donnée)
- Dockerisation complète du projet

## Décision
Nous avons choisi de dockeriser entièrement l'envirnnement serveur (backend + base de données).

Le frontend web peur être éxécuté localement ou intégré à l'environnement Docker.
L'aplication Flutter consomme l'API exposé sur le backend.

L'orchestration est gérée via `docker-compose`.

## Justification
Docker permet:
- Un environnement isolé et reproductible
- Une gestion simplifiée des dépendances
- Une configuration claire des services (backend, db)
- Une protabilité facilitée vers d'autres machines ou serveurs
- Une cohérence entre environnement de développement et production

L'utilisation de `docker-compose` permet de définir l'architecture dans un fichier unique et versionné.

## Conséquences

### Positives
- Supprssion des conflits d'environnement
- Installation simplifiée pour les nouveaux dévelopeurs
- Déploiement facilité
- Acrchitecture claire et modulaire

### Négatives
- Complexité supplémentaire au démarrage
Consommation de ressources plus élevée
- Courbe d'apprentissage initiale

## Alternatives considérées

### Installation manuelle
Siple à court terme, mais source fréquente d'erreurs de configuration et de divergences entre développeurs.

### Docker partiel (uniquement la base de donnée)
Réduit partiellement les problèmes, mais ne garantit pas une homogénéité complète de l'environnement

## Conclusion
La dockerisation complète assure la stabilité, la portabilité et la maintenabilité du projet sur le long terme.