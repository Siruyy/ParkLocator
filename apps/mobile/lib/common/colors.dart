import 'package:flutter/material.dart';

/// App color palette based on the design system
class AppColors {
  AppColors._();

  /// Primary brand color (blue from logo)
  static const Color primary = Color(0xFF2E7CC2);

  /// Primary color variants
  static const Color primaryLight = Color(
    0xFF5FA6E6,
  ); // Lighter shade of #2e7cc2
  static const Color primaryDark = Color(0xFF1A5A94); // Darker shade of #2e7cc2

  /// Accent color (yellow from logo)
  static const Color accent = Color(0xFFFBE709);

  /// Background colors
  static const Color background = Color(0xFFFCFCFC);
  static const Color backgroundSecondary = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFF1F5F9);

  /// Text colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  /// Border colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  /// Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  /// Available spots indicator
  static const Color available = Color(0xFF22C55E);
  static const Color limited = Color(0xFFF59E0B);
  static const Color full = Color(0xFFEF4444);
}
