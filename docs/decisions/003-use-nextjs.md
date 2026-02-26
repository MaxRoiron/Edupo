# ADR 003 — Utilisation de Next.js pour le frontend web

## Contexte
Le projet Édupo inclut un frontend web qui doit:
- Offrir une expérience rapide et fluide pour les utilisateurs
- Être maintenable et scalable
- Supporter des fonctionnalités modernes (auth, previews, middleware)
- S'intégrer facilement avec le backend FastAPI
- Permettre l'utilsation de TypeScript
- Réduire l'exposition des clés API et protéger la logique serveur

Plusieurs options ont été envisagées:
- React pur
- Vue.js
- Next.js

## Décision
Nous avons choisi d'utiliser **Next.js** comme framework frontend web.

## Justification
Next.js a été retenu pour les raisons suivantes:
- Performence optimisée par défaut
- HTML pré-rendu côté serveur (SSR) pour un chargement initial plus rapide
- Basé sur React, ce qui permet d'utiliser l'écosystème React existant
- Compatible avec toutes les librairies React
- Support natif de TypeScript
- CI/CD simplifié avec preview automatique
- Support des Edge Fuctions
- Sécurité renforcée (Server Components réduisent l'exposition des clés API)
- Header configurables et middleware pour authentification et protection
- Très scalable pour une évolution future
- Possibilité de ne pas exposer toute la logique au client

## Conséquences

### Positives
- Chargement initial rapide
- Sécurité accrue
- Maintenabilité simplifiée grâce à TypeScript et React
- Intégration facile pour le backend
- Architecture modulaire et scalable
- Développement rapide avec preview et middleware

## Négatives
- Corbe d'apprentissage pour les développeurs React débutants
- Certaines fonctionnalitées avancées nécessitent la compréhention du SSR / SSG / ISR
- Taille du bundle côté client parfois plus importante

## Alternatives considérées

### React pur
Permet une flexibilité totale mais nécessite beaucoup de configurations pour SSR, sécurité et CI/CD

### Vue.js
Solution viable, mais moins adaptée à l'écosystème React déjà utilisé dans le projet.

## Conclusion
Next.js représente le meilleur compromis entre performence, sécurité, maintenabilité et scalabilité pour le frontend web du projet Édupo.