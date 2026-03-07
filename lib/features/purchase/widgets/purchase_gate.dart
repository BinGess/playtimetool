import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/styles/game_ui_style.dart';
import '../../../shared/widgets/game_top_bar.dart';
import '../../../shared/widgets/web3_game_background.dart';
import '../iap_purchase_provider.dart';
import '../purchase_catalog.dart';

enum _PurchaseGateAction { buy, restore }

class PurchaseGate extends ConsumerStatefulWidget {
  const PurchaseGate({
    super.key,
    required this.route,
    required this.gameTitleKey,
    required this.accentColor,
    required this.child,
  });

  final String route;
  final String gameTitleKey;
  final Color accentColor;
  final Widget child;

  @override
  ConsumerState<PurchaseGate> createState() => _PurchaseGateState();
}

class _PurchaseGateState extends ConsumerState<PurchaseGate> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gameTitle = l10n.t(widget.gameTitleKey);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final purchaseState = ref.watch(iapPurchaseProvider);
    final productId = PurchaseCatalog.routeToProductId[widget.route];

    if (!settings.iapPaywallEnabled ||
        productId == null ||
        purchaseState.isUnlocked(productId)) {
      return widget.child;
    }

    final priceText = purchaseState.productById(productId)?.price ??
        l10n.t('iapPriceFallback');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Web3GameBackground(
            accentColor: widget.accentColor,
            secondaryColor: const Color(0xFFFF6B6B),
          ),
          SafeArea(
            child: Padding(
              padding: GameUiSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GameTopBar(
                    title: gameTitle,
                    onBack: () => context.pop(),
                    accentColor: widget.accentColor,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: GameUiSurface.heroPanel(
                      accentColor: widget.accentColor,
                      secondaryColor: const Color(0xFFFF6B6B),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(84),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha(48),
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_open_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.t('iapLockedHeroTitle'),
                          textAlign: TextAlign.center,
                          style: GameUiText.sectionTitle.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.t('iapPurchaseBody', {
                            'game': gameTitle,
                            'price': priceText,
                          }),
                          textAlign: TextAlign.center,
                          style: GameUiText.body.copyWith(
                            color: const Color(0xFFD8E6FF),
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _BenefitChip(
                              label: l10n.t('iapBenefitPermanentUnlock'),
                            ),
                            _BenefitChip(
                              label: l10n.t('iapBenefitRestoreSupport'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(110),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: widget.accentColor.withAlpha(90),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sell_rounded,
                                color: widget.accentColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.t('iapPermanentPriceTag', {
                                  'price': priceText,
                                }),
                                style: GameUiText.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: GameUiSpacing.buttonHeight,
                          child: ElevatedButton(
                            onPressed: purchaseState.isBusy
                                ? null
                                : () => _requestPurchase(
                                      context,
                                      productId,
                                      _PurchaseGateAction.buy,
                                    ),
                            style: GameUiSurface.primaryButton(
                              widget.accentColor,
                            ),
                            child: Text(
                              purchaseState.isBusy
                                  ? l10n.t('iapPurchasePending')
                                  : l10n.t('iapBuyNow'),
                              style: GameUiText.buttonLabel.copyWith(
                                color: GameUiSurface.foregroundOn(
                                    widget.accentColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: purchaseState.isBusy
                              ? null
                              : () => _requestPurchase(
                                    context,
                                    productId,
                                    _PurchaseGateAction.restore,
                                  ),
                          child: Text(l10n.t('iapRestore')),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPurchase(
    BuildContext context,
    String productId,
    _PurchaseGateAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(iapPurchaseProvider.notifier);
    final result = action == _PurchaseGateAction.buy
        ? await notifier.buyProduct(productId)
        : await notifier.restorePurchases();

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case PurchaseRequestResult.started:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.t('iapPurchasePending')),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      case PurchaseRequestResult.storeUnavailable:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.t('iapStoreUnavailable')),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      case PurchaseRequestResult.productNotFound:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.t('iapProductNotFound')),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      case PurchaseRequestResult.failed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.t('iapPurchaseFailed')),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
    }
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha(34)),
      ),
      child: Text(
        label,
        style: GameUiText.caption.copyWith(color: Colors.white),
      ),
    );
  }
}
