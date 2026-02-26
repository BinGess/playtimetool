import 'dart:math';
import 'package:flutter/material.dart';
import '../models/wheel_segment.dart';

/// CustomPainter for the spin wheel.
/// Draws segments with text labels radiating outward, neon glow border,
/// and a fixed pointer triangle at the top.
class WheelPainter extends CustomPainter {
  const WheelPainter({
    required this.segments,
    required this.totalWeight,
    required this.angle,
    required this.accentColor,
    this.glowIntensity = 1.0,
    this.speed = 0.0,
  });

  final List<WheelSegment> segments;
  final double totalWeight;
  final double angle; // current rotation in radians
  final Color accentColor;
  final double glowIntensity; // 0.0–1.0
  final double speed; // angular velocity magnitude for blur effect

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.90;

    // Outer glow
    canvas.drawCircle(
      center,
      radius + 6,
      Paint()
        ..color = accentColor.withAlpha((80 * glowIntensity).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Draw segments
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    double startAngle = -pi / 2;
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final sweepAngle = (seg.weight / totalWeight) * 2 * pi;

      // Segment fill — no solid pie, just arced path for "open" look
      final segPaint = Paint()
        ..color = seg.color.withAlpha(200)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(0, 0)
        ..arcTo(
            Rect.fromCircle(center: Offset.zero, radius: radius),
            startAngle,
            sweepAngle,
            false)
        ..close();
      canvas.drawPath(path, segPaint);

      // Divider line
      canvas.drawLine(
        Offset.zero,
        Offset(cos(startAngle) * radius, sin(startAngle) * radius),
        Paint()
          ..color = Colors.black.withAlpha(200)
          ..strokeWidth = 2,
      );

      // Segment label
      _drawLabel(canvas, seg.label, startAngle, sweepAngle, radius);

      startAngle += sweepAngle;
    }

    // Center hub circle
    canvas.drawCircle(
      Offset.zero,
      18,
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      Offset.zero,
      18,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.restore();

    // Fixed pointer at top center (not affected by rotation)
    _drawPointer(canvas, center, radius);
  }

  void _drawLabel(Canvas canvas, String text, double startAngle,
      double sweepAngle, double radius) {
    final midAngle = startAngle + sweepAngle / 2;
    final labelR = radius * 0.62;
    final x = cos(midAngle) * labelR;
    final y = sin(midAngle) * labelR;

    final opacity = speed > 8 ? 0.3 : (speed > 3 ? 0.7 : 1.0);

    // UX: min 16px for mobile readability; letterSpacing for legibility
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withAlpha((255 * opacity).round()),
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          height: 1.35,
          shadows: const [
            Shadow(color: Colors.black54, blurRadius: 4),
            Shadow(color: Colors.black, blurRadius: 2),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 84);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(midAngle + pi / 2);
    painter.paint(
        canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  void _drawPointer(Canvas canvas, Offset center, double radius) {
    const pSize = 14.0;
    final tipY = center.dy - radius - 2;
    final path = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - pSize / 2, tipY - pSize)
      ..lineTo(center.dx + pSize / 2, tipY - pSize)
      ..close();

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = accentColor.withAlpha(120)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Solid pointer
    canvas.drawPath(
      path,
      Paint()..color = accentColor,
    );
  }

  @override
  bool shouldRepaint(WheelPainter old) =>
      old.angle != angle ||
      old.glowIntensity != glowIntensity ||
      old.speed != speed ||
      old.segments != segments;
}
