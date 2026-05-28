import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../utils/constants.dart';
import 'save_service.dart';

class IapService {
  static IapService? _instance;
  static IapService get instance => _instance ??= IapService._();
  IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  List<ProductDetails> products = [];
  bool _available = false;

  bool get available => _available;

  Future<void> init() async {
    if (kIsWeb) {
      _available = false;
      return;
    }
    try {
      _available = await _iap.isAvailable();
      if (!_available) return;
      final response = await _iap.queryProductDetails(IapIds.all);
      products = response.productDetails;
      _sub = _iap.purchaseStream.listen(
        _onPurchaseUpdated,
        onError: (e) {
          if (kDebugMode) debugPrint('IAP stream error: $e');
        },
      );
    } catch (e) {
      _available = false;
      if (kDebugMode) debugPrint('IAP init failed: $e');
    }
  }

  ProductDetails? findProduct(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> buy(String productId) async {
    if (!_available) return false;
    final product = findProduct(productId);
    if (product == null) return false;
    final param = PurchaseParam(productDetails: product);
    try {
      if (productId == IapIds.removeAds) {
        return await _iap.buyNonConsumable(purchaseParam: param);
      }
      return await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      if (kDebugMode) debugPrint('buy error: $e');
      return false;
    }
  }

  Future<void> restore() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      if (kDebugMode) debugPrint('restore error: $e');
    }
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await _grantPurchase(p.productID);
      }
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (e) {
          if (kDebugMode) debugPrint('completePurchase error: $e');
        }
      }
    }
  }

  Future<void> _grantPurchase(String productId) async {
    switch (productId) {
      case IapIds.coinpackStarter:
        await SaveService.instance.addCoins(2500);
        break;
      case IapIds.coinpackValue:
        await SaveService.instance.addCoins(7000);
        break;
      case IapIds.coinpackMega:
        await SaveService.instance.addCoins(15000);
        break;
      case IapIds.removeAds:
        await SaveService.instance.setAdsRemoved(true);
        break;
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
