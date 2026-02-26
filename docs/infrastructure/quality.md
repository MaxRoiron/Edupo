# 💎 Qualité du Code & Standards

La qualité du code est primordiale pour maintenir Édupo sur le long terme. Ce document définit les outils et les règles à suivre.

---

## 🐍 Standards Python (Backend)

### 1. Style de code
- Nous suivons la **PEP 8**.
- **Indentation** : 4 espaces.
- **Type Hinting** : Obligatoire pour tous les nouveaux services et modèles (`def func(name: str) -> None`).

### 2. Organisation des modules
Chaque module dans `app/modules/` doit suivre la structure :
- `model.py` : Schéma de base de données.
- `shemas.py` : Schémas Pydantic (Input/Output).
- `services.py` : Logique métier (CRUD).
- `router.py` : Routes FastAPI.

### 3. Nettoyage
Le script `backend/clean.sh` doit être utilisé régulièrement pour supprimer les fichiers temporaires et les caches Python (`__pycache__`).
```bash
cd backend
./clean.sh
```

---

## 🎨 Standards Frontend (Next.js)

### 1. Composants
- Utilisez des **Functional Components** avec TypeScript.
- Les composants réutilisables vont dans `src/components/`.
- Utilisez **Tailwind CSS** pour le styling.

### 2. TypeScript
- Évitez l'usage du type `any`. Créez des `interface` ou des `type` pour chaque objet complexe.

---

## 🧪 Stratégie de Tests (À venir)

Le projet prévoit d'intégrer :
- **Backend** : `pytest` pour les tests unitaires et d'intégration.
- **Frontend** : `Jest` ou `Vitest` pour les composants.

---

## 🛠️ Outils de Qualité recommandés

Pour une meilleure expérience, il est conseillé d'utiliser les extensions suivantes dans votre IDE (VS Code) :
- **Prettier** : Formatage automatique (JS/TS/CSS).
- **Ruff** ou **Black** : Formatage automatique (Python).
- **Pylance** : Analyse statique Python.
- **ESLint** : Analyse statique JS/TS.

---

## 🏁 Définition du "Done" (DoD)
Une fonctionnalité est considérée comme terminée si :
1. Le code respecte les standards de style.
2. La documentation (`docs/`) a été mise à jour si nécessaire.
3. Aucune erreur de type (TS ou Python) n'est présente.
4. Les migrations Alembic ont été générées et testées.
