import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/glass_container.dart';
import 'providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(
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
              label: '音效',
              sublabel: 'SOUND',
              value: settings.soundEnabled,
              accentColor: AppColors.fingerCyan,
              onToggle: () =>
                  ref.read(settingsProvider.notifier).toggleSound(),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              label: '震动',
              sublabel: 'VIBRATION',
              value: settings.vibrationEnabled,
              accentColor: AppColors.wheelOrange,
              onToggle: () =>
                  ref.read(settingsProvider.notifier).toggleVibration(),
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              label: '极简模式',
              sublabel: 'MINIMAL MODE',
              value: settings.minimalMode,
              accentColor: AppColors.bombRed,
              onToggle: () =>
                  ref.read(settingsProvider.notifier).toggleMinimalMode(),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '聚会游戏精选 v1.0',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
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
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
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
