import 'dart:io' show Platform;

/// `true` on iOS — subscriptions must be sold via Apple In-App Purchase
/// (StoreKit) per Apple App Store Guideline 3.1.1. Non-IAP payment methods
/// (VNPay QR, bank transfer, Pays2 card) are hidden on iOS; the payment
/// screen offers only "Apple In-App Purchase".
///
/// Android keeps the full VNPay / bank / Pays2 flow.
bool get usesAppleIAP => Platform.isIOS;

/// Deep link to the iOS Settings → Subscriptions screen. Apps that sell
/// auto-renewable subscriptions MUST expose this so the user can manage
/// (upgrade / downgrade / cancel) their subscription per Apple guideline 3.1.2(a).
const String appleManageSubscriptionsUrl =
    'https://apps.apple.com/account/subscriptions';
