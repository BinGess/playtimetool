import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/locale/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_container.dart';
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
            if (kDebugMode) ...[
              _SettingsTile(
                label: l10n.t('iapPaywallSwitch'),
                sublabel: l10n.t('iapPaywallSwitchSub'),
                value: settings.iapPaywallEnabled,
                accentColor: AppColors.bombRed,
                onToggle: () => ref
                    .read(settingsProvider.notifier)
                    .toggleIapPaywallEnabled(),
              ),
              const SizedBox(height: 12),
            ],
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
              _LangOption(
                label: l10n.langJapanese,
                active: current?.languageCode == 'ja',
                onTap: () {
                  notifier.setJapanese();
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
    required this.localeOverride,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final Locale? localeOverride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String value;
    if (localeOverride == null) {
      value = l10n.langFollowSystem;
    } else if (localeOverride!.languageCode == 'zh') {
      value = l10n.langChinese;
    } else if (localeOverride?.languageCode == 'ja') {
      value = l10n.langJapanese;
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
