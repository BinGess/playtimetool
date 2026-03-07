import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../styles/game_ui_style.dart';

/// NFT / Web3-inspired dark gradient background with neon blobs.
class Web3GameBackground extends StatelessWidget {
  const Web3GameBackground({
    super.key,
    required this.accentColor,
    this.secondaryColor = AppColors.wheelOrange,
    this.overlayOpacity = 0.9,
  });

  final Color accentColor;
  final Color secondaryColor;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    final primaryBase = GameUiSurface.darkTone(
      accentColor,
      lightness: 0.14,
      saturation: 0.58,
    );
    final secondaryBase = GameUiSurface.darkTone(
      secondaryColor,
      lightness: 0.1,
      saturation: 0.5,
    );

    return IgnorePointer(
      child: Opacity(
        opacity: overlayOpacity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryBase,
                    secondaryBase,
                    const Color(0xFF030407),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _AmbientMeshPainter(
                  accentColor: accentColor,
                  secondaryColor: secondaryColor,
                ),
              ),
            ),
            Positioned(
              left: -90,
              top: -70,
              child: _GlowBlob(
                size: 240,
                color: accentColor.withAlpha(55),
              ),
            ),
            Positioned(
              right: -100,
              top: 190,
              child: _GlowBlob(
                size: 220,
                color: secondaryColor.withAlpha(50),
              ),
            ),
            Positioned(
              left: 70,
              bottom: -130,
              child: _GlowBlob(
                size: 300,
                color: accentColor.withAlpha(35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientMeshPainter extends CustomPainter {
  const _AmbientMeshPainter({
    required this.accentColor,
    required this.secondaryColor,
  });

  final Color accentColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withAlpha(12);
    final accentPaint = Paint()..color = accentColor.withAlpha(14);
    final secondaryPaint = Paint()..color = secondaryColor.withAlpha(12);

    for (double y = size.height * 0.18; y < size.height; y += 72) {
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.35, y - 18, size.width, y + 12);
      canvas.drawPath(path, linePaint);
    }

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.28),
      size.width * 0.12,
      accentPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.72),
      size.width * 0.16,
      secondaryPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientMeshPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}
