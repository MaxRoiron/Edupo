# ADR 001 — Utilisation de FastAPI comme framework backend

## Context
Le projet nécessite un backend moderne permettant:
- La création d'une API REST claire et maintenable
- Une documentation automatique pour faciliter le développement frontednd
- De bonnes performences
- Une architecture facilement extensible
- Une bonne intégration avec PostgreSQL et Docker

Plusieurs frameworks Python étaient envisageables:
- Flask
- Django
- FastAPI

## Décision
Nous avons choisi d'utiliser **FastAPI** comme framework backend principal.

## Justification
FastAPI à été retenue pour les raisons suivantes:
- Génération automatique de documentation OpenAPI (Swagger / Redoc)
- Typage fort via Pydentic
- Support natif de l'asynchrone (ASGI)
- Performence élevée comparé à Flask ou Django
- Structure simple et flexible adaptée à un projet évolutif

## Conséquences

### Positives
- Documentation intéractive accessible immédiatement
- Meilleure maintenabilité grâce au typage
- Bonnes performences
- Intégration naturelle avec SQLAlchemy et Alembic

### Négatives
- Dépendance forte à Pydentic
- Complexité liée à l'async ppour certains développeurs
- Moins de batteries incluses que Django

## Alternatives considérées

### Flask
Plus simple mais nécessite plus de configuration pour atteingre le même niveau de structure.

### Django
Très complet mais trop lourd pour une API REST principalement rientée service.

## Conclusion
FastAPI représente le meilleur compromis entre performence, simplicité et évolutivité pour les besoins actuels et futurs du projet.