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

  static const TextStyle eyebrow = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.3,
    height: 1.2,
  );

  static TextStyle phaseCounter(Color accentColor) => TextStyle(
        color: accentColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );
}

abstract final class GameUiSurface {
  static BorderRadius get largeRadius => BorderRadius.circular(24);
  static BorderRadius get mediumRadius => BorderRadius.circular(20);
  static BorderRadius get smallRadius => BorderRadius.circular(16);

  static Color foregroundOn(Color color) =>
      color.computeLuminance() > 0.45 ? Colors.black : Colors.white;

  static Color shiftHue(
    Color color, {
    double by = 26,
    double saturation = 0.88,
    double lightness = 0.62,
  }) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withHue((hsl.hue + by) % 360)
        .withSaturation(saturation.clamp(0.0, 1.0))
        .withLightness(lightness.clamp(0.0, 1.0))
        .toColor();
  }

  static Color darkTone(
    Color color, {
    double lightness = 0.16,
    double saturation = 0.52,
  }) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(lightness.clamp(0.0, 1.0))
        .withSaturation(saturation.clamp(0.0, 1.0))
        .toColor();
  }

  static LinearGradient accentGradient(
    Color accentColor, {
    Color? secondaryColor,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    final secondary = secondaryColor ?? shiftHue(accentColor, by: 34);
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        accentColor.withAlpha(230),
        secondary.withAlpha(225),
      ],
    );
  }

  static BoxDecoration panel({
    required Color accentColor,
    Color? secondaryColor,
    BorderRadius? borderRadius,
    double opacity = 0.96,
  }) {
    final secondary = secondaryColor ?? shiftHue(accentColor, by: 28);
    return BoxDecoration(
      borderRadius: borderRadius ?? largeRadius,
      border: Border.all(color: accentColor.withAlpha(95)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkTone(accentColor, lightness: 0.18).withValues(alpha: opacity),
          darkTone(secondary, lightness: 0.13).withValues(alpha: opacity),
          const Color(0xFF05070D).withValues(alpha: 0.98),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withAlpha(30),
          blurRadius: 28,
          offset: const Offset(0, 18),
        ),
      ],
    );
  }

  static BoxDecoration heroPanel({
    required Color accentColor,
    Color? secondaryColor,
  }) {
    return panel(
      accentColor: accentColor,
      secondaryColor: secondaryColor ?? shiftHue(accentColor, by: 46),
      borderRadius: BorderRadius.circular(26),
      opacity: 0.98,
    );
  }

  static BoxDecoration chip({
    required Color accentColor,
    bool selected = true,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: selected ? accentColor.withAlpha(28) : Colors.white.withAlpha(10),
      border: Border.all(
        color: selected ? accentColor.withAlpha(170) : Colors.white24,
      ),
    );
  }

  static ButtonStyle primaryButton(Color accentColor) {
    final foreground = foregroundOn(accentColor);
    return ElevatedButton.styleFrom(
      backgroundColor: accentColor,
      foregroundColor: foreground,
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: const Size.fromHeight(GameUiSpacing.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      textStyle: GameUiText.buttonLabel,
    );
  }

  static ButtonStyle secondaryButton(Color accentColor) {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.white.withAlpha(8),
      side: BorderSide(color: accentColor.withAlpha(140)),
      minimumSize: const Size.fromHeight(GameUiSpacing.buttonHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      textStyle: GameUiText.buttonLabel,
    );
  }
}
