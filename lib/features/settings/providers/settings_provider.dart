import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';
import '../../penalty_plugin/domain/penalty_models.dart';

class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.minimalMode = false,
    this.alcoholPenaltyEnabled = true,
    this.defaultPenaltyCountry = PenaltyCountry.cn,
    this.defaultPenaltyDifficulty = PenaltyDifficulty.normal,
    this.defaultPenaltyScale = PenaltyScale.medium,
    this.defaultPenaltySelectionMode = PenaltySelectionMode.random,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool minimalMode;
  final bool alcoholPenaltyEnabled;
  final PenaltyCountry defaultPenaltyCountry;
  final PenaltyDifficulty defaultPenaltyDifficulty;
  final PenaltyScale defaultPenaltyScale;
  final PenaltySelectionMode defaultPenaltySelectionMode;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? minimalMode,
    bool? alcoholPenaltyEnabled,
    PenaltyCountry? defaultPenaltyCountry,
    PenaltyDifficulty? defaultPenaltyDifficulty,
    PenaltyScale? defaultPenaltyScale,
    PenaltySelectionMode? defaultPenaltySelectionMode,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      minimalMode: minimalMode ?? this.minimalMode,
      alcoholPenaltyEnabled:
          alcoholPenaltyEnabled ?? this.alcoholPenaltyEnabled,
      defaultPenaltyCountry:
          defaultPenaltyCountry ?? this.defaultPenaltyCountry,
      defaultPenaltyDifficulty:
          defaultPenaltyDifficulty ?? this.defaultPenaltyDifficulty,
      defaultPenaltyScale: defaultPenaltyScale ?? this.defaultPenaltyScale,
      defaultPenaltySelectionMode:
          defaultPenaltySelectionMode ?? this.defaultPenaltySelectionMode,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _keySound = 'soundEnabled';
  static const _keyVibration = 'vibrationEnabled';
  static const _keyMinimal = 'minimalMode';
  static const _keyAlcoholPenalty = 'alcoholPenaltyEnabled';
  static const _keyPenaltyCountry = 'penaltyCountry';
  static const _keyPenaltyDifficulty = 'penaltyDifficulty';
  static const _keyPenaltyScale = 'penaltyScale';
  static const _keyPenaltySelectionMode = 'penaltySelectionMode';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(
      soundEnabled: prefs.getBool(_keySound) ?? true,
      vibrationEnabled: prefs.getBool(_keyVibration) ?? true,
      minimalMode: prefs.getBool(_keyMinimal) ?? false,
      alcoholPenaltyEnabled: prefs.getBool(_keyAlcoholPenalty) ?? true,
      defaultPenaltyCountry:
          _decodeCountry(prefs.getString(_keyPenaltyCountry)),
      defaultPenaltyDifficulty:
          _decodeDifficulty(prefs.getString(_keyPenaltyDifficulty)),
      defaultPenaltyScale: _decodeScale(prefs.getString(_keyPenaltyScale)),
      defaultPenaltySelectionMode:
          _decodeSelectionMode(prefs.getString(_keyPenaltySelectionMode)),
    );
    _applySettings(settings);
    return settings;
  }

  void _applySettings(AppSettings s) {
    AudioService.setEnabled(s.soundEnabled);
    HapticService.setEnabled(s.vibrationEnabled);
  }

  Future<void> toggleSound() async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(soundEnabled: !current.soundEnabled);
    await _save(updated);
    state = AsyncData(updated);
    _applySettings(updated);
  }

  Future<void> toggleVibration() async {
    final current = state.value ?? const AppSettings();
    final updated =
        current.copyWith(vibrationEnabled: !current.vibrationEnabled);
    await _save(updated);
    state = AsyncData(updated);
    _applySettings(updated);
  }

  Future<void> toggleMinimalMode() async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(minimalMode: !current.minimalMode);
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> toggleAlcoholPenalty() async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(
      alcoholPenaltyEnabled: !current.alcoholPenaltyEnabled,
    );
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> setPenaltyCountry(PenaltyCountry country) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(defaultPenaltyCountry: country);
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> setPenaltyDifficulty(PenaltyDifficulty difficulty) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(defaultPenaltyDifficulty: difficulty);
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> setPenaltyScale(PenaltyScale scale) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(defaultPenaltyScale: scale);
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> setPenaltySelectionMode(PenaltySelectionMode mode) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(defaultPenaltySelectionMode: mode);
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> _save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, s.soundEnabled);
    await prefs.setBool(_keyVibration, s.vibrationEnabled);
    await prefs.setBool(_keyMinimal, s.minimalMode);
    await prefs.setBool(_keyAlcoholPenalty, s.alcoholPenaltyEnabled);
    await prefs.setString(_keyPenaltyCountry, s.defaultPenaltyCountry.name);
    await prefs.setString(
        _keyPenaltyDifficulty, s.defaultPenaltyDifficulty.name);
    await prefs.setString(_keyPenaltyScale, s.defaultPenaltyScale.name);
    await prefs.setString(
      _keyPenaltySelectionMode,
      s.defaultPenaltySelectionMode.name,
    );
  }
}

PenaltyCountry _decodeCountry(String? raw) {
  if (raw == null) return PenaltyCountry.cn;
  return PenaltyCountry.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => PenaltyCountry.cn,
  );
}

PenaltyDifficulty _decodeDifficulty(String? raw) {
  if (raw == null) return PenaltyDifficulty.normal;
  return PenaltyDifficulty.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => PenaltyDifficulty.normal,
  );
}

PenaltyScale _decodeScale(String? raw) {
  if (raw == null) return PenaltyScale.medium;
  return PenaltyScale.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => PenaltyScale.medium,
  );
}

PenaltySelectionMode _decodeSelectionMode(String? raw) {
  if (raw == null) return PenaltySelectionMode.random;
  return PenaltySelectionMode.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => PenaltySelectionMode.random,
  );
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
