# 🗄️ Gestion des Migrations avec Alembic

Ce projet utilise **Alembic** pour gérer les évolutions de la base de données PostgreSQL. Contrairement à une création automatique brute, Alembic permet de modifier la structure de la base sans perdre les données existantes.

## 🚀 Workflow Rapide (Usage Quotidien)

Dès que vous modifiez un fichier `model.py` dans vos modules :

### 1. Générer une nouvelle migration
Depuis le dossier `backend/`, lancez la commande suivante :
```bash
python -m alembic revision --autogenerate -m "description de mon changement"
```
*Ceci va créer un nouveau script dans `migrations/versions/`.*

### 2. Appliquer les changements
Pour mettre à jour votre base de données locale (ou en production) :
```bash
python -m alembic upgrade head
```

---

## 🧐 Comprendre le fonctionnement

### Pourquoi Alembic ?
- **Historique** : Chaque changement est stocké dans Git.
- **Sécurité** : On ne supprime pas la base pour la recréer, on l'adapte.
- **Production** : On peut déployer des changements de schéma en toute confiance.

### Configuration du projet
- **Fichier `alembic.ini`** : Contient les réglages de base.
- **Fichier `migrations/env.py`** : C'est le cerveau de la migration. Il a été configuré pour :
    - Charger l'URL de la base de données directement depuis le fichier `.env`.
    - Détecter automatiquement les modèles **SQLModel** définis dans les modules.

---

## 🛠️ Commandes Utiles

| Commande | Description |
| :--- | :--- |
| `alembic history` | Affiche la liste chronologique des migrations. |
| `alembic current` | Affiche la version actuelle de votre base de données. |
| `alembic upgrade +1` | Applique uniquement la migration suivante. |
| `alembic downgrade -1` | Annule la dernière migration appliquée (Attention !). |

---

## ⚠️ Bonnes Pratiques & Erreurs Courantes

### 🔍 Relire les scripts générés
Alembic est puissant mais automatique. Avant de faire un `upgrade head`, ouvrez toujours le fichier généré dans `migrations/versions/` pour vérifier qu'il ne va pas supprimer une colonne par erreur (ex: si vous avez renommé un champ).

### ❌ Erreur : "Can't locate revision identified by 'xxxx'"
Cette erreur arrive si votre base de données croit être sur une version dont le fichier n'existe plus sur votre PC (souvent après un merge Git ou une suppression manuelle).
**Solution brute :** Supprimez la table `alembic_version` dans votre DB et relancez une migration initiale.
```bash
# Commande pour réinitialiser l'historique dans Docker :
docker compose exec db psql -U superadmin -d edupo_db -c "DROP TABLE IF EXISTS alembic_version CASCADE;"
```

### 🔄 Que se passe-t-il si je renomme une colonne ?
**Attention !** Alembic `--autogenerate` ne détecte pas bien les renommages. Par défaut, il va :
1. **Supprimer** l'ancienne colonne (vous perdez vos données !).
2. **Créer** une nouvelle colonne vide.

**La méthode pro pour renommer :**
1. Générez la migration : `python -m alembic revision --autogenerate -m "rename col"`.
2. Ouvrez le fichier généré dans `migrations/versions/`.
3. Remplacez les lignes `op.drop_column` et `op.add_column` par une seule ligne :
   ```python
   op.alter_column('nom_table', 'ancien_nom', new_column_name='nouveau_nom')
   ```

### 📦 Ajout d'un nouveau module
Si vous créez un nouveau module (ex: `app/modules/courses`), n'oubliez pas d'importer son modèle dans `backend/migrations/env.py` pour qu'Alembic puisse le voir !
