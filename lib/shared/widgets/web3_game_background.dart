import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

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
    return IgnorePointer(
      child: Opacity(
        opacity: overlayOpacity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF060611),
                    Color(0xFF0E1022),
                    Color(0xFF050508),
                  ],
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
