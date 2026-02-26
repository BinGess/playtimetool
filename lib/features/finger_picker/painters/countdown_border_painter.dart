import 'dart:math';
import 'package:flutter/material.dart';

/// Paints a cyan progress arc around the screen border that sweeps as
/// countdown progresses. progress: 0.0 (start) → 1.0 (complete).
class CountdownBorderPainter extends CustomPainter {
  const CountdownBorderPainter({required this.progress});

  final double progress; // 0.0 → 1.0

  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFF00FFFF);
    const strokeW = 3.0;
    const padding = strokeW / 2;

    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    // Glow layer
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW + 6
        ..strokeCap = StrokeCap.round,
    );

    // Crisp arc
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(CountdownBorderPainter old) =>
      old.progress != progress;
}
