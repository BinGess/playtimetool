import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../core/audio/audio_service.dart';

class AppSettings {
  const AppSettings({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.minimalMode = false,
    this.alcoholPenaltyEnabled = true,
    this.iapPaywallEnabled = false,
  });

  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool minimalMode;
  final bool alcoholPenaltyEnabled;
  final bool iapPaywallEnabled;

  AppSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? minimalMode,
    bool? alcoholPenaltyEnabled,
    bool? iapPaywallEnabled,
  }) {
    return AppSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      minimalMode: minimalMode ?? this.minimalMode,
      alcoholPenaltyEnabled:
          alcoholPenaltyEnabled ?? this.alcoholPenaltyEnabled,
      iapPaywallEnabled: iapPaywallEnabled ?? this.iapPaywallEnabled,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _keySound = 'soundEnabled';
  static const _keyVibration = 'vibrationEnabled';
  static const _keyMinimal = 'minimalMode';
  static const _keyAlcoholPenalty = 'alcoholPenaltyEnabled';
  static const _keyIapPaywallEnabled = 'iapPaywallEnabled';

  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = AppSettings(
      soundEnabled: prefs.getBool(_keySound) ?? true,
      vibrationEnabled: prefs.getBool(_keyVibration) ?? true,
      minimalMode: prefs.getBool(_keyMinimal) ?? false,
      alcoholPenaltyEnabled: prefs.getBool(_keyAlcoholPenalty) ?? true,
      iapPaywallEnabled: prefs.getBool(_keyIapPaywallEnabled) ?? false,
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

  Future<void> toggleIapPaywallEnabled() async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(
      iapPaywallEnabled: !current.iapPaywallEnabled,
    );
    await _save(updated);
    state = AsyncData(updated);
  }

  Future<void> _save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, s.soundEnabled);
    await prefs.setBool(_keyVibration, s.vibrationEnabled);
    await prefs.setBool(_keyMinimal, s.minimalMode);
    await prefs.setBool(_keyAlcoholPenalty, s.alcoholPenaltyEnabled);
    await prefs.setBool(_keyIapPaywallEnabled, s.iapPaywallEnabled);
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
