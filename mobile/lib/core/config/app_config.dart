import 'dart:io' show Platform;

/// Platform-aware flags governing the paid-upgrade / subscription surface.
///
/// **Apple Guideline 3.1.1** forbids selling digital subscriptions through any
/// mechanism other than In-App Purchase. Halong24h bills via manual VietQR bank
/// transfer (handled outside the app), so on iOS the entire paid-upgrade
/// surface is hidden: owners get a free working tier and pay through the
/// website. Android keeps the full bank-transfer flow.
///
/// Use [hidePaidUpgradeUI] to suppress any plan price, payment, "mua/nâng cấp
/// gói", "chuyển khoản", or contact-to-pay UI a reviewer could see on iOS.
class AppConfig {
  AppConfig._();

  /// `true` on builds where the in-app paid-upgrade / payment surface must be
  /// hidden (currently iOS, for App Store Guideline 3.1.1 compliance).
  static bool get hidePaidUpgradeUI => Platform.isIOS;

  /// Inverse of [hidePaidUpgradeUI] — payment/subscription UI may be shown.
  static bool get showPaidUpgradeUI => !hidePaidUpgradeUI;
}
