import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/sensors/gyroscope_service.dart';
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
    final gyroAsync = ref.watch(gyroscopeProvider);
    final gyroX = gyroAsync.value?.x ?? 0.0;
    final gyroY = gyroAsync.value?.y ?? 0.0;

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
                const Text(
                  '聚会游戏精选',
                  style: TextStyle(
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
                    children: const [
                      GameCard(
                        title: '指尖轮盘',
                        subtitle: 'FINGER PICKER',
                        description: '命运的触碰',
                        accentColor: AppColors.fingerCyan,
                        route: '/finger',
                        icon: Icons.fingerprint,
                      ),
                      GameCard(
                        title: '自定义转盘',
                        subtitle: 'SPIN WHEEL',
                        description: '丝滑的物理感',
                        accentColor: AppColors.wheelOrange,
                        route: '/wheel',
                        icon: Icons.rotate_right,
                      ),
                      GameCard(
                        title: '数字炸弹',
                        subtitle: 'NUMBER BOMB',
                        description: '心理压迫感',
                        accentColor: AppColors.bombRed,
                        route: '/bomb',
                        icon: Icons.bolt,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Page dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final active = i == _currentPage;
                    final colors = [
                      AppColors.fingerCyan,
                      AppColors.wheelOrange,
                      AppColors.bombRed,
                    ];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: active
                            ? colors[i]
                            : AppColors.textDim,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: colors[i].withAlpha(120),
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
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '⚙  SETTINGS',
                      style: TextStyle(
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
