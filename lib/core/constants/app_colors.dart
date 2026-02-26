import 'package:flutter/material.dart';

abstract final class AppColors {
  // Global background (OLED black)
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF111111);
  static const Color surfaceVariant = Color(0xFF1A1A1A);

  // Finger Picker - Electric Cyan
  static const Color fingerCyan = Color(0xFF00FFFF);
  static const Color fingerCyanDim = Color(0xFF007F7F);
  static const Color fingerCyanDark = Color(0xFF003333);

  // Spin Wheel - Sunset Orange
  static const Color wheelOrange = Color(0xFFFF6B35);
  static const Color wheelOrangeDim = Color(0xFF803518);
  static const Color wheelOrangeDark = Color(0xFF331500);

  // Number Bomb - Vivid Red
  static const Color bombRed = Color(0xFFFF2020);
  static const Color bombRedDim = Color(0xFF801010);
  static const Color bombBlueDark = Color(0xFF0A0A2E); // calm start bg
  static const Color bombRedDark = Color(0xFF2E0A0A);  // tense end bg

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF888888);
  static const Color textDim = Color(0xFF444444);

  // Glass effect tint
  static const Color glassTint = Color(0x0FFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);

  // 10 neon colors for finger picker (cyclic assignment)
  static const List<Color> fingerNeons = [
    Color(0xFF00FFFF), // Cyan
    Color(0xFFFF00FF), // Magenta
    Color(0xFF00FF66), // Lime
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF6B35), // Orange
    Color(0xFF9B00FF), // Violet
    Color(0xFFFF0080), // Hot Pink
    Color(0xFF00FF80), // Spring Green
    Color(0xFF0080FF), // Azure
    Color(0xFFFF8C00), // Amber
  ];
}
