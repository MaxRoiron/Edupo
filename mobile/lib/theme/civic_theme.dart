import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Visual tokens scoped to the redesigned law feed and account surfaces.
abstract final class Civic {
  static const blue = AppColors.frBlue;
  static const red = AppColors.frRed;
  static const paper = Color(0xFFF6F6F2);
  static const ink = Color(0xFF151B2B);
  static const muted = Color(0xFF616778);
  static const line = Color(0xFFE3E5EB);
  static const pale = Color(0xFFEBEFFB);
  static const green = Color(0xFF167454);
  static const radius = 24.0;
  static const fast = Duration(milliseconds: 140);
  static const normal = Duration(milliseconds: 220);

  static Duration duration(BuildContext context, [bool slow = false]) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : (slow ? normal : fast);

  static TextStyle heading(double size, {Color color = ink}) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: -size * .035,
    height: 1.17,
    color: color,
  );

  static ThemeData theme(BuildContext context) => Theme.of(context).copyWith(
    scaffoldBackgroundColor: paper,
    colorScheme: const ColorScheme.light(
      primary: blue,
      secondary: red,
      surface: Colors.white,
      onSurface: ink,
      error: Color(0xFFB51B32),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: const TextStyle(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: blue, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ink,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
