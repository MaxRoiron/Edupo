import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Stable database identity, official vote identity and status are independent.
class Law {
  final String id;
  final String? scrutinId;
  final String title;
  final String officialTitle;
  final String description;
  final DateTime? voteDate;
  final DateTime? publishedAt;
  final String category;
  final String status;
  final String? sourceUrl;
  final String? descriptionSourceUrl;

  const Law({
    required this.id,
    this.scrutinId,
    required this.title,
    this.officialTitle = '',
    required this.description,
    this.voteDate,
    this.publishedAt,
    required this.category,
    this.status = 'unknown',
    this.sourceUrl,
    this.descriptionSourceUrl,
  });

  factory Law.fromJson(Map<String, dynamic> json) => Law(
    id: json['id'].toString(),
    scrutinId: json['scrutin_id'] as String?,
    title: json['title'] as String? ?? 'Êtes-vous favorable à ce texte ?',
    officialTitle: json['official_title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    voteDate: DateTime.tryParse(json['vote_date']?.toString() ?? ''),
    publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
    category: json['category'] as String? ?? 'Législation',
    status: json['status'] as String? ?? 'unknown',
    sourceUrl: json['source_url'] as String?,
    descriptionSourceUrl: json['description_source_url'] as String?,
  );

  bool get isPending => status == 'pending';
  bool get isVoted => ['adopted', 'rejected', 'promulgated'].contains(status);
  bool get hasResults => scrutinId != null && scrutinId!.startsWith('VTAN');

  String get statusLabel => switch (status) {
    'pending' => 'En cours d’examen',
    'adopted' => 'Adopté à l’Assemblée',
    'rejected' => 'Rejeté à l’Assemblée',
    'promulgated' => 'Loi promulguée',
    'withdrawn' => 'Texte retiré',
    _ => 'Statut à vérifier',
  };

  int? get daysUntilVote {
    if (voteDate == null) return null;
    final now = DateTime.now();
    // Compare calendar dates without DST or time-of-day rounding.
    return DateTime.utc(
      voteDate!.year,
      voteDate!.month,
      voteDate!.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  }

  String get date {
    final value = voteDate ?? publishedAt;
    if (value == null) {
      return isPending ? 'Date de vote non annoncée' : 'Date non disponible';
    }
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String get urgencyLabel {
    if (!isPending) return statusLabel;
    final days = daysUntilVote;
    if (days == null) return 'En cours d’examen';
    if (days < 0) return 'Calendrier à confirmer';
    if (days == 0) return 'Vote prévu aujourd’hui';
    return 'Vote prévu dans $days jour${days == 1 ? '' : 's'}';
  }

  Color get urgencyColor {
    if (status == 'rejected') return AppColors.frRed;
    if (isVoted) return AppColors.accentGreen;
    final days = daysUntilVote;
    if (days != null && days >= 0 && days <= 21) return AppColors.accentOrange;
    return AppColors.frBlue;
  }
}
