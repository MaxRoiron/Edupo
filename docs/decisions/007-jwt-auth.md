# ADR 007 — Utilisation de JWT pour l'authentification

## Context
Le projet Édupo comprend plusieurs clients:
- Frontend web (Next.js)
- Application mobile

Nous avons besoin d'un mécanisme d'authentification qui soit:
- Compatible avec plusieurs clients
- Sécurisé
- Facile à intégrer avec FastAPI
- Facile à maintenir et à scaler
- Capable de gérer des sessions sans serveur (stateless)
- Compatible avec l'authentification tierce (ex: Google OAuth)

Plusieurs solutions ont été envisagées:
- Sessions côté serveur avec cookies
- OAuth complet (Google, Facebook, etc.)
- JTW interne

## Décision
Nous avons choisi d'utiliser **JWT** comme mécanisme principal pour gérer l'authentification et l'autorisation.

Le projet supporte **deux méthodes d'authentification**:
1. **Compte Édupo natif** (mail + mot de passe)
2. **Google OAuth**

Dans les deux cas, **un compte utilisateur est créé ou lié dans notre base**.
Le backend délivre ensuite **un JWT interne**, utilisé pour toutes les requêtes API, garantissant:
- Cohérence des permissions
- Architecture stateless
- Compatibilité multi-clients (web et mobile)

### Flux multi-authentification
- **Connexion compte natif**: validation du mot de passe -> JWT interne généré
- **Connexion Google Oauth**: vérification du token Google -> création automatique d'un compte si inexistant -> JWT interne généré

## Justification
- Compatibilité multi-clients (Next.js et Flutter)
- Stateless -> backend scalable
- Intégration facile avec FastAPI et Pydentic
- Standard largement adopté et documenté
- Gestion des rôles et permissions via claim JWT
- Permet d'ajouter facilement d'autres fournisseurs OAuth à l'avenir
- Maintien d'un contrôle uniforme sur tous les utilisateurs

## Conséquences

### Positives
- Authentification unifiée pour tous les clients
- Backend stateless -> facile à scaler
- Support multi-auth (Édupo + Google)
- Gestion flexible des rôles et permissions
- Standardisé et bien documenté

### Négatives
- Nécessité d'implémenter et sécuriser les refresh token
- Les tokens exposés peuvent être utilisés jusqu'à expiration si compromis
- Vérification correcte des identités tierces nécessaire

## Alternatives considérées

### Session côté serveur
- Simple à mettre en place
- Moins adapté pour Flutter et API multi-clients
- Nécessite stockage centralisé pour le scaling

### OAuth complet sans JWT interne
- Très sécurisé et standard
- Complexité élevée
- Nécessite d'adapter tout le backend pour le stockage des sessions externes

## Conclusion
L'utilisation d'un **JWT interne** pour tous les utilisateurs, même ceux s'authentifiant via Google OAuth, garantit:
- Un contrôle uniforme sur les permissions et la sécurité
- Une architecture stateless et scalable
- Une compatibilité optimale avec tous les clients (web et mobile)
- La possibilité d'ajouter de futurs fournisseurs OAuth sans refactorisation majeure