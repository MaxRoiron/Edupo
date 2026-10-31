import 'package:flutter/material.dart';
import '../models/law.dart';
import '../theme/civic_theme.dart';
import '../theme/app_theme.dart';
import 'civic_components.dart';

class LawCard extends StatelessWidget {
  const LawCard({
    super.key,
    required this.law,
    this.onTap,
    this.featured = false,
  });
  final Law law;
  final VoidCallback? onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final ink = featured ? Colors.white : Civic.ink;
    final muted = featured ? const Color(0xFFD6DDF5) : Civic.muted;
    final accent = featured ? Colors.white : Civic.blue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: featured ? Civic.blue : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Civic.radius),
          side: BorderSide(color: featured ? Civic.blue : Civic.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: CivicPress(
          onTap: onTap,
          radius: Civic.radius,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: featured
                                ? Colors.white
                                : AppColors.getCategoryColor(law.category),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            law.category,
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: featured
                            ? Colors.white.withValues(alpha: .12)
                            : law.isVoted
                            ? const Color(0xFFECF5EF)
                            : Civic.pale,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        law.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: featured
                              ? Colors.white
                              : law.isVoted
                              ? Civic.green
                              : Civic.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  law.title,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Civic.heading(21, color: ink),
                ),
                if (law.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    law.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 13, height: 1.55),
                  ),
                ],
                const SizedBox(height: 20),
                Divider(
                  height: 1,
                  color: featured
                      ? Colors.white.withValues(alpha: .2)
                      : Civic.line,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            law.hasResults
                                ? 'Voir les votes'
                                : 'Comprendre et donner mon avis',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            law.date,
                            style: TextStyle(
                              color: muted,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: featured ? Colors.white : Civic.pale,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Civic.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
