import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C47FF);
  static const Color primaryLight = Color(0xFF9B7BFF);
  static const Color primaryDark = Color(0xFF4A25DD);
  static const Color secondary = Color(0xFF26C6DA);
  // Light theme colors
  static const Color background = Color(0xFFF3F0FF);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color textLight = Color(0xFFBDBDBD);
  // Shared colors
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFEF5350);
  // Dark theme colors
  static const Color darkBackground = Color(0xFF0F0B29);
  static const Color darkCard = Color(0xFF16003B);
  static const Color darkCardLight = Color(0xFF2A0A6B);
  static const Color darkTextDark = Color(0xFFFFFFFF);
  static const Color darkTextGrey = Color(0xFFB3B3B3);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      cardColor: AppColors.cardBg,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textDark),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkTextDark),
      ),
      cardColor: AppColors.darkCard,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkTextDark),
        bodyMedium: TextStyle(color: AppColors.darkTextDark),
      ),
    );
  }

  // Helper getters to use colors based on ThemeMode dynamically in the UI
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBackground
        : AppColors.background;
  }
  
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkCard
        : AppColors.cardBg;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextDark
        : AppColors.textDark;
  }

  static Color getTextGreyColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextGrey
        : AppColors.textGrey;
  }
}
