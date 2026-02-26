import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_container.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String _privacyUrl =
      'https://lucky-geranium-802.notion.site/Privacy-Policy-313407f7a70180f19468caf40f8ddba6?source=copy_link';
  static const String _contactEmail = 'baibin1989@foxmail.com';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDim, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.aboutSub,
          style: const TextStyle(
            letterSpacing: 3,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              l10n.appTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.appVersion,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          const SizedBox(height: 48),
          _LinkTile(
            icon: Icons.privacy_tip_outlined,
            label: l10n.privacyPolicy,
            onTap: () => launchUrl(
              Uri.parse(_privacyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 12),
          _LinkTile(
            icon: Icons.email_outlined,
            label: l10n.contact,
            subtitle: _contactEmail,
            onTap: () => launchUrl(Uri.parse('mailto:$_contactEmail')),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderColor: AppColors.glassBorder,
        child: Row(
          children: [
            Icon(icon, color: AppColors.fingerCyan, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textDim, size: 20),
          ],
        ),
      ),
    );
  }
}
