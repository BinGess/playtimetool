import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_catalog.dart';

enum PurchaseRequestResult {
  started,
  storeUnavailable,
  productNotFound,
  failed,
}

class IapPurchaseState {
  const IapPurchaseState({
    this.initialized = false,
    this.storeAvailable = false,
    this.isBusy = false,
    this.productsById = const {},
    this.unlockedProductIds = const {},
  });

  final bool initialized;
  final bool storeAvailable;
  final bool isBusy;
  final Map<String, ProductDetails> productsById;
  final Set<String> unlockedProductIds;

  bool isUnlocked(String productId) => unlockedProductIds.contains(productId);

  ProductDetails? productById(String productId) => productsById[productId];

  IapPurchaseState copyWith({
    bool? initialized,
    bool? storeAvailable,
    bool? isBusy,
    Map<String, ProductDetails>? productsById,
    Set<String>? unlockedProductIds,
  }) {
    return IapPurchaseState(
      initialized: initialized ?? this.initialized,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      isBusy: isBusy ?? this.isBusy,
      productsById: productsById ?? this.productsById,
      unlockedProductIds: unlockedProductIds ?? this.unlockedProductIds,
    );
  }
}

class IapPurchaseNotifier extends StateNotifier<IapPurchaseState> {
  IapPurchaseNotifier() : super(const IapPurchaseState()) {
    _init();
  }

  static const _prefsKeyUnlockedProducts = 'iap_unlocked_product_ids';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<void> _init() async {
    try {
      final unlocked = await _loadUnlockedProductIds();
      final available = await _iap.isAvailable();
      Map<String, ProductDetails> products = const {};

      if (available) {
        final response =
            await _iap.queryProductDetails(PurchaseCatalog.productIds);
        products = {
          for (final p in response.productDetails) p.id: p,
        };
      }

      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onDone: () => _purchaseSub?.cancel(),
        onError: (_) {
          state = state.copyWith(isBusy: false);
        },
      );

      state = state.copyWith(
        initialized: true,
        storeAvailable: available,
        productsById: products,
        unlockedProductIds: unlocked,
      );
    } catch (_) {
      state = state.copyWith(
        initialized: true,
        storeAvailable: false,
        isBusy: false,
      );
    }
  }

  Future<PurchaseRequestResult> buyProduct(String productId) async {
    try {
      if (!state.storeAvailable) return PurchaseRequestResult.storeUnavailable;

      final details = state.productsById[productId];
      if (details == null) return PurchaseRequestResult.productNotFound;

      state = state.copyWith(isBusy: true);

      final accepted = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );

      if (!accepted) {
        state = state.copyWith(isBusy: false);
        return PurchaseRequestResult.failed;
      }

      return PurchaseRequestResult.started;
    } catch (_) {
      state = state.copyWith(isBusy: false);
      return PurchaseRequestResult.failed;
    }
  }

  Future<PurchaseRequestResult> restorePurchases() async {
    try {
      if (!state.storeAvailable) return PurchaseRequestResult.storeUnavailable;
      state = state.copyWith(isBusy: true);

      await _iap.restorePurchases();

      // restorePurchases might not emit updates when there is nothing to restore.
      // Keep the UI responsive by clearing the busy flag after dispatch.
      state = state.copyWith(isBusy: false);
      return PurchaseRequestResult.started;
    } catch (_) {
      state = state.copyWith(isBusy: false);
      return PurchaseRequestResult.failed;
    }
  }

  Future<void> refreshProducts() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        state = state.copyWith(storeAvailable: false);
        return;
      }

      final response =
          await _iap.queryProductDetails(PurchaseCatalog.productIds);
      state = state.copyWith(
        storeAvailable: true,
        productsById: {
          for (final p in response.productDetails) p.id: p,
        },
      );
    } catch (_) {
      state = state.copyWith(storeAvailable: false);
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    try {
      var unlocked = Set<String>.from(state.unlockedProductIds);
      var hasPending = false;

      for (final purchase in purchases) {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            hasPending = true;
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            unlocked.add(purchase.productID);
            break;
          case PurchaseStatus.canceled:
          case PurchaseStatus.error:
            break;
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }

      await _saveUnlockedProductIds(unlocked);

      state = state.copyWith(
        isBusy: hasPending,
        unlockedProductIds: unlocked,
      );
    } catch (_) {
      state = state.copyWith(isBusy: false);
    }
  }

  Future<Set<String>> _loadUnlockedProductIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_prefsKeyUnlockedProducts) ?? const <String>[])
        .toSet();
  }

  Future<void> _saveUnlockedProductIds(Set<String> unlocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKeyUnlockedProducts, unlocked.toList());
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}

final iapPurchaseProvider =
    StateNotifierProvider<IapPurchaseNotifier, IapPurchaseState>(
  (ref) => IapPurchaseNotifier(),
);
