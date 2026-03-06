import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

abstract final class GameUiSpacing {
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const EdgeInsets compactScreenPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 14);

  static const double topGap = 10;
  static const double sectionGap = 16;
  static const double blockGap = 12;
  static const double itemGap = 8;
  static const double itemGapTight = 6;

  static const double buttonHeight = 52;
}

abstract final class GameUiText {
  static const TextStyle navTitle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    height: 1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    height: 1.5,
  );

  static const TextStyle bodyStrong = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    height: 1.4,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  static TextStyle phaseCounter(Color accentColor) => TextStyle(
        color: accentColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );
}
