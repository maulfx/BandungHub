import 'package:flutter/material.dart';

class AppColors {
  // Primary Bandung Teal / Parahyangan Green
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF115E59);

  // Secondary Warm Amber / Terracotta
  static const Color secondary = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFF59E0B);
  static const Color secondaryDark = Color(0xFFB45309);

  // Neutral tones
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark mode
  static const Color backgroundDark = Color(0xFF0B132B);
  static const Color surfaceDark = Color(0xFF1C2541);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Category specific colors
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'alam':
        return const Color(0xFF10B981);
      case 'kuliner':
        return const Color(0xFFF97316);
      case 'sejarah':
        return const Color(0xFFD97706);
      case 'keluarga':
        return const Color(0xFF0284C7);
      case 'hiburan':
        return const Color(0xFF8B5CF6);
      default:
        return primary;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'alam':
        return Icons.landscape_rounded;
      case 'kuliner':
        return Icons.restaurant_rounded;
      case 'sejarah':
        return Icons.account_balance_rounded;
      case 'keluarga':
        return Icons.family_restroom_rounded;
      case 'hiburan':
        return Icons.attractions_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  // Adaptive Helpers based on active theme
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getTextPrimary(BuildContext context) {
    return isDarkMode(context) ? textPrimaryDark : textPrimaryLight;
  }

  static Color getTextSecondary(BuildContext context) {
    return isDarkMode(context) ? textSecondaryDark : textSecondaryLight;
  }

  static Color getBackgroundColor(BuildContext context) {
    return isDarkMode(context) ? backgroundDark : backgroundLight;
  }

  static Color getCardColor(BuildContext context) {
    return isDarkMode(context) ? cardDark : cardLight;
  }

  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? surfaceDark : surfaceLight;
  }

  static Color getBorderColor(BuildContext context) {
    return isDarkMode(context) ? borderDark : borderLight;
  }
}

