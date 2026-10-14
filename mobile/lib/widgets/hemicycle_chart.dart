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
    return Color(int.tryParse(hex, radix: 16) ?? 0xFF808080);
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
            double radius =
                innerRadius + (r / (rows - 1)) * (outerRadius - innerRadius);
            totalArcSum += radius;
          }

          int assigned = 0;
          for (int r = 0; r < rows; r++) {
            if (r == rows - 1) {
              seatsPerRow.add(totalSeats - assigned);
            } else {
              double radius =
                  innerRadius + (r / (rows - 1)) * (outerRadius - innerRadius);
              int s = ((radius / totalArcSum) * totalSeats).round();
              seatsPerRow.add(s);
              assigned += s;
            }
          }

          // Allocate by angular column across all rows, so each group forms
          // a continuous sector instead of restarting at the left of each row.
          final slots = <({double x, double y, double angle, double size})>[];
          const anglePadding = 0.06;
          for (int r = 0; r < rows; r++) {
            final progress = r / (rows - 1);
            final radius = innerRadius + progress * (outerRadius - innerRadius);
            final count = seatsPerRow[r];
            for (int seat = 0; seat < count; seat++) {
              final t = count <= 1 ? .5 : seat / (count - 1);
              final angle =
                  (math.pi - anglePadding) - t * (math.pi - 2 * anglePadding);
              slots.add((
                x: centerX + radius * math.cos(angle),
                y: centerY - radius * math.sin(angle),
                angle: angle,
                size: 5 + progress * 2.5,
              ));
            }
          }
          slots.sort((a, b) => b.angle.compareTo(a.angle));
          final seats = <_SeatData>[];
          for (int index = 0; index < slots.length; index++) {
            final slot = slots[index];
            final vote = sortedVotes[index];
            final matches =
                (activeFilter == null || activeFilter == vote['position']) &&
                (selectedGroup == null || selectedGroup == vote['groupe']);
            final groupColor = _parseColor(
              vote['color']?.toString() ?? '#808080',
            );
            // Non-voters remain neutral until specifically selected.
            final neutral =
                vote['position'] == 'non_votant' &&
                activeFilter == null &&
                selectedGroup == null;
            seats.add(
              _SeatData(
                x: slot.x,
                y: slot.y,
                size: slot.size,
                color: !matches
                    ? const Color(0xFFE5E7EB)
                    : neutral
                    ? const Color(0xFFC8CCD2)
                    : groupColor,
                opacity: matches ? 1 : .3,
                showGlow:
                    matches && (activeFilter != null || selectedGroup != null),
              ),
            );
          }

          return CustomPaint(
            size: Size(width, height),
            painter: _HemicyclePainter(
              seats: seats,
              signature: Object.hash(
                width,
                height,
                identityHashCode(votesList),
                activeFilter,
                selectedGroup,
              ),
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
  final int signature;
  final double centerX, centerY, innerRadius, outerRadius;

  _HemicyclePainter({
    required this.seats,
    required this.signature,
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
        canvas.drawCircle(Offset(seat.x, seat.y), seat.size * 0.9, glowPaint);
      }

      final dotPaint = Paint()
        ..color = seat.color.withValues(alpha: seat.opacity);
      canvas.drawCircle(Offset(seat.x, seat.y), seat.size / 2, dotPaint);

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
  bool shouldRepaint(covariant _HemicyclePainter oldDelegate) =>
      signature != oldDelegate.signature;
}
