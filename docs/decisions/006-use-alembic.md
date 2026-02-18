# ADR 006 — Utilisation d'alembic pour la gestion des migrations

## Context
Le projet Édupo utilise:
- PostgreSQL comme base de donnée
- SQLAlchemy comme ORM côté backend FastAPI

Nous avons besoin:
- De gérer l'évolution du shéma de base de données
- De créer et de versionner des migrations facilement
- D'assurer la cohérence entre environnement (dev, staging, prod)
- De minimiser les erreurs lors de déploiement de nouvelles versions

Plusieurs solutions ont été envisagées:
- Gestion manuelle des migrations SQL
- Utilisation d'outils intégrés à PostgreSQL
- Utilisation d'Alembic

## Décision
Nous avons choisi d'utiliser **Alembic** comme outil de migration pour SQLAlchemy

## Justification
Alembic a été retenu pour les raisons suivantes:
- Intégration native avec SQLAlchemy
- Génération automatique des migrations (`--autogenerate`)
- Versionnement clair des migrations
- Compatibilité multi-environnements (dev, staging, prod)
- Facilité de rollback si besoin
- Documentation officielle complète
- Large adoption dans la communauté Python

## Conséquences

### Positives
- Migrations versionnées et reproductibles
- Réduction des erreurs humaines
- Maintenance simplifiée du shéma DB
- Intégration facile dans CI/CD

### Négatives
- Courbe d'apprentissage pour les développeurs débutants
- Nécessité de maintenir des scripts de migration
- Dépendance suppléménetaire dans le projet

## Alternatives considérées

### Gestion manuelle des migrations
Simple pour un projet très petit, mais source d'erreurs et non scalable.

### Outils PostgreSQL natif (pg_dump / scripts SQL)
Moins intégré à l'ORM et moins pratique pour le développement agile.

## Conclusion
Alembic représente le choix le plus adapté pour un projet FastAPI avec SQLAlchemy, garantissant cohérence, maintenabilité et évolutivité du shéma de base de données.