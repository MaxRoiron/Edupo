import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Law {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String date;
  final DateTime voteDate;
  final String category;

  const Law({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.date,
    required this.voteDate,
    required this.category,
  });

  /// Nombre de jours restants avant le vote
  int get daysUntilVote {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final vote = DateTime(voteDate.year, voteDate.month, voteDate.day);
    return vote.difference(today).inDays;
  }

  /// Label lisible pour le nombre de jours restants
  String get urgencyLabel {
    final days = daysUntilVote;
    if (days <= 0) return 'Aujourd\'hui';
    if (days == 1) return 'Demain';
    if (days <= 7) return 'Dans $days jours';
    if (days <= 14) return 'Dans ~${(days / 7).round()} semaines';
    if (days <= 30) return 'Dans ~${(days / 7).round()} semaines';
    return 'Dans ~${(days / 30).round()} mois';
  }

  /// Couleur dynamique selon l'urgence du vote
  ///  - ≤ 7 jours  → rouge-orangé (urgent)
  ///  - 8–21 jours → orange (proche)
  ///  - 22–45 jours → bleu clair (modéré)
  ///  - > 45 jours → bleu foncé (lointain)
  Color get urgencyColor {
    final days = daysUntilVote;
    if (days <= 21) return AppColors.accentOrange;     // Orange
    if (days <= 45) return AppColors.accentBlue;       // Bleu clair
    return AppColors.frBlue;                           // Bleu République
  }
}

