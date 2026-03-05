import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/locale/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_container.dart';
import '../penalty_plugin/domain/penalty_models.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final localeOverride = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(
            letterSpacing: 3,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _SettingsTile(
              label: l10n.sound,
              sublabel: l10n.soundSub,
              value: settings.soundEnabled,
              accentColor: AppColors.fingerCyan,
              onToggle: () => ref.read(settingsProvider.notifier).toggleSound(),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              label: l10n.vibration,
              sublabel: l10n.vibrationSub,
              value: settings.vibrationEnabled,
              accentColor: AppColors.wheelOrange,
              onToggle: () =>
                  ref.read(settingsProvider.notifier).toggleVibration(),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              label: l10n.minimalMode,
              sublabel: l10n.minimalModeSub,
              value: settings.minimalMode,
              accentColor: AppColors.bombRed,
              onToggle: () =>
                  ref.read(settingsProvider.notifier).toggleMinimalMode(),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              label: l10n.alcoholPenalty,
              sublabel: l10n.alcoholPenaltySub,
              value: settings.alcoholPenaltyEnabled,
              accentColor: AppColors.wheelOrange,
              onToggle: () =>
                  ref.read(settingsProvider.notifier).toggleAlcoholPenalty(),
            ),
            const SizedBox(height: 12),
            _LanguageTile(
              label: l10n.t('penaltyCountry'),
              sublabel: l10n.t('penaltyCountrySub'),
              value: _countryLabel(l10n, settings.defaultPenaltyCountry),
              onTap: () => _showPenaltyCountrySheet(context, ref, settings),
            ),
            const SizedBox(height: 12),
            _LanguageTile(
              label: l10n.t('penaltyDifficulty'),
              sublabel: l10n.t('penaltyDifficultySub'),
              value: _difficultyLabel(
                l10n,
                settings.defaultPenaltyDifficulty,
              ),
              onTap: () => _showPenaltyDifficultySheet(context, ref, settings),
            ),
            const SizedBox(height: 12),
            _LanguageTile(
              label: l10n.t('penaltyScale'),
              sublabel: l10n.t('penaltyScaleSub'),
              value: _scaleLabel(l10n, settings.defaultPenaltyScale),
              onTap: () => _showPenaltyScaleSheet(context, ref, settings),
            ),
            const SizedBox(height: 12),
            _LanguageTile(
              label: l10n.t('penaltySelectionMode'),
              sublabel: l10n.t('penaltySelectionModeSub'),
              value: _selectionModeLabel(
                l10n,
                settings.defaultPenaltySelectionMode,
              ),
              onTap: () =>
                  _showPenaltySelectionModeSheet(context, ref, settings),
            ),
            const SizedBox(height: 12),
            _LanguageTile(
              label: l10n.language,
              sublabel: l10n.languageSub,
              localeOverride: localeOverride,
              onTap: () => _showLanguageSheet(context, ref),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/settings/about'),
              child: GlassContainer(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                borderColor: AppColors.glassBorder,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.about,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.aboutSub,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textDim, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                l10n.appVersion,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(localeProvider.notifier);
    final current = ref.read(localeProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                l10n.language,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              _LangOption(
                label: l10n.langFollowSystem,
                active: current == null,
                onTap: () {
                  notifier.followSystem();
                  Navigator.pop(ctx);
                },
              ),
              _LangOption(
                label: l10n.langChinese,
                active: current?.languageCode == 'zh',
                onTap: () {
                  notifier.setChinese();
                  Navigator.pop(ctx);
                },
              ),
              _LangOption(
                label: l10n.langEnglish,
                active: current?.languageCode == 'en',
                onTap: () {
                  notifier.setEnglish();
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _countryLabel(AppLocalizations l10n, PenaltyCountry value) {
    switch (value) {
      case PenaltyCountry.cn:
        return l10n.t('penaltyCountryCn');
      case PenaltyCountry.us:
        return l10n.t('penaltyCountryUs');
    }
  }

  String _difficultyLabel(AppLocalizations l10n, PenaltyDifficulty value) {
    switch (value) {
      case PenaltyDifficulty.easy:
        return l10n.t('penaltyDifficultyEasy');
      case PenaltyDifficulty.normal:
        return l10n.t('penaltyDifficultyNormal');
      case PenaltyDifficulty.hard:
        return l10n.t('penaltyDifficultyHard');
    }
  }

  String _scaleLabel(AppLocalizations l10n, PenaltyScale value) {
    switch (value) {
      case PenaltyScale.light:
        return l10n.t('penaltyScaleLight');
      case PenaltyScale.medium:
        return l10n.t('penaltyScaleMedium');
      case PenaltyScale.wild:
        return l10n.t('penaltyScaleWild');
    }
  }

  String _selectionModeLabel(
    AppLocalizations l10n,
    PenaltySelectionMode value,
  ) {
    switch (value) {
      case PenaltySelectionMode.manual:
        return l10n.t('penaltySelectionManual');
      case PenaltySelectionMode.random:
        return l10n.t('penaltySelectionRandom');
    }
  }

  void _showPenaltyCountrySheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final l10n = AppLocalizations.of(context);
    _showSelectionSheet<PenaltyCountry>(
      context: context,
      title: l10n.t('penaltyCountry'),
      options: [
        _SelectionOption(
          value: PenaltyCountry.cn,
          label: l10n.t('penaltyCountryCn'),
        ),
        _SelectionOption(
          value: PenaltyCountry.us,
          label: l10n.t('penaltyCountryUs'),
        ),
      ],
      selected: settings.defaultPenaltyCountry,
      onSelect: (value) =>
          ref.read(settingsProvider.notifier).setPenaltyCountry(value),
    );
  }

  void _showPenaltyDifficultySheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final l10n = AppLocalizations.of(context);
    _showSelectionSheet<PenaltyDifficulty>(
      context: context,
      title: l10n.t('penaltyDifficulty'),
      options: [
        _SelectionOption(
          value: PenaltyDifficulty.easy,
          label: l10n.t('penaltyDifficultyEasy'),
        ),
        _SelectionOption(
          value: PenaltyDifficulty.normal,
          label: l10n.t('penaltyDifficultyNormal'),
        ),
        _SelectionOption(
          value: PenaltyDifficulty.hard,
          label: l10n.t('penaltyDifficultyHard'),
        ),
      ],
      selected: settings.defaultPenaltyDifficulty,
      onSelect: (value) =>
          ref.read(settingsProvider.notifier).setPenaltyDifficulty(value),
    );
  }

  void _showPenaltyScaleSheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final l10n = AppLocalizations.of(context);
    _showSelectionSheet<PenaltyScale>(
      context: context,
      title: l10n.t('penaltyScale'),
      options: [
        _SelectionOption(
          value: PenaltyScale.light,
          label: l10n.t('penaltyScaleLight'),
        ),
        _SelectionOption(
          value: PenaltyScale.medium,
          label: l10n.t('penaltyScaleMedium'),
        ),
        _SelectionOption(
          value: PenaltyScale.wild,
          label: l10n.t('penaltyScaleWild'),
        ),
      ],
      selected: settings.defaultPenaltyScale,
      onSelect: (value) =>
          ref.read(settingsProvider.notifier).setPenaltyScale(value),
    );
  }

  void _showPenaltySelectionModeSheet(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final l10n = AppLocalizations.of(context);
    _showSelectionSheet<PenaltySelectionMode>(
      context: context,
      title: l10n.t('penaltySelectionMode'),
      options: [
        _SelectionOption(
          value: PenaltySelectionMode.manual,
          label: l10n.t('penaltySelectionManual'),
        ),
        _SelectionOption(
          value: PenaltySelectionMode.random,
          label: l10n.t('penaltySelectionRandom'),
        ),
      ],
      selected: settings.defaultPenaltySelectionMode,
      onSelect: (value) =>
          ref.read(settingsProvider.notifier).setPenaltySelectionMode(value),
    );
  }

  void _showSelectionSheet<T>({
    required BuildContext context,
    required String title,
    required List<_SelectionOption<T>> options,
    required T selected,
    required Future<void> Function(T value) onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              ...options.map(
                (option) => ListTile(
                  title: Text(
                    option.label,
                    style: TextStyle(
                      color: option.value == selected
                          ? AppColors.fingerCyan
                          : AppColors.textPrimary,
                      fontWeight: option.value == selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: option.value == selected
                      ? const Icon(
                          Icons.check,
                          color: AppColors.fingerCyan,
                          size: 20,
                        )
                      : null,
                  onTap: () async {
                    await onSelect(option.value);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionOption<T> {
  const _SelectionOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class _LangOption extends StatelessWidget {
  const _LangOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.fingerCyan : AppColors.textPrimary,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: active
          ? const Icon(Icons.check, color: AppColors.fingerCyan, size: 20)
          : null,
      onTap: onTap,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.sublabel,
    this.localeOverride,
    this.value,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final Locale? localeOverride;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String value;
    if (this.value != null) {
      value = this.value!;
    } else if (localeOverride == null) {
      value = l10n.langFollowSystem;
    } else if (localeOverride?.languageCode == 'zh') {
      value = l10n.langChinese;
    } else {
      value = l10n.langEnglish;
    }

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderColor: AppColors.glassBorder,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.accentColor,
    required this.onToggle,
  });

  final String label;
  final String sublabel;
  final bool value;
  final Color accentColor;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderColor: value ? accentColor.withAlpha(80) : AppColors.glassBorder,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: value ? accentColor : AppColors.surface,
                border: Border.all(
                  color: value ? accentColor : AppColors.textDim,
                  width: 1,
                ),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: accentColor.withAlpha(80),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value ? Colors.black : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
