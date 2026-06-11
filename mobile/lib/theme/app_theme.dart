import 'package:flutter/material.dart';

class AppColors {
  // Primary palette — French Republic inspired
  static const Color frBlue = Color(0xFF002395);
  static const Color frRed = Color(0xFFED2939);
  static const Color frWhite = Color(0xFFFFFFFF);

  // Backgrounds
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0A1628);

  // Text
  static const Color textPrimary = Color(0xFF161616);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Accents
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Borders & Dividers
  static const Color border = Color(0xFFE5E5E5);
  static const Color divider = Color(0xFFF0F0F0);

  // Glassmorphism
  static const Color glassWhite = Color(0xCCFFFFFF);   // 80% white
  static const Color glassBorder = Color(0x33FFFFFF);    // 20% white
  static const Color glassShadow = Color(0x0A000000);    // very subtle shadow

  // Category colors
  static const Color catDefense = Color(0xFF1E40AF);
  static const Color catEconomie = Color(0xFF047857);
  static const Color catTravail = Color(0xFFB45309);
  static const Color catInterieur = Color(0xFF7C3AED);
  static const Color catDefault = Color(0xFF6B7280);

  static Color getCategoryColor(String category) {
    if (category.contains('Défense')) return catDefense;
    if (category.contains('Économie') || category.contains('Écologie')) return catEconomie;
    if (category.contains('Travail') || category.contains('Social')) return catTravail;
    if (category.contains('Intérieur')) return catInterieur;
    return catDefault;
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.frBlue,
        primary: AppColors.frBlue,
        secondary: AppColors.frRed,
        surface: AppColors.cardBackground,
        onPrimary: AppColors.textOnDark,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.frBlue,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.frWhite,
        selectedItemColor: AppColors.frBlue,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
