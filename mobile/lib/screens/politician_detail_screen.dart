import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/political_party.dart';
import '../theme/app_theme.dart';

class PoliticianDetailScreen extends StatelessWidget {
  final PoliticalParty party;

  const PoliticianDetailScreen({super.key, required this.party});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: party.primaryColor,
        elevation: 0,
        title: Text(party.leader, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [party.primaryColor, party.primaryColor.withValues(alpha: 0.0)],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Hero(
                    tag: 'leader_${party.abbreviation}',
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          )
                        ],
                        image: DecorationImage(
                          image: AssetImage(party.leaderAsset),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    party.leader,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: party.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: party.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(party.logoAsset, width: 24, height: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Leader - ${party.name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: party.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Carrière',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      party.leaderCareer,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.flag_rounded,
                    title: 'Parti Politique',
                    value: party.name,
                    color: party.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.account_balance_rounded,
                    title: 'Idéologie',
                    value: party.ideology,
                    color: party.secondaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.explore_rounded,
                    title: 'Positionnement',
                    value: party.positioning,
                    color: AppColors.accentBlue,
                  ),
                  if (party.constituency != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.map_rounded,
                      title: 'Circonscription',
                      value: party.constituency!,
                      color: party.primaryColor,
                    ),
                  ],
                  if (party.seatNumber != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.event_seat_rounded,
                      title: 'Siège Hémicycle',
                      value: party.seatNumber!,
                      color: party.secondaryColor,
                    ),
                  ],
                  if (party.assemblyLink != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.link_rounded,
                      title: 'Fiche Assemblée Nationale',
                      value: 'Voir sur assemblee-nationale.fr',
                      color: AppColors.accentBlue,
                      onTap: () async {
                        final url = Uri.parse(party.assemblyLink!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: onTap != null ? Colors.blue : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.open_in_new_rounded, color: Colors.blue, size: 20),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}
