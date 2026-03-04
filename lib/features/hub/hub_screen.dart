import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/sensors/gyroscope_service.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/game_card.dart';

class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  final _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gyroAsync = ref.watch(gyroscopeProvider);
    final gyroX = gyroAsync.value?.x ?? 0.0;
    final gyroY = gyroAsync.value?.y ?? 0.0;
    final games = _games(l10n);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle grid background with parallax
          _ParallaxGrid(offsetX: gyroX * 6, offsetY: gyroY * 6),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Title
                Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 40),

                // Game cards
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: games
                        .map(
                          (g) => GameCard(
                            title: g.title,
                            subtitle: g.subtitle,
                            description: g.description,
                            accentColor: g.accentColor,
                            route: g.route,
                            icon: g.icon,
                          ),
                        )
                        .toList(),
                  ),
                ),

                const SizedBox(height: 24),
                // Page dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(games.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color:
                            active ? games[i].accentColor : AppColors.textDim,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: games[i].accentColor.withAlpha(120),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),
                // Settings link
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '⚙  ${l10n.settingsTitle}',
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_HubGameItem> _games(AppLocalizations l10n) {
    return [
      _HubGameItem(
        title: l10n.fingerPicker,
        subtitle: l10n.fingerPickerSub,
        description: l10n.fingerPickerDesc,
        accentColor: AppColors.fingerCyan,
        route: '/finger',
        icon: Icons.fingerprint,
      ),
      _HubGameItem(
        title: l10n.spinWheel,
        subtitle: l10n.spinWheelSub,
        description: l10n.spinWheelDesc,
        accentColor: AppColors.wheelOrange,
        route: '/wheel',
        icon: Icons.rotate_right,
      ),
      _HubGameItem(
        title: l10n.numberBomb,
        subtitle: l10n.numberBombSub,
        description: l10n.numberBombDesc,
        accentColor: AppColors.bombRed,
        route: '/bomb',
        icon: Icons.bolt,
      ),
      _HubGameItem(
        title: l10n.t('passBomb'),
        subtitle: l10n.t('passBombSub'),
        description: l10n.t('passBombDesc'),
        accentColor: const Color(0xFFFF4757),
        route: '/games/pass-bomb',
        icon: Icons.local_fire_department,
      ),
      _HubGameItem(
        title: l10n.t('gestureDuel'),
        subtitle: l10n.t('gestureDuelSub'),
        description: l10n.t('gestureDuelDesc'),
        accentColor: const Color(0xFF00E5FF),
        route: '/games/gesture-duel',
        icon: Icons.sports_mma,
      ),
      _HubGameItem(
        title: l10n.t('leftRight'),
        subtitle: l10n.t('leftRightSub'),
        description: l10n.t('leftRightDesc'),
        accentColor: const Color(0xFFFFA726),
        route: '/games/left-right',
        icon: Icons.compare_arrows,
      ),
      _HubGameItem(
        title: l10n.t('wordBomb'),
        subtitle: l10n.t('wordBombSub'),
        description: l10n.t('wordBombDesc'),
        accentColor: const Color(0xFF00E676),
        route: '/games/word-bomb',
        icon: Icons.record_voice_over,
      ),
      _HubGameItem(
        title: l10n.t('challengeAuction'),
        subtitle: l10n.t('challengeAuctionSub'),
        description: l10n.t('challengeAuctionDesc'),
        accentColor: const Color(0xFFFFB300),
        route: '/games/challenge-auction',
        icon: Icons.gavel,
      ),
      _HubGameItem(
        title: l10n.t('truthRaise'),
        subtitle: l10n.t('truthRaiseSub'),
        description: l10n.t('truthRaiseDesc'),
        accentColor: const Color(0xFFFF5252),
        route: '/games/truth-raise',
        icon: Icons.question_answer,
      ),
    ];
  }
}

class _HubGameItem {
  const _HubGameItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    required this.route,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String description;
  final Color accentColor;
  final String route;
  final IconData icon;
}

/// Subtle dot-grid that shifts slightly with gyroscope.
class _ParallaxGrid extends StatelessWidget {
  const _ParallaxGrid({required this.offsetX, required this.offsetY});

  final double offsetX;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
