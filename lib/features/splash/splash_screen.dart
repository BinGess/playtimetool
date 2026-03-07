import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/neon_text.dart';
import '../../shared/widgets/web3_game_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _displayDuration = Duration(seconds: 1);
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(_displayDuration, () {
      if (!mounted) return;
      context.go('/home');
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Web3GameBackground(
            accentColor: AppColors.fingerCyan,
            secondaryColor: AppColors.wheelOrange,
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.88, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value.clamp(0, 1),
                      child: Transform.scale(
                        scale: value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SplashLogo(),
                      const SizedBox(height: 24),
                      NeonText(
                        l10n.appTitle,
                        color: AppColors.fingerCyan,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        glowRadius: 18,
                        letterSpacing: 2.6,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.appSlogan,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary.withAlpha(220),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
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

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                width: 116,
                height: 116,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x6600FFFF),
                      Color(0x1A00FFFF),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 24,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x55FF6B35),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 28,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x4000FFFF),
                ),
              ),
            ),
          ),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.celebration_rounded,
                    color: AppColors.textPrimary,
                    size: 64,
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
