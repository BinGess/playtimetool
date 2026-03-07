import 'package:flutter/material.dart';

class WheelSegment {
  const WheelSegment({
    required this.label,
    required this.color,
    this.weight = 1.0,
    this.labelLocalizationKey,
  });

  final String label;
  final Color color;
  final double weight; // Relative probability weight
  final String? labelLocalizationKey;

  WheelSegment copyWith({
    String? label,
    Color? color,
    double? weight,
    String? labelLocalizationKey,
  }) {
    return WheelSegment(
      label: label ?? this.label,
      color: color ?? this.color,
      weight: weight ?? this.weight,
      labelLocalizationKey: labelLocalizationKey ?? this.labelLocalizationKey,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'label': label,
      'color': color.toARGB32(),
      'weight': weight,
      'labelLocalizationKey': labelLocalizationKey,
    };
  }

  factory WheelSegment.fromJson(Map<String, dynamic> json) {
    return WheelSegment(
      label: json['label'] as String? ?? '',
      color: Color(json['color'] as int? ?? Colors.white.toARGB32()),
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      labelLocalizationKey: json['labelLocalizationKey'] as String?,
    );
  }
}

class WheelConfig {
  const WheelConfig({
    required this.id,
    required this.name,
    required this.segments,
    this.isPrankMode = false,
    this.nameLocalizationKey,
  });

  final String id;
  final String name;
  final List<WheelSegment> segments;
  final bool isPrankMode;
  final String? nameLocalizationKey;

  bool get isBuiltIn => id.startsWith('preset_');

  WheelConfig copyWith({
    String? id,
    String? name,
    List<WheelSegment>? segments,
    bool? isPrankMode,
    String? nameLocalizationKey,
  }) {
    return WheelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      segments: segments ?? this.segments,
      isPrankMode: isPrankMode ?? this.isPrankMode,
      nameLocalizationKey: nameLocalizationKey ?? this.nameLocalizationKey,
    );
  }

  double get totalWeight => segments.fold(0.0, (sum, s) => sum + s.weight);

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'isPrankMode': isPrankMode,
      'nameLocalizationKey': nameLocalizationKey,
    };
  }

  factory WheelConfig.fromJson(Map<String, dynamic> json) {
    final rawSegments = json['segments'];
    return WheelConfig(
      id: json['id'] as String? ?? 'custom_unknown',
      name: json['name'] as String? ?? '',
      segments: rawSegments is List
          ? rawSegments
              .whereType<Map>()
              .map(
                (segment) => WheelSegment.fromJson(
                  Map<String, dynamic>.from(segment),
                ),
              )
              .toList()
          : const [],
      isPrankMode: json['isPrankMode'] as bool? ?? false,
      nameLocalizationKey: json['nameLocalizationKey'] as String?,
    );
  }
}

// Pre-defined templates
abstract final class WheelPresets {
  static WheelConfig get dinner => const WheelConfig(
        id: 'preset_dinner',
        name: 'preset_dinner',
        nameLocalizationKey: 'presetDinner',
        segments: [
          WheelSegment(
            label: 'dinner_hotpot',
            labelLocalizationKey: 'wheelPresetDinnerHotPot',
            color: Color(0xFFFF4444),
          ),
          WheelSegment(
            label: 'dinner_bbq',
            labelLocalizationKey: 'wheelPresetDinnerBbq',
            color: Color(0xFFFF8C00),
          ),
          WheelSegment(
            label: 'dinner_sushi',
            labelLocalizationKey: 'wheelPresetDinnerSushi',
            color: Color(0xFF44AAFF),
          ),
          WheelSegment(
            label: 'dinner_spicy_hotpot',
            labelLocalizationKey: 'wheelPresetDinnerSpicyHotPot',
            color: Color(0xFFFF6B35),
          ),
          WheelSegment(
            label: 'dinner_pizza',
            labelLocalizationKey: 'wheelPresetDinnerPizza',
            color: Color(0xFF44FF88),
          ),
          WheelSegment(
            label: 'dinner_takeout',
            labelLocalizationKey: 'wheelPresetDinnerTakeout',
            color: Color(0xFFAA44FF),
          ),
        ],
      );

