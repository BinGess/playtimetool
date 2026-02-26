import 'package:flutter/material.dart';

/// Text widget with neon glow effect using multiple shadows.
class NeonText extends StatelessWidget {
  const NeonText(
    this.text, {
    super.key,
    required this.color,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.glowRadius = 8.0,
    this.letterSpacing,
    this.textAlign,
  });

  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final double glowRadius;
  final double? letterSpacing;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        shadows: [
          Shadow(color: color.withAlpha(200), blurRadius: glowRadius),
          Shadow(color: color.withAlpha(100), blurRadius: glowRadius * 2),
          Shadow(color: color.withAlpha(50), blurRadius: glowRadius * 4),
        ],
      ),
    );
  }
}
