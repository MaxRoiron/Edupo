import 'dart:math' as math;
import 'package:flutter/material.dart';

class HemicycleChart extends StatelessWidget {
  final List<dynamic> votesList;
  final String? activeFilter; // 'pour', 'contre', 'abstention', null

  const HemicycleChart({super.key, required this.votesList, this.activeFilter});

  Color _getGroupColor(String groupAcronym) {
    switch (groupAcronym) {
      case 'RN':
        return const Color(0xFF04195E);
      case 'LFI-NUPES':
        return const Color(0xFFCC2443);
      case 'LR':
        return const Color(0xFF0066CC);
      case 'RE':
        return const Color(0xFFFFB400);
      case 'DEM':
        return const Color(0xFFED7F10);
      case 'SOC':
        return const Color(0xFFE42313);
      case 'HOR':
        return const Color(0xFF38B2E8);
      case 'ECO-NUPES':
        return const Color(0xFF00C02A);
      case 'GDR-NUPES':
        return const Color(0xFF9C2A2A);
      case 'LIOT':
        return const Color(0xFFFCE900);
      default:
        return const Color(0xFF808080);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (votesList.isEmpty) return const SizedBox.shrink();

    // Sort votes by party (Left to Right in standard assembly arrangement)
    final leftToRight = [
      'GDR-NUPES',
      'LFI-NUPES',
      'SOC',
      'ECO-NUPES',
      'LIOT',
      'RE',
      'DEM',
      'HOR',
      'LR',
      'RN',
    ];

    final sortedVotes = List<dynamic>.from(votesList);
    sortedVotes.sort((a, b) {
      final ga = a['vote']['parlementaire_groupe_acronyme']?.toString() ?? '';
      final gb = b['vote']['parlementaire_groupe_acronyme']?.toString() ?? '';
      var idxA = leftToRight.indexOf(ga);
      var idxB = leftToRight.indexOf(gb);
      if (idxA == -1) idxA = 99;
      if (idxB == -1) idxB = 99;
      return idxA.compareTo(idxB);
    });

    return AspectRatio(
      aspectRatio: 2.0, // Semi-circle is twice as wide as it is tall
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final centerX = width / 2;
          final centerY = height;

          final innerRadius = width * 0.18;
          final outerRadius = width * 0.48;

          final totalSeats = sortedVotes.length;
          final int rows = 12; // Number of concentric semicircles

          // Math to calculate seats per row to form an even hemicycle
          List<int> seatsPerRow = [];
          double totalRadiusSum = 0;
          for (int r = 1; r <= rows; r++) {
            totalRadiusSum += r;
          }

          int assigned = 0;
          for (int r = 1; r <= rows; r++) {
            if (r == rows) {
              seatsPerRow.add(totalSeats - assigned);
            } else {
              int s = ((r / totalRadiusSum) * totalSeats).round();
              seatsPerRow.add(s);
              assigned += s;
            }
          }

          List<Widget> dots = [];
          int seatIndex = 0;

          for (int r = 0; r < rows; r++) {
            double progress = rows > 1 ? (r / (rows - 1)) : 0.0;
            double currentRadius =
                innerRadius + progress * (outerRadius - innerRadius);
            int seatsInRow = seatsPerRow[r];

            for (int s = 0; s < seatsInRow; s++) {
              if (seatIndex >= totalSeats) break;

              final voteObj = sortedVotes[seatIndex]['vote'] ?? {};
              final position = voteObj['position']?.toString() ?? '';
              final group =
                  voteObj['parlementaire_groupe_acronyme']?.toString() ?? '';

              // Angle goes from Pi (left) to 0 (right)
              double angle =
                  math.pi -
                  (s / (seatsInRow <= 1 ? 1 : (seatsInRow - 1))) * math.pi;

              double x = centerX + currentRadius * math.cos(angle);
              double y = centerY - currentRadius * math.sin(angle);

              // Determine color
              bool isActive = activeFilter != null && activeFilter == position;
              Color dotColor;
              if (activeFilter == null) {
                dotColor = const Color(0xFFD1D5DB); // Neutral Gray default
              } else if (isActive) {
                dotColor = _getGroupColor(group); // Colored by party
              } else {
                dotColor = const Color(
                  0xFFF3F4F6,
                ).withValues(alpha: 0.5); // Very Dim
              }

              dots.add(
                Positioned(
                  left: x - 4, // 8px dot diameter
                  top: y - 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 7.5,
                    height: 7.5,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
              seatIndex++;
            }
          }

          return Stack(children: dots);
        },
      ),
    );
  }
}
