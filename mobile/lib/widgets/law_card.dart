import 'package:flutter/material.dart';
import '../models/law.dart';
import '../theme/app_theme.dart';

class LawCard extends StatelessWidget {
  final Law law;
  final VoidCallback? onTap;
  const LawCard({super.key, required this.law, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: AppColors.frBlue.withValues(alpha: .12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _badge(
                    law.category,
                    AppColors.getCategoryColor(law.category),
                  ),
                  _badge(law.statusLabel, law.urgencyColor),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                law.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
              if (law.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  law.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.event_rounded, size: 16, color: law.urgencyColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      law.date,
                      style: TextStyle(color: law.urgencyColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: Icon(
                    law.hasResults
                        ? Icons.bar_chart_rounded
                        : Icons.menu_book_rounded,
                  ),
                  label: Text(
                    law.hasResults
                        ? 'Voir les votes'
                        : 'Comprendre et donner mon avis',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      softWrap: true,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
