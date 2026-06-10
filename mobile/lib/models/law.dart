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

  factory Law.fromJson(Map<String, dynamic> json) {
    // Parse the datetime string from backend isoformat
    DateTime vDate = DateTime.now();
    if (json['vote_date'] != null) {
      vDate = DateTime.parse(json['vote_date']);
    }

    final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    
    return Law(
      id: json['scrutin_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? 'Loi sans titre',
      subtitle: json['subtitle'] ?? '',
      description: json['description'] ?? '',
      date: '${vDate.day} ${months[vDate.month - 1]} ${vDate.year}',
      voteDate: vDate,
      category: json['category'] ?? 'Général',
    );
  }

  /// Nombre de jours restants avant le vote
  int get daysUntilVote {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final vote = DateTime(voteDate.year, voteDate.month, voteDate.day);
    return vote.difference(today).inDays;
  }

  /// Label lisible pour le nombre de jours restants ou passés
  String get urgencyLabel {
    final days = daysUntilVote;
    if (days < 0) return 'Votée le ${voteDate.day}/${voteDate.month}/${voteDate.year}';
    if (days == 0) return 'Aujourd\'hui';
    if (days <= 7) return 'Dans $days jours';
    if (days <= 14) return 'Dans ${(days / 7).round()} semaines';
    if (days <= 30) return 'Dans ${(days / 7).round()} semaines';
    return 'Dans ${(days / 30).round()} mois';
  }

  /// Couleur dynamique selon l'urgence du vote
  ///  - ≤ 7 jours  → rouge-orangé (urgent)
  ///  - 8–21 jours → orange (proche)
  ///  - 22–45 jours → bleu clair (modéré)
  ///  - > 45 jours → bleu foncé (lointain)
  Color get urgencyColor {
    final days = daysUntilVote;
    if (days < 0) return AppColors.accentGreen;        // Vert pour les lois clôturées
    if (days <= 21) return AppColors.accentOrange;     // Orange
    if (days <= 45) return AppColors.accentBlue;       // Bleu clair
    return AppColors.frBlue;                           // Bleu République
  }
}

// Les listes ne sont plus statiques, 
// elles seront récupérées depuis l'API.
