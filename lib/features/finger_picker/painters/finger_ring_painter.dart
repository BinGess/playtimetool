import 'dart:math';
import 'package:flutter/material.dart';
import '../models/finger_state.dart';

/// 绘制所有指尖的霓虹圆环。
///
/// [glowPulse]   : 0.0–1.0，呼吸动画进度
/// [spinAngle]   : 0–2π，倒计时阶段圆环上的旋转亮弧位置
/// [elimOrder]   : 落败者按淘汰顺序排列的 pointerId 列表
/// [elimVisible] : 当前已显示消除效果的数量
class FingerRingPainter extends CustomPainter {
  const FingerRingPainter({
    required this.fingers,
    required this.phase,
    required this.glowPulse,
    this.spinAngle = 0.0,
    this.elimOrder = const [],
    this.elimVisible = 0,
    Listenable? repaint,
  }) : super(repaint: repaint);

  final Map<int, FingerData> fingers;
  final PickerPhase phase;
  final double glowPulse;
  final double spinAngle;
  final List<int> elimOrder;
  final int elimVisible;

  // ── 尺寸常量 ────────────────────────────────────────────────────
  static const double _baseR = 42.0;   // 普通圆环半径
  static const double _winR  = 68.0;   // 胜利者圆环半径
  static const double _elimR = 28.0;   // 消除后缩小的圆环半径

  bool _isVisiblyEliminated(int id) {
    final idx = elimOrder.indexOf(id);
    return idx >= 0 && idx < elimVisible;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in fingers.values) {
      final visElim = _isVisiblyEliminated(f.pointerId);

      if (visElim || (f.isEliminated && phase == PickerPhase.result)) {
        _drawEliminated(canvas, f);
      } else if (f.isWinner && phase == PickerPhase.result) {
        _drawWinner(canvas, f);
      } else if (phase == PickerPhase.countdown) {
        _drawSpinning(canvas, f);
      } else if (phase == PickerPhase.locked) {
        _drawLocked(canvas, f);
      } else {
        _drawActive(canvas, f);
      }
    }
  }

  // ── 普通激活状态 ─────────────────────────────────────────────────
  void _drawActive(Canvas canvas, FingerData f) {
    final c = f.position;
    final color = f.neonColor;
    final bloom = 0.25 + 0.18 * glowPulse;

    // 外层光晕（呼吸）
    canvas.drawCircle(
      c,
      _baseR + 10,
      Paint()
        ..color = color.withAlpha((bloom * 200).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    // 主圆环
    canvas.drawCircle(
      c,
      _baseR,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // 中心点
    canvas.drawCircle(c, 5, Paint()..color = color);
  }

  // ── 锁定状态（粗一点的圆环，无旋转）────────────────────────────
  void _drawLocked(Canvas canvas, FingerData f) {
    final c = f.position;
    final color = f.neonColor;

    canvas.drawCircle(
      c,
      _baseR + 4,
      Paint()
        ..color = color.withAlpha(80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    canvas.drawCircle(
      c,
      _baseR,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(c, 5, Paint()..color = color);
  }

  // ── 倒计时旋转状态 ───────────────────────────────────────────────
  void _drawSpinning(Canvas canvas, FingerData f) {
    final c = f.position;
    final color = f.neonColor;

    // 底部暗圆环
    canvas.drawCircle(
      c,
      _baseR,
      Paint()
        ..color = color.withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // 旋转的亮弧（约 100° 的弧段）
    final sweepRect = Rect.fromCircle(center: c, radius: _baseR);
    canvas.drawArc(
      sweepRect,
      spinAngle,
      1.8, // ~103°
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // 内圈高亮弧（略短）
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: _baseR - 6),
      spinAngle + 0.2,
      1.2,
      false,
      Paint()
        ..color = color.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    // 中心点
    canvas.drawCircle(c, 5, Paint()..color = color);
  }

  // ── 消除动画（缩小 + 暗淡 + X）──────────────────────────────────
  void _drawEliminated(Canvas canvas, FingerData f) {
    final c = f.position;

    // 缩小的暗圆环
    canvas.drawCircle(
      c,
      _elimR,
      Paint()
        ..color = Colors.white.withAlpha(25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 红色 X
    const d = 13.0;
    final xPaint = Paint()
      ..color = Colors.red.withAlpha(200)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + const Offset(-d, -d), c + const Offset(d, d), xPaint);
    canvas.drawLine(c + const Offset(d, -d), c + const Offset(-d, d), xPaint);
  }

  // ── 胜利者（扩散波纹 + 粒子烟花）───────────────────────────────
  void _drawWinner(Canvas canvas, FingerData f) {
    final c = f.position;
    final color = f.neonColor;
    final scale = 1.0 + 0.14 * glowPulse;
    final r = _winR * scale;

    // 强光晕
    canvas.drawCircle(
      c,
      r + 14,
      Paint()
        ..color = color.withAlpha(120)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    // 填充色
    canvas.drawCircle(c, r, Paint()..color = color.withAlpha(45));
    // 外圈
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // 内圈（双环效果）
    canvas.drawCircle(
      c,
      r * 0.72,
      Paint()
        ..color = color.withAlpha(140)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // 中心点
    canvas.drawCircle(c, 7, Paint()..color = Colors.white);

    // 辐射粒子线
    _drawParticles(canvas, c, color, r);
  }

  void _drawParticles(
      Canvas canvas, Offset center, Color color, double r) {
    const n = 16;
    final paint = Paint()
      ..color = color.withAlpha((180 * (0.7 + 0.3 * glowPulse)).round())
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < n; i++) {
      final angle = (2 * pi / n) * i;
      final inner = r + 5;
      final outer = r + 18 + 12 * glowPulse;
      final start = center + Offset(cos(angle) * inner, sin(angle) * inner);
      final end   = center + Offset(cos(angle) * outer, sin(angle) * outer);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(FingerRingPainter old) => true;
}
