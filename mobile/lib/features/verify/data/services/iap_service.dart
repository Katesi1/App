import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Thin wrapper around `InAppPurchase.instance` for Apple StoreKit.
///
/// Responsibilities:
///  - Query product catalog from App Store Connect
///  - Initiate a non-consumable (subscription) purchase
///  - Expose the platform purchase stream so the controller can react to
///    success / cancel / restored events
///  - Restore purchases (required by Apple — see Subscription Detail screen)
///  - Complete (acknowledge) purchases after backend receipt verification
///
/// Receipt verification (the trust boundary) lives on the backend; this
/// service is intentionally dumb. The controller is responsible for sending
/// `PurchaseDetails.verificationData.serverVerificationData` (the base64
/// receipt) to `/payments/apple/verify` and only calling `completePurchase`
/// after the backend confirms.
class IAPService {
  final InAppPurchase _iap = InAppPurchase.instance;

  /// True when StoreKit is available (always false on simulators without a
  /// signed-in Apple ID, and on Android — IAP is iOS-only in this app).
  Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    return _iap.isAvailable();
  }

  /// Fetch product metadata (price, title, locale-formatted price string).
  /// `productIds` must match the IDs created in App Store Connect exactly.
  /// IDs not found are returned in `ProductDetailsResponse.notFoundIDs`.
  Future<ProductDetailsResponse> queryProducts(Set<String> productIds) {
    return _iap.queryProductDetails(productIds);
  }

  /// Initiate a non-consumable purchase (auto-renewable subscriptions are
  /// treated as non-consumable by `in_app_purchase`). Returns immediately —
  /// the result arrives via [purchaseStream]. Apple shows its own modal
  /// purchase sheet; the user can cancel from there.
  Future<bool> buySubscription(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  /// Restore previously-purchased subscriptions. Required by Apple to be
  /// reachable from a visible UI element (we expose it on the Subscription
  /// Detail screen as "Khôi phục đăng ký").
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Acknowledge a completed purchase after backend has verified the receipt.
  /// MUST be called or the purchase remains in `purchaseStream` and Apple
  /// will redeliver it on every app launch.
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  /// Stream of purchase updates from StoreKit. Subscribe in the controller
  /// at app start (or on first navigation to the payment screen) so that
  /// purchases initiated, restored, or redelivered are all observed.
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;
}

final iapServiceProvider = Provider<IAPService>((_) => IAPService());
