import 'package:flutter/material.dart';

class WheelSegment {
  const WheelSegment({
    required this.label,
    required this.color,
    this.weight = 1.0,
  });

  final String label;
  final Color color;
  final double weight; // Relative probability weight

  WheelSegment copyWith({String? label, Color? color, double? weight}) {
    return WheelSegment(
      label: label ?? this.label,
      color: color ?? this.color,
      weight: weight ?? this.weight,
    );
  }
}

class WheelConfig {
  const WheelConfig({
    required this.name,
    required this.segments,
    this.isPrankMode = false,
  });

  final String name;
  final List<WheelSegment> segments;
  final bool isPrankMode;

  WheelConfig copyWith({
    String? name,
    List<WheelSegment>? segments,
    bool? isPrankMode,
  }) {
    return WheelConfig(
      name: name ?? this.name,
      segments: segments ?? this.segments,
      isPrankMode: isPrankMode ?? this.isPrankMode,
    );
  }

  double get totalWeight =>
      segments.fold(0.0, (sum, s) => sum + s.weight);
}

// Pre-defined templates
abstract final class WheelPresets {
  static WheelConfig get dinner => const WheelConfig(
        name: '今晚吃啥',
        segments: [
          WheelSegment(label: '火锅', color: Color(0xFFFF4444)),
          WheelSegment(label: '烧烤', color: Color(0xFFFF8C00)),
          WheelSegment(label: '寿司', color: Color(0xFF44AAFF)),
          WheelSegment(label: '麻辣烫', color: Color(0xFFFF6B35)),
          WheelSegment(label: '披萨', color: Color(0xFF44FF88)),
          WheelSegment(label: '外卖', color: Color(0xFFAA44FF)),
        ],
      );

  static WheelConfig get whoPays => const WheelConfig(
        name: '谁买单',
        segments: [
          WheelSegment(label: '张三', color: Color(0xFF00FFFF)),
          WheelSegment(label: '李四', color: Color(0xFFFF00FF)),
          WheelSegment(label: '王五', color: Color(0xFF00FF66)),
          WheelSegment(label: '赵六', color: Color(0xFFFFFF00)),
          WheelSegment(label: '老板', color: Color(0xFFFF6B35), weight: 0.1),
        ],
      );

  static WheelConfig get truthDare => const WheelConfig(
        name: '真心话大冒险',
        segments: [
          WheelSegment(label: '真心话', color: Color(0xFF00FFFF)),
          WheelSegment(label: '大冒险', color: Color(0xFFFF4444)),
          WheelSegment(label: '真心话', color: Color(0xFF00FFFF)),
          WheelSegment(label: '大冒险', color: Color(0xFFFF4444)),
          WheelSegment(label: '双倍惩罚', color: Color(0xFFFF00FF), weight: 0.5),
        ],
      );

  static WheelConfig get games => const WheelConfig(
        name: '玩什么游戏',
        segments: [
          WheelSegment(label: '狼人杀', color: Color(0xFF9B00FF)),
          WheelSegment(label: '剧本杀', color: Color(0xFFFF6B35)),
          WheelSegment(label: '密室', color: Color(0xFF00FF80)),
          WheelSegment(label: '桌游', color: Color(0xFFFFFF00)),
          WheelSegment(label: '唱K', color: Color(0xFFFF0080)),
          WheelSegment(label: '电玩', color: Color(0xFF0080FF)),
        ],
      );

  static List<WheelConfig> get all => [dinner, whoPays, truthDare, games];
}
