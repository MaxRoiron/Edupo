# ADR 002 — Utilisation de PostgreSQL comme système de gestion de base de donnée

## Context
Le projet Édupo nécessite une base de donnée relationnelle permettant:
- La gestion structurée des utilisateurs et de leurs données
- La cohérence et l'intégrité des relations (clé étrangères)
- Une bonne compatibilité avec SQLAlchemy
- Une solution adaptée à un environnement Dockerisé
- Une solution viable pour un déploiement en production

Plusieurs options ont été considérés:
- SQLite
- MySQL
- PostgreSQL

## Décision
Nous avons choisi d'utiliser **PostgreSQL** comment système de gestion de base de donnée principale.

## Justification
PostgreSQL à été retenu pour les raisons suivantes:
- Base de donnée relationnelle robuste et éprouvé
- Exellente gestion des contraintes et de l'intégrité référentielle
- Compatibilité complète avec SQLAlchemy et Alembic
- Support avancé des types de données
- Très bonne intégration avec Docker

## Conséquences

### Positives
- Fiabilité et stabilité élevées
- Meilleur gestion des relations complexes
- Scalabilité pour une évolution future du projet
- Environnement proche des standards industriels

### Négatives
- Configuration plus complexe que SQLite
- Nécessite un service séparé (conteneur Docker)
- Consommation de ressources supérieure à SQLite

## Alternatives considérées

### SQLite
Simple, rapide à mettre en place, mais non adaptée à un environnement multi-utilisateurs ou production.

### MySQL
Salution viable, mais PostgreSQL offre une meilleure conformité SQL et des fonctionnalités plus avancées.

## Conclusion
PosgreSQL représente un choix cohérent pour un projet structuré, évolutif et destiné à être maintenu sur le long terme.