// Projets de loi à venir à l'Assemblée nationale
final List<Law> upcomingLaws = [
  Law(
    id: 'pjl-fin-de-vie',
    title: 'Projet de loi sur la fin de vie',
    subtitle: 'Légalisation de l\'aide à mourir sous conditions strictes pour les patients en phase terminale.',
    description:
        'Ce projet de loi vise à créer un nouveau droit : l\'aide à mourir pour les personnes majeures '
        'atteintes d\'une maladie grave et incurable, engageant leur pronostic vital à court ou moyen terme, '
        'et dont les souffrances sont réfractaires aux traitements.\n\n'
        'Le texte prévoit plusieurs conditions cumulatives :\n\n'
        '• Le patient doit être majeur, de nationalité française ou résidant de manière stable en France\n'
        '• Il doit être atteint d\'une affection grave et incurable\n'
        '• Il doit exprimer une demande libre, éclairée et réitérée\n'
        '• Deux médecins indépendants doivent valider la demande\n'
        '• Un délai de réflexion de 15 jours est imposé après l\'accord médical\n\n'
        'Le projet inclut également un renforcement significatif des soins palliatifs sur l\'ensemble du territoire, '
        'avec la création de maisons d\'accompagnement et l\'augmentation des financements dédiés.\n\n'
        'Les opposants au texte craignent une dérive vers l\'euthanasie, tandis que les partisans défendent '
        'le droit à mourir dans la dignité.',
    date: '14 Mars 2026',
    voteDate: DateTime(2026, 3, 14),
    category: 'Santé & Éthique',
  ),
  Law(
    id: 'pjl-reforme-audiovisuel',
    title: 'Réforme de l\'audiovisuel public',
    subtitle: 'Fusion de France Télévisions, Radio France et l\'INA en une holding unique « France Médias ».',
    description:
        'Le projet de loi prévoit la création d\'une société holding unique baptisée « France Médias » '
        'regroupant France Télévisions, Radio France et l\'Institut National de l\'Audiovisuel (INA).\n\n'
        'Les objectifs principaux :\n\n'
        '• Mutualiser les moyens techniques et les rédactions pour gagner en efficacité\n'
        '• Créer une plateforme numérique commune pour concurrencer les géants du streaming\n'
        '• Maintenir l\'indépendance éditoriale de chaque entité via des chartes déontologiques\n'
        '• Réduire les coûts de fonctionnement de 15 % sur 5 ans\n\n'
        'Le financement resterait public, avec une dotation budgétaire annuelle votée par le Parlement '
        'en remplacement de la contribution à l\'audiovisuel public supprimée en 2022.\n\n'
        'Les syndicats de journalistes expriment des inquiétudes sur les suppressions de postes '
        'et la concentration des rédactions.',
    date: '21 Mars 2026',
    voteDate: DateTime(2026, 3, 21),
    category: 'Culture & Médias',
  ),
  Law(
    id: 'pjl-logement-social',
    title: 'Accélération du logement social',
    subtitle: 'Obligation de 30% de logements sociaux dans les communes de plus de 3 500 habitants.',
    description:
        'Ce projet de loi renforce la loi SRU (Solidarité et Renouvellement Urbain) en augmentant '
        'les obligations de construction de logements sociaux pour les communes.\n\n'
        'Mesures principales :\n\n'
        '• Passage du seuil obligatoire de 25 % à 30 % de logements sociaux\n'
        '• Abaissement du seuil d\'application de 5 000 à 3 500 habitants\n'
        '• Quintuplement des amendes pour les communes récalcitrantes\n'
        '• Création d\'un « fonds national d\'accélération » doté de 2 milliards d\'euros\n'
        '• Simplification des permis de construire pour les bailleurs sociaux\n'
        '• Encadrement renforcé des loyers dans les zones tendues\n\n'
        'Les maires des petites communes s\'inquiètent de la faisabilité technique et financière '
        'de ces nouvelles obligations, tandis que les associations de mal-logés saluent une mesure '
        '«nécessaire mais insuffisante».',
    date: '2 Avril 2026',
    voteDate: DateTime(2026, 4, 2),
    category: 'Logement',
  ),
  Law(
    id: 'pjl-numerique-mineurs',
    title: 'Protection des mineurs en ligne',
    subtitle: 'Vérification d\'âge obligatoire et responsabilisation des plateformes pour les contenus exposés aux mineurs.',
    description:
        'Ce texte vise à renforcer drastiquement la protection des mineurs sur Internet, '
        'en imposant de nouvelles obligations aux plateformes numériques.\n\n'
        'Dispositions clés :\n\n'
        '• Vérification d\'âge obligatoire sur les réseaux sociaux et sites de contenus pour adultes\n'
        '• Interdiction des « dark patterns » ciblant les mineurs (notifications addictives, scroll infini)\n'
        '• Obligation pour les plateformes de détecter et supprimer les contenus de harcèlement en 24h\n'
        '• Création d\'un « droit à l\'oubli numérique » renforcé pour les mineurs\n'
        '• Amendes jusqu\'à 6 % du chiffre d\'affaires mondial en cas de manquement\n'
        '• Possibilité pour les parents de demander la suppression de tout compte de leur enfant\n\n'
        'Le débat porte sur l\'équilibre entre protection de l\'enfance et respect de la vie privée, '
        'notamment concernant les méthodes de vérification d\'âge qui pourraient impliquer '
        'la collecte de données sensibles.',
    date: '22 Avril 2026',
    voteDate: DateTime(2026, 4, 22),
    category: 'Numérique',
  ),
  Law(
    id: 'pjl-souverainete-alimentaire',
    title: 'Souveraineté alimentaire',
    subtitle: 'Garantir l\'autonomie agricole française face aux crises géopolitiques et climatiques.',
    description:
        'Le projet de loi sur la souveraineté alimentaire vise à renforcer la capacité de la France '
        'à nourrir sa population de manière autonome.\n\n'
        'Axes principaux :\n\n'
        '• Interdiction de la vente à perte de produits agricoles français\n'
        '• Création d\'un « bouclier foncier agricole » pour limiter l\'artificialisation des terres\n'
        '• Obligation de 60 % de produits locaux dans la restauration collective publique\n'
        '• Plan de transition pour réduire la dépendance aux engrais importés\n'
        '• Soutien financier à l\'installation de 20 000 nouveaux agriculteurs par an\n'
        '• Création de stocks stratégiques alimentaires nationaux\n\n'
        'Les syndicats agricoles majoritaires soutiennent ce texte, mais les associations '
        'environnementales regrettent l\'absence de mesures contraignantes sur les pesticides '
        'et le bien-être animal.',
    date: '6 Mai 2026',
    voteDate: DateTime(2026, 5, 6),
    category: 'Agriculture',
  ),
];
