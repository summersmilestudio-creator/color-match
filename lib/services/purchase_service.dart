import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Outcome of a buy() call, so the UI can give the user feedback instead of a
/// silently dead button.
enum PurchaseResult { started, unavailable, notFound, failed }

extension PurchaseResultMessage on PurchaseResult {
  /// Romanian user-facing message; null when the purchase sheet opened fine.
  String? get message {
    switch (this) {
      case PurchaseResult.started:
        return null;
      case PurchaseResult.unavailable:
        return 'Magazinul nu este disponibil. Verifică-ți conexiunea și contul App Store.';
      case PurchaseResult.notFound:
        return 'Produsul nu este disponibil momentan. Încearcă din nou mai târziu.';
      case PurchaseResult.failed:
        return 'Cumpărarea nu a putut fi pornită. Încearcă din nou.';
    }
  }
}

/// Single non-consumable "remove ads" purchase for Color Match.
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  /// Logical product id used everywhere in the app.
  static const String noAdsId = 'noads';

  static const _kNoAdsKey = 'noAds_color';

  /// The iOS "remove ads" product is configured in App Store Connect as
  /// `colormatch_remove_ads`; Android uses the plain logical id.
  static const String _iosNoAdsId = 'colormatch_remove_ads';

  static String _platformId(String logicalId) {
    if (!Platform.isIOS) return logicalId;
    if (logicalId == noAdsId) return _iosNoAdsId;
    return '${logicalId}_color';
  }

  static String _logicalId(String platformId) {
    if (platformId == _iosNoAdsId) return noAdsId;
    return platformId.endsWith('_color')
        ? platformId.substring(0, platformId.length - 6)
        : platformId;
  }

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

  /// Bumped with a user-facing message when a purchase fails or is cancelled,
  /// so a listening screen can show a SnackBar.
  final ValueNotifier<String?> lastError = ValueNotifier(null);

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        await _grant(p);
      } else if (p.status == PurchaseStatus.error) {
        lastError.value = p.error?.message ?? 'Cumpărarea a eșuat.';
      }
      // Always finalise the transaction so it doesn't get stuck pending.
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

  Future<PurchaseResult> buy(String logicalId) async {
    // Re-check availability (e.g. first launch raced the store connection).
    if (!_available) {
      _available = await _iap.isAvailable();
    }
    if (!_available) return PurchaseResult.unavailable;

    var product = _products[logicalId];
    if (product == null) {
      // The initial product query may have failed or not finished — retry once
      // so the button doesn't appear dead.
      final response = await _iap.queryProductDetails({_platformId(logicalId)});
      for (final p in response.productDetails) {
        _products[_logicalId(p.id)] = p;
      }
      product = _products[logicalId];
    }
    if (product == null) return PurchaseResult.notFound;

    final param = PurchaseParam(productDetails: product);
    final started = await _iap.buyNonConsumable(purchaseParam: param);
    return started ? PurchaseResult.started : PurchaseResult.failed;
  }

  Future<void> restore() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _sub?.cancel();
  }
}
