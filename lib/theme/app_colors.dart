import 'package:flutter/material.dart';

/// Colors taken from the CommiLink Figma design tokens.
class AppColors {
  AppColors._();

  // Brand
  static const Color wine900 = Color(0xFF3E0A1F);
  static const Color wine700 = Color(0xFF650C2C);
  static const Color wine500 = Color(0xFF8C2A4B);
  static const Color peach400 = Color(0xFFEFB988);
  static const Color peach100 = Color(0xFFFCEEE1);

  // Text
  static const Color textPrimary = Color(0xFF2A0714);
  static const Color textSecondary = Color(0xFF6E4E58);
  static const Color textTertiary = Color(0xFFA68A93);
  static const Color textOnBrand = Color(0xFFFFFFFF);

  // Neutrals
  static const Color bg = Color(0xFFF9F1EF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEBD9D5);
  static const Color muted = Color(0xFFF3E6E3);

  // Status
  static const Color error = Color(0xFFB3261E);
  static const Color danger = Color(0xFFB42332);
  static const Color dangerBg = Color(0xFFFBE3E5);

  // Button gradient (top -> bottom)
  static const Color ctaTop = Color(0xFF7A1A3A);
  static const Color ctaBottom = Color(0xFF43091F);
}