import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyLocale = 'locale';

/// 当前应用语言
/// - null: 跟随系统
/// - Locale('zh'): 中文
/// - Locale('en'): 英文
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_keyLocale);
    if (code == null || code == 'system') {
      state = null;
    } else {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString(_keyLocale, 'system');
    } else {
      await prefs.setString(_keyLocale, locale.languageCode);
    }
  }

  void followSystem() => setLocale(null);
  void setChinese() => setLocale(const Locale('zh'));
  void setEnglish() => setLocale(const Locale('en'));
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (ref) => LocaleNotifier(),
);

/// 实际使用的 Locale（考虑系统语言）
Locale localeResolver(Locale? override, List<Locale> systemLocales) {
  if (override != null) return override;
  for (final l in systemLocales) {
    if (l.languageCode == 'zh') return const Locale('zh');
    if (l.languageCode == 'en') return const Locale('en');
  }
  return const Locale('en');
}
