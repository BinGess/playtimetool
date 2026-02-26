import 'package:flutter/services.dart';

/// Centralized haptic feedback service.
/// Thin wrapper over Flutter's built-in HapticFeedback.
/// iOS maps to Core Haptics; Android uses VibrationEffect (API 26+).
abstract final class HapticService {
  static bool _enabled = true;

  static void setEnabled(bool enabled) => _enabled = enabled;

  static void selectionClick() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  static void lightImpact() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  static void notificationSuccess() {
    if (!_enabled) return;
    // Simulate success via medium impact on both platforms
    HapticFeedback.mediumImpact();
  }

  static void notificationWarning() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  static void errorVibrate() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }

  /// Triple heavy impact with 120ms gap — simulates explosion.
  static Future<void> tripleHeavyImpact() async {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.heavyImpact();
  }

  /// Pulse vibration for critical warning (range ≤ 3 in bomb game).
  static Future<void> pulseCritical({int pulses = 3}) async {
    if (!_enabled) return;
    for (int i = 0; i < pulses; i++) {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
}
