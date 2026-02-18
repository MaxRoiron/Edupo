# ADR 004 — Utilisation de Flutter pour l'application mobile

## Context
Le projet Édupo inclut une application mobile qui doit:
- Être disponible sur Android et iOS
- Offrir une expérience fluide et moderne
- Maintenir une cohérence visuelle entre plateformes
- Permettre des interfaces personnalisées avancées
- Être maintenable sur le long terme

Plusieurs solutions ont été envisagées:
- Développement natif (Kotlin / Swift)
- React Native
- Flutter

## Décision
Nous avons choisi d'utiliser **Flutter** comme framework de développement mobile.

## Justification
Flutter a été retenu pour les raisons suivantes:
- Compilation en code natif ARM
- Utilisation du moteur graphique Sika
- Exellentes performences (60 à 120 FPS)
- Très performant pour les animations complexes
- Contrôle total du rendu UI
- Widgets riches et personnalisables
- Cohérence parfaite entre Android et iOS
- Très bonne documentation officielle
- Écosystème en forte croissance
- Nombreux packages officiels maintenus par Google
- Stabilité élevée
- Moins dépendant des versions Android / iOS
- Réduction des bugs liés aux mises à jour système

Flutter permet ainsi de garantir une expérience utilisateur fluide et cohérente tout en conservant une codebase unique.

## Conséquences

### Positives
- Un seul codebase pour Android et iOS
- Performance proche du natif
- Design entièrement personnalisable
- Moins de fragmentation entre plateformes
- Maintenance simplifiée

### Négatives
- Taille d'application plus importante
- Nécéssité d'apprendre Dart
- Moins d'accès direct aux APIs que le développement sur natif pur

## Alternatives considérées

### Développement natif (Kotlin / Swift)
Offre un contrôle maximal mais impose deux codebases distincts et une maintenance plus complexe.

### React Native
Solution viable, mais dépend davantage du bridage JavaScript et peut présenter des limitations de performences pour des interfaces graphiques complexes.

## Conclusion
Flutter représente le meilleur compromis entre performence, maintenabilité et cohérence multi-plateformes pour les besoins du projet.