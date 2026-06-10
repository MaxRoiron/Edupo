import 'dart:math' as math;
import 'package:flutter/material.dart';

class HemicycleChart extends StatelessWidget {
  final List<dynamic> votesList;
  final String? activeFilter; // 'pour', 'contre', 'abstention', null
  final String? selectedGroup; // group abbreviation or null

  const HemicycleChart({
    super.key,
    required this.votesList,
    this.activeFilter,
    this.selectedGroup,
  });

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    if (votesList.isEmpty) return const SizedBox.shrink();

    final sortedVotes = List<dynamic>.from(votesList);

    return AspectRatio(
      aspectRatio: 1.85,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final centerX = width / 2;
          final centerY = height * 0.92;

          final innerRadius = width * 0.15;
          final outerRadius = width * 0.47;

          final totalSeats = sortedVotes.length;
          final int rows = 14;

          // Distribute seats proportionally across rows (more seats on outer arcs)
          List<int> seatsPerRow = [];
          double totalArcSum = 0;
          for (int r = 0; r < rows; r++) {
            double radius = innerRadius + (r / (rows - 1)) * (outerRadius - innerRadius);
            totalArcSum += radius;
          }

          int assigned = 0;
          for (int r = 0; r < rows; r++) {
            if (r == rows - 1) {
              seatsPerRow.add(totalSeats - assigned);
            } else {
              double radius = innerRadius + (r / (rows - 1)) * (outerRadius - innerRadius);
              int s = ((radius / totalArcSum) * totalSeats).round();
              seatsPerRow.add(s);
              assigned += s;
            }
          }

          // Pre-compute all seat data for the painter
          List<_SeatData> seats = [];
          int seatIndex = 0;

          const double anglePadding = 0.06;

          for (int r = 0; r < rows; r++) {
            double progress = r / (rows - 1);
            double currentRadius = innerRadius + progress * (outerRadius - innerRadius);
            int seatsInRow = seatsPerRow[r];

            double dotSize = 5.0 + progress * 2.5;

            for (int s = 0; s < seatsInRow; s++) {
              if (seatIndex >= totalSeats) break;

              final voteObj = sortedVotes[seatIndex];
              final position = voteObj['position']?.toString() ?? '';
              final colorHex = voteObj['color']?.toString() ?? '#808080';
              final groupe = voteObj['groupe']?.toString() ?? '';
              final groupColor = _parseColor(colorHex);

              double t = seatsInRow <= 1 ? 0.5 : s / (seatsInRow - 1);
              double angle = (math.pi - anglePadding) - t * (math.pi - 2 * anglePadding);

              double x = centerX + currentRadius * math.cos(angle);
              double y = centerY - currentRadius * math.sin(angle);

              // --- Color logic ---
              bool matchesFilter = activeFilter == null || activeFilter == position;
              bool matchesGroup = selectedGroup == null || selectedGroup == groupe;
              bool isHighlighted = matchesFilter && matchesGroup;

              Color dotColor;
              double opacity = 1.0;
              bool showGlow = false;

              if (activeFilter == null && selectedGroup == null) {
                // No filter: show all with party colors
                dotColor = groupColor;
              } else if (isHighlighted) {
                // Matches active filters
                dotColor = groupColor;
                showGlow = true;
              } else {
                // Dimmed
                dotColor = const Color(0xFFE5E7EB);
                opacity = 0.3;
              }

              seats.add(_SeatData(
                x: x,
                y: y,
                color: dotColor,
                opacity: opacity,
                size: dotSize,
                showGlow: showGlow,
              ));
              seatIndex++;
            }
          }

          return CustomPaint(
            size: Size(width, height),
            painter: _HemicyclePainter(
              seats: seats,
              centerX: centerX,
              centerY: centerY,
              innerRadius: innerRadius * 0.7,
              outerRadius: outerRadius + 8,
            ),
          );
        },
      ),
    );
  }
}

class _SeatData {
  final double x, y, size, opacity;
  final Color color;
  final bool showGlow;

  _SeatData({
    required this.x,
    required this.y,
    required this.color,
    required this.opacity,
    required this.size,
    required this.showGlow,
  });
}

class _HemicyclePainter extends CustomPainter {
  final List<_SeatData> seats;
  final double centerX, centerY, innerRadius, outerRadius;

  _HemicyclePainter({
    required this.seats,
    required this.centerX,
    required this.centerY,
    required this.innerRadius,
    required this.outerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // --- Background arc guides ---
    final guidePaint = Paint()
      ..color = const Color(0xFFF0F1F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 5; i++) {
      double t = i / 4;
      double r = innerRadius + t * (outerRadius - innerRadius);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: r),
        math.pi,
        -math.pi,
        false,
        guidePaint,
      );
    }

    // --- Podium / Speaker area ---
    final podiumGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        const Color(0xFF002395).withValues(alpha: 0.06),
        const Color(0xFF002395).withValues(alpha: 0.0),
      ],
    );

    final podiumRect = Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: innerRadius,
    );

    final podiumPaint = Paint()
      ..shader = podiumGradient.createShader(podiumRect);

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, centerY));
    canvas.drawCircle(Offset(centerX, centerY), innerRadius, podiumPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFF002395).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: innerRadius),
      math.pi,
      -math.pi,
      false,
      ringPaint,
    );
    canvas.restore();

    // --- Draw seats ---
    for (final seat in seats) {
      if (seat.showGlow) {
        final glowPaint = Paint()
          ..color = seat.color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(
          Offset(seat.x, seat.y),
          seat.size * 0.9,
          glowPaint,
        );
      }

      final dotPaint = Paint()
        ..color = seat.color.withValues(alpha: seat.opacity);
      canvas.drawCircle(
        Offset(seat.x, seat.y),
        seat.size / 2,
        dotPaint,
      );

      if (seat.opacity > 0.5) {
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.25);
        canvas.drawCircle(
          Offset(seat.x - seat.size * 0.12, seat.y - seat.size * 0.12),
          seat.size * 0.15,
          highlightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HemicyclePainter oldDelegate) => true;
}
