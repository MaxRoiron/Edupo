class Law {
  final String id;
  final String title;
  final String summary;
  final String date;
  final String category;
  final String details;

  const Law({
    required this.id,
    required this.title,
    required this.summary,
    required this.date,
    required this.category,
    required this.details,
  });
}

// Sample data — mirrors the web front-end's laws.ts
const List<Law> sampleLaws = [
  Law(
    id: 'loi-programmation-militaire-2024-2030',
    title: 'Loi de programmation militaire 2024-2030',
    summary:
        'Définit les orientations et les moyens de la politique de défense pour les sept prochaines années, avec un budget en hausse significative.',
    date: '1er Août 2023',
    category: 'Défense',
    details:
        'Cette loi prévoit 413 milliards d\'euros de crédits pour les armées sur la période, afin de moderniser les équipements, renforcer la dissuasion nucléaire et adapter les forces aux nouvelles menaces (cyber, spatial, hybridité).',
  ),
  Law(
    id: 'loi-industrie-verte',
    title: 'Loi relative à l\'industrie verte',
    summary:
        'Vise à réindustrialiser la France tout en favorisant la transition écologique par des mesures fiscales et de simplification administrative.',
    date: '23 Octobre 2023',
    category: 'Économie & Écologie',
    details:
        'La loi crée un crédit d\'impôt "investissement industries vertes", accélère les implantations industrielles, et met en place un label "site clés en main France 2030".',
  ),
  Law(
    id: 'loi-plein-emploi',
    title: 'Loi pour le plein emploi',
    summary:
        'Transforme Pôle emploi en "France Travail" et réforme le RSA avec des droits et devoirs renforcés pour les allocataires.',
    date: '18 Décembre 2023',
    category: 'Travail & Social',
    details:
        'Création du réseau France Travail pour coordonner tous les acteurs de l\'emploi. Conditionnement du RSA à 15 heures d\'activité hebdomadaire d\'insertion.',
  ),
  Law(
    id: 'loi-immigration-integration',
    title: 'Loi pour contrôler l\'immigration, améliorer l\'intégration',
    summary:
        'Texte visant à mieux contrôler les flux migratoires et renforcer l\'intégration des étrangers en situation régulière.',
    date: '26 Janvier 2024',
    category: 'Intérieur',
    details:
        'Le texte durcit les conditions de regroupement familial, rétablit le délit de séjour irrégulier, et conditionne certaines prestations sociales.',
  ),
];
