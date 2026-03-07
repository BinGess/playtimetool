import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/sensors/gyroscope_service.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../purchase/iap_purchase_provider.dart';
import '../purchase/purchase_catalog.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/game_top_bar.dart';
import 'widgets/game_card.dart';

enum _PremiumDialogAction { buy, restore }

class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends ConsumerState<HubScreen> {
  String? _pendingUnlockProductId;
  String? _pendingUnlockRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gyroAsync = ref.watch(gyroscopeProvider);
    final purchaseState = ref.watch(iapPurchaseProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final paywallEnabled = settings.iapPaywallEnabled;
    final gyroX = gyroAsync.value?.x ?? 0.0;
    final gyroY = gyroAsync.value?.y ?? 0.0;
    final games = _games(l10n);

    ref.listen(iapPurchaseProvider, (prev, next) {
      final pendingProduct = _pendingUnlockProductId;
      final pendingRoute = _pendingUnlockRoute;
      if (pendingProduct != null &&
          pendingRoute != null &&
          next.isUnlocked(pendingProduct)) {
        _pendingUnlockProductId = null;
        _pendingUnlockRoute = null;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.t('iapUnlockSuccess',
                  {'game': _titleByRoute(pendingRoute, l10n)}),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        context.push(pendingRoute);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle grid background with parallax
          _ParallaxGrid(offsetX: gyroX * 6, offsetY: gyroY * 6),

          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 12),
                    GameTopBar(
                      title: l10n.appTitle,
                      trailing: GameIconButton(
                        key: const Key('hub-settings-button'),
                        onPressed: () => context.push('/settings'),
                        tooltip: l10n.settings,
                        icon: Icons.settings_rounded,
                        accentColor: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.84,
                        ),
                        itemCount: games.length,
                        itemBuilder: (_, i) {
                          final g = games[i];
                          final productId =
                              PurchaseCatalog.routeToProductId[g.route];
                          final locked = paywallEnabled &&
                              productId != null &&
                              !purchaseState.isUnlocked(productId);
                          final lockBadgeText = locked
                              ? (purchaseState.productById(productId)?.price ??
                                  l10n.t('iapPriceFallback'))
                              : null;
                          return GameCard(
                            title: g.title,
                            subtitle: g.subtitle,
                            description: g.description,
                            accentColor: g.accentColor,
                            route: g.route,
                            icon: g.icon,
                            locked: locked,
                            lockBadgeText: lockBadgeText,
                            onTap: () => _handleGameTap(g, l10n),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGameTap(_HubGameItem game, AppLocalizations l10n) async {
    final paywallEnabled =
        (ref.read(settingsProvider).value ?? const AppSettings())
            .iapPaywallEnabled;
    if (!paywallEnabled) {
      context.push(game.route);
      return;
    }

    final productId = PurchaseCatalog.routeToProductId[game.route];
    if (productId == null) {
      context.push(game.route);
      return;
    }

    final purchaseState = ref.read(iapPurchaseProvider);
    if (purchaseState.isUnlocked(productId)) {
      context.push(game.route);
      return;
    }

    final action = await _showPurchaseDialog(
      game: game,
      l10n: l10n,
      priceText: purchaseState.productById(productId)?.price ??
          l10n.t('iapPriceFallback'),
    );
    if (action == null || !mounted) return;

    _pendingUnlockProductId = productId;
    _pendingUnlockRoute = game.route;

    final notifier = ref.read(iapPurchaseProvider.notifier);
    final result = action == _PremiumDialogAction.buy
        ? await notifier.buyProduct(productId)
        : await notifier.restorePurchases();

    if (!mounted) return;
    switch (result) {
      case PurchaseRequestResult.started:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('iapPurchasePending')),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      case PurchaseRequestResult.storeUnavailable:
        _clearPendingUnlock();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('iapStoreUnavailable')),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      case PurchaseRequestResult.productNotFound:
        _clearPendingUnlock();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('iapProductNotFound')),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      case PurchaseRequestResult.failed:
        _clearPendingUnlock();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('iapPurchaseFailed')),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }

  void _clearPendingUnlock() {
    _pendingUnlockProductId = null;
    _pendingUnlockRoute = null;
  }

  Future<_PremiumDialogAction?> _showPurchaseDialog({
    required _HubGameItem game,
    required AppLocalizations l10n,
    required String priceText,
  }) {
    return showDialog<_PremiumDialogAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.textDim.withAlpha(100)),
        ),
        title: Text(
          l10n.t('iapPurchaseTitle'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.t('iapPurchaseBody', {
            'game': game.title,
            'price': priceText,
          }),
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _PremiumDialogAction.restore),
            child: Text(l10n.t('iapRestore')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _PremiumDialogAction.buy),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wheelOrange,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.t('iapBuyNow')),
          ),
        ],
      ),
    );
  }

  String _titleByRoute(String route, AppLocalizations l10n) {
    return _games(l10n)
        .firstWhere(
          (g) => g.route == route,
          orElse: () => _HubGameItem(
            title: route,
            subtitle: '',
            description: '',
            accentColor: Colors.white,
            route: route,
            icon: Icons.lock,
          ),
        )
        .title;
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
        accentColor: const Color(0xFFFF4FA3),
        route: '/games/pass-bomb',
        icon: Icons.local_fire_department,
      ),
      _HubGameItem(
        title: l10n.t('leftRight'),
        subtitle: l10n.t('leftRightSub'),
        description: l10n.t('leftRightDesc'),
        accentColor: const Color(0xFF5B8CFF),
        route: '/games/left-right',
        icon: Icons.compare_arrows,
      ),
      _HubGameItem(
        title: l10n.t('bioDetector'),
        subtitle: l10n.t('bioDetectorSub'),
        description: l10n.t('bioDetectorDesc'),
        accentColor: const Color(0xFF43E97B),
        route: '/games/bio-detector',
        icon: Icons.monitor_heart,
      ),
      _HubGameItem(
        title: l10n.t('decibelBomb'),
        subtitle: l10n.t('decibelBombSub'),
        description: l10n.t('decibelBombDesc'),
        accentColor: const Color(0xFF9B6BFF),
        route: '/games/decibel-bomb',
        icon: Icons.graphic_eq,
      ),
      _HubGameItem(
        title: l10n.t('gravityBalance'),
        subtitle: l10n.t('gravityBalanceSub'),
        description: l10n.t('gravityBalanceDesc'),
        accentColor: const Color(0xFF7DFF7A),
        route: '/games/gravity-balance',
        icon: Icons.timeline,
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
