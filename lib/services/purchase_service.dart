import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single non-consumable "remove ads" purchase for Color Match.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// Logical product id used everywhere in the app.
  static const String noAdsId = 'noads';

  static const _kNoAdsKey = 'noAds_color';

  /// iOS uses a suffixed product id ('noads_color'); Android uses the plain id.
  static String _platformId(String logicalId) =>
      Platform.isIOS ? '${logicalId}_color' : logicalId;

  static String _logicalId(String platformId) =>
      platformId.endsWith('_color')
          ? platformId.substring(0, platformId.length - 6)
          : platformId;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<String, ProductDetails> _products = {}; // keyed by logical ID
  bool _available = false;
  bool _noAds = false;
  final ValueNotifier<bool> noAdsNotifier = ValueNotifier(false);

  bool get available => _available;
  bool get noAds => _noAds;
  ProductDetails? productFor(String logicalId) => _products[logicalId];

  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final prefs = await SharedPreferences.getInstance();
    _noAds = prefs.getBool(_kNoAdsKey) ?? false;
    noAdsNotifier.value = _noAds;
    _available = await _iap.isAvailable();
    if (!_available) return;
    final response = await _iap.queryProductDetails({_platformId(noAdsId)});
    for (final p in response.productDetails) {
      _products[_logicalId(p.id)] = p;
    }
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdated, onDone: () => _sub?.cancel());
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        await _grant(p);
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _grant(PurchaseDetails p) async {
    final logicalId = _logicalId(p.productID);
    if (logicalId == noAdsId) {
      final prefs = await SharedPreferences.getInstance();
      _noAds = true;
      noAdsNotifier.value = true;
      await prefs.setBool(_kNoAdsKey, true);
    }
  }

  Future<bool> buy(String logicalId) async {
    final product = _products[logicalId];
    if (product == null || !_available) return false;
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _sub?.cancel();
  }
}