  static WheelConfig get whoPays => const WheelConfig(
        id: 'preset_who_pays',
        name: 'preset_who_pays',
        nameLocalizationKey: 'presetWhoPays',
        segments: [
          WheelSegment(
            label: 'player_a',
            labelLocalizationKey: 'wheelPresetWhoPaysPlayerA',
            color: Color(0xFF00FFFF),
          ),
          WheelSegment(
            label: 'player_b',
            labelLocalizationKey: 'wheelPresetWhoPaysPlayerB',
            color: Color(0xFFFF00FF),
          ),
          WheelSegment(
            label: 'player_c',
            labelLocalizationKey: 'wheelPresetWhoPaysPlayerC',
            color: Color(0xFF00FF66),
          ),
          WheelSegment(
            label: 'player_d',
            labelLocalizationKey: 'wheelPresetWhoPaysPlayerD',
            color: Color(0xFFFFFF00),
          ),
          WheelSegment(
            label: 'boss',
            labelLocalizationKey: 'wheelPresetWhoPaysBoss',
            color: Color(0xFFFF6B35),
            weight: 0.1,
          ),
        ],
      );

  static WheelConfig get truthDare => const WheelConfig(
        id: 'preset_truth_dare',
        name: 'preset_truth_dare',
        nameLocalizationKey: 'presetTruthDare',
        segments: [
          WheelSegment(
            label: 'truth',
            labelLocalizationKey: 'wheelPresetTruthDareTruth',
            color: Color(0xFF00FFFF),
          ),
          WheelSegment(
            label: 'dare',
            labelLocalizationKey: 'wheelPresetTruthDareDare',
            color: Color(0xFFFF4444),
          ),
          WheelSegment(
            label: 'truth_2',
            labelLocalizationKey: 'wheelPresetTruthDareTruth',
            color: Color(0xFF00FFFF),
          ),
          WheelSegment(
            label: 'dare_2',
            labelLocalizationKey: 'wheelPresetTruthDareDare',
            color: Color(0xFFFF4444),
          ),
          WheelSegment(
            label: 'double_penalty',
            labelLocalizationKey: 'wheelPresetTruthDareDoublePenalty',
            color: Color(0xFFFF00FF),
            weight: 0.5,
          ),
        ],
      );

  static WheelConfig get games => const WheelConfig(
        id: 'preset_games',
        name: 'preset_games',
        nameLocalizationKey: 'presetGames',
        segments: [
          WheelSegment(
            label: 'werewolf',
            labelLocalizationKey: 'wheelPresetGamesWerewolf',
            color: Color(0xFF9B00FF),
          ),
          WheelSegment(
            label: 'murder_mystery',
            labelLocalizationKey: 'wheelPresetGamesMurderMystery',
            color: Color(0xFFFF6B35),
          ),
          WheelSegment(
            label: 'escape_room',
            labelLocalizationKey: 'wheelPresetGamesEscapeRoom',
            color: Color(0xFF00FF80),
          ),
          WheelSegment(
            label: 'board_game',
            labelLocalizationKey: 'wheelPresetGamesBoardGame',
            color: Color(0xFFFFFF00),
          ),
          WheelSegment(
            label: 'karaoke',
            labelLocalizationKey: 'wheelPresetGamesKaraoke',
            color: Color(0xFFFF0080),
          ),
          WheelSegment(
            label: 'arcade',
            labelLocalizationKey: 'wheelPresetGamesArcade',
            color: Color(0xFF0080FF),
          ),
        ],
      );

  static List<WheelConfig> get all => [dinner, whoPays, truthDare, games];
}
