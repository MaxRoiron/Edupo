import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/civic_theme.dart';

/// Adaptive native transitions retain the iOS back gesture and Android behavior.
/// Reduced motion takes effect at navigation time; the feed has no route ticker.
class CivicPageRoute<T> extends MaterialPageRoute<T> {
  CivicPageRoute({required BuildContext context, required super.builder})
    : _motionDuration = Civic.duration(context, true);

  final Duration _motionDuration;
  @override
  Duration get transitionDuration => _motionDuration;
  @override
  Duration get reverseTransitionDuration => _motionDuration;
}

class CivicWordmark extends StatelessWidget {
  const CivicWordmark({super.key, this.size = 27});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Édupo',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'édu',
            textScaler: TextScaler.noScaling,
            style: Civic.heading(size, color: Civic.blue),
          ),
          Text(
            'po',
            textScaler: TextScaler.noScaling,
            style: Civic.heading(size, color: Civic.blue),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 3, top: 15),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Civic.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A press response, with no persistent ticker or entry animation on scroll.
class CivicPress extends StatefulWidget {
  const CivicPress({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 20,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  @override
  State<CivicPress> createState() => _CivicPressState();
}

class _CivicPressState extends State<CivicPress> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: _pressed && !MediaQuery.disableAnimationsOf(context) ? .985 : 1,
    duration: Civic.duration(context),
    curve: Curves.easeOutCubic,
    child: InkWell(
      borderRadius: BorderRadius.circular(widget.radius),
      onTap: widget.onTap,
      onHighlightChanged: (value) {
        if (mounted) setState(() => _pressed = value);
      },
      child: widget.child,
    ),
  );
}

class CivicButton extends StatelessWidget {
  const CivicButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.secondary = false,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy, secondary;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Material(
    color: secondary ? Colors.white : Civic.blue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: secondary ? Civic.line : Civic.blue),
    ),
    child: CivicPress(
      onTap: busy ? null : onPressed,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: secondary ? Civic.blue : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (busy)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: secondary ? Civic.blue : Colors.white,
                ),
              )
            else
              Icon(
                icon,
                color: secondary ? Civic.blue : Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    ),
  );
}

class CivicNotice extends StatelessWidget {
  const CivicNotice({
    super.key,
    required this.message,
    this.action,
    this.onAction,
    this.error = false,
  });
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final bool error;
  @override
  Widget build(BuildContext context) => Material(
    color: error ? const Color(0xFFFFEFF0) : Civic.pale,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                error
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                color: error ? const Color(0xFFA51B2F) : Civic.blue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    style: TextStyle(
                      color: error ? const Color(0xFFA51B2F) : Civic.blue,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (action != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onAction, child: Text(action!)),
            ),
        ],
      ),
    ),
  );
}

class CivicHemicycle extends StatelessWidget {
  const CivicHemicycle({
    super.key,
    this.color = Civic.blue,
    this.fadeEdges = false,
  });
  final Color color;
  final bool fadeEdges;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(painter: _HemicycleMark(color, fadeEdges: fadeEdges)),
    ),
  );
}

class _HemicycleMark extends CustomPainter {
  _HemicycleMark(this.color, {required this.fadeEdges});
  final Color color;
  final bool fadeEdges;

  double _fade(double value) {
    final t = value.clamp(0.0, 1.0).toDouble();
    return t * t * (3 - 2 * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .86);
    final unit = math.min(size.width, size.height * 1.72);
    for (var ring = 0; ring < 5; ring++) {
      final radius = unit * (.19 + ring * .075);
      final count = 9 + ring * 4;
      for (var seat = 0; seat < count; seat++) {
        final theta = math.pi + math.pi * seat / (count - 1);
        final position =
            center + Offset(math.cos(theta), math.sin(theta)) * radius;
        final seatColor = (ring == 4 && seat > count - 5)
            ? Civic.red
            : color.withValues(alpha: .25 + ring * .14);
        // Fade each dot directly; no blur or offscreen shader layer on scroll.
        final opacity = fadeEdges
            ? .65 *
                  (.30 + .70 * _fade((position.dx / size.width - .05) / .75)) *
                  (.35 + .65 * _fade((.90 - position.dy / size.height) / .38))
            : 1.0;
        final paint = Paint()
          ..color = seatColor.withValues(alpha: seatColor.a * opacity);
        canvas.drawCircle(position, unit * .013, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HemicycleMark old) =>
      old.color != color || old.fadeEdges != fadeEdges;
}
