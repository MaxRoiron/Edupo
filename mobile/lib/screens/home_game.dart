import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: EdupoGame());
  }
}

class ClickableSprite extends SpriteComponent with TapCallbacks {
  void Function()? onTap;

  ClickableSprite({this.onTap});

  @override
  void onTapDown(TapDownEvent event) {
    onTap?.call();
  }
}

/// Boîte de dialogue rétro style RPG avec effet machine à écrire
class RetroDialogBox extends PositionComponent {
  final String text;
  final double charDelay; // secondes entre chaque caractère
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final double fontSize;
  final double padding;
  final double borderWidth;

  int _charCount = 0;
  double _timer = 0;
  bool _isComplete = false;

  RetroDialogBox({
    required this.text,
    this.charDelay = 0.04,
    this.bgColor = const Color(0xE6111122),
    this.borderColor = const Color(0xFFDDDDDD),
    this.textColor = const Color(0xFFFFFFFF),
    this.fontSize = 18,
    this.padding = 16,
    this.borderWidth = 3,
    super.position,
    super.size,
  });

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isComplete) {
      _timer += dt;
      final newCount = (_timer / charDelay).floor();
      if (newCount >= text.length) {
        _charCount = text.length;
        _isComplete = true;
      } else {
        _charCount = newCount;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fond sombre
    final bgPaint = Paint()..color = bgColor;
    final bgRect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );

    // Bordure double style rétro
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      borderPaint,
    );

    // Bordure intérieure
    final innerRect = Rect.fromLTWH(
      borderWidth + 2,
      borderWidth + 2,
      width - (borderWidth + 2) * 2,
      height - (borderWidth + 2) * 2,
    );
    final innerBorderPaint = Paint()
      ..color = borderColor.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(2)),
      innerBorderPaint,
    );

    // Texte avec effet machine à écrire
    final displayText = text.substring(0, _charCount);
    final paragraphBuilder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(textAlign: TextAlign.left, fontSize: fontSize),
          )
          ..pushStyle(ui.TextStyle(color: textColor, fontSize: fontSize))
          ..addText(displayText);

    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: width - padding * 2));

    canvas.drawParagraph(paragraph, Offset(padding, padding));

    // Curseur clignotant
    if (!_isComplete) {
      final cursorVisible = (_timer * 3).floor() % 2 == 0;
      if (cursorVisible) {
        final cursorPaint = Paint()..color = textColor;
        // Position approximative du curseur après le dernier caractère
        final cursorX = padding + paragraph.longestLine;
        final lines = paragraph.computeLineMetrics();
        final cursorY = lines.isNotEmpty
            ? padding + (lines.length - 1) * fontSize * 1.2
            : padding;
        canvas.drawRect(
          Rect.fromLTWH(cursorX + 2, cursorY, fontSize * 0.5, fontSize),
          cursorPaint,
        );
      }
    }
  }

  /// Affiche tout le texte d'un coup
  void skipAnimation() {
    _charCount = text.length;
    _isComplete = true;
  }

  bool get isComplete => _isComplete;
}

class EdupoGame extends FlameGame {
  late RectangleComponent _background;
  RetroDialogBox? _currentDialog;

  void changeBgColor(Color color) {
    _background.paint.color = color;
  }

  void showRetroDialog(
    String text, {
    Vector2? boxPosition,
    double? boxWidth,
    double? boxHeight,
  }) {
    // Supprimer l'ancienne si elle existe
    _currentDialog?.removeFromParent();

    final margin = 12.0;
    final w = boxWidth ?? (size.x - margin * 2);
    final h = boxHeight ?? (size.y * 0.25);
    final pos = boxPosition ?? Vector2(margin, size.y - h - margin);

    _currentDialog = RetroDialogBox(
      text: text,
      position: pos,
      size: Vector2(w, h),
    );
    add(_currentDialog!);
  }

  /// Ferme la boîte de dialogue
  void hideRetroDialog() {
    _currentDialog?.removeFromParent();
    _currentDialog = null;
  }

  /// Sprite cliquable (avec callback onTap)
  Future<ClickableSprite> createSprite(
    String path,
    Vector2 position,
    double width,
    double ratio, {
    void Function()? onTap,
  }) async {
    final sprite = await Sprite.load(path);

    return ClickableSprite(onTap: onTap)
      ..sprite = sprite
      ..size = Vector2(width, width * ratio)
      ..anchor = Anchor.center
      ..position = position;
  }

  /// Sprite non cliquable (juste visuel)
  Future<SpriteComponent> createStaticSprite(
    String path,
    Vector2 position,
    double width,
    double ratio,
  ) async {
    final sprite = await Sprite.load(path);

    return SpriteComponent()
      ..sprite = sprite
      ..size = Vector2(width, width * ratio)
      ..anchor = Anchor.center
      ..position = position;
  }

  Future<void> takeLetter() async {}

  Future<void> openEnvelope() async {
    double spriteWidth = size.x * 0.3;
    double ratio = 350 / 248;

    final openedEnvelope = await createSprite(
      'opened_envelope.png',
      Vector2(size.x / 2, size.y),
      spriteWidth,
      ratio,
    );
    final letter = await createSprite(
      'letter.png',
      Vector2(size.x / 2, size.y - 100),
      spriteWidth,
      ratio,
      onTap: () {},
    );

    letter.onTap = () {
      letter.position = Vector2(size.x / 2, size.y / 3);
      letter.size = Vector2(size.x * 0.6, size.x * 0.6 * ratio);
      openedEnvelope.removeFromParent();
    };

    add(letter);
    add(openedEnvelope);
  }

  Future<void> initGame() async {
    changeBgColor(const Color.fromARGB(255, 108, 108, 108));
    double spriteWidth = size.x * 0.3;
    double ratio = 350 / 248;

    final envelope = await createSprite(
      'envelope.png',
      Vector2(size.x / 2, size.y),
      spriteWidth,
      ratio,
      onTap: () {},
    );

    envelope.onTap = () {
      openEnvelope();
      envelope.removeFromParent();
    };

    add(envelope);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Fond coloré (RectangleComponent plein écran)
    _background = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFFAF5F0), // Blanc cassé
    );
    add(_background);
    final dialogWidth = size.x - 12.0 * 2;
    showRetroDialog(
      "Bienvenue dans Edupo ! Ouvre l'enveloppe pour découvrir ta lettre...",
      boxPosition: Vector2((size.x - dialogWidth) / 2, 12),
    );

    await initGame();
  }
}
