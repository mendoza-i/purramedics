import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F9E8C);
  static const Color primaryDark = Color(0xFF0B7A6C);
  static const Color primaryLight = Color(0xFF4FC3B1);
  static const Color primarySurface = Color(0xFFE6F5F2);

  static const Color secondary = Color(0xFFFF8A6B);
  static const Color secondaryDark = Color(0xFFE56B4A);
  static const Color secondarySurface = Color(0xFFFFECE5);

  static const Color success = Color(0xFF10B981);
  static const Color successSurface = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSurface = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSurface = Color(0xFFDBEAFE);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  static const List<Color> primaryGradient = [primary, primaryDark];
}
