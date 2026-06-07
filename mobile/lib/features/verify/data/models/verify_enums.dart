/// Enums for the verify + subscription flow.
library;

/// Aggregate state of a verify application.
enum VerifyStatus {
  draft, // Owner is filling in, not yet fully uploaded
  kycSubmitted, // CCCD + selfie uploaded
  paymentPending, // Not paid yet
  awaitingApproval, // Payment OK, waiting on admin approval
  approved, // Admin approved → trial active
  rejected, // Admin rejected (fully or partially)
  refunded, // Refunded
}

/// Which side of the CCCD to capture.
enum CCCDSide { front, back }

enum BillingCycle { monthly, yearly }

/// 6 tiers with fixed room counts. Plan = tier; user does not pick room count
/// (it's an attribute of the tier). Enterprise = unlimited, contact-only pricing.
enum Tier { rooms1, rooms5, rooms10, rooms20, rooms50, enterprise }

extension TierX on Tier {
  String get displayName => switch (this) {
        Tier.rooms1 => 'Mini',
        Tier.rooms5 => 'Starter',
        Tier.rooms10 => 'Standard',
        Tier.rooms20 => 'Pro',
        Tier.rooms50 => 'Business',
        Tier.enterprise => 'Enterprise',
      };

  String get tagline => switch (this) {
        Tier.rooms1 => 'Cá nhân thử nghiệm',
        Tier.rooms5 => 'Homestay nhỏ',
        Tier.rooms10 => 'Homestay vừa',
        Tier.rooms20 => 'Homestay lớn',
        Tier.rooms50 => 'Chuỗi nhỏ',
        Tier.enterprise => 'Không giới hạn — hợp đồng riêng',
      };

  /// Fixed room count for the tier. Enterprise = -1 (custom/unlimited).
  int get rooms => switch (this) {
        Tier.rooms1 => 1,
        Tier.rooms5 => 5,
        Tier.rooms10 => 10,
        Tier.rooms20 => 20,
        Tier.rooms50 => 50,
        Tier.enterprise => -1,
      };

  bool get isEnterprise => this == Tier.enterprise;
}

enum PaymentMethod { vnpayQR, bankTransfer, card }

extension PaymentMethodX on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.vnpayQR:
        return 'VNPay QR';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản ngân hàng';
      case PaymentMethod.card:
        return 'Thẻ tín dụng/ghi nợ';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethod.vnpayQR:
        return 'Quét QR bằng app ngân hàng · Tức thời';
      case PaymentMethod.bankTransfer:
        return 'STK + nội dung CK · 5-30 phút';
      case PaymentMethod.card:
        return 'Visa, Mastercard, JCB · Tức thời';
    }
  }
}

enum PaymentStatus { pending, paid, failed, expired, refunded }

/// Loại giao dịch BE tự nhận diện (quote/initiate/history trả về). BE là source
/// of truth — FE chỉ đọc để render nhãn/icon, KHÔNG tự suy ra.
enum TransactionKind { subscription, renew, upgrade, downgrade }

TransactionKind? transactionKindFromApi(String? raw) {
  switch (raw) {
    case 'subscription':
      return TransactionKind.subscription;
    case 'renew':
      return TransactionKind.renew;
    case 'upgrade':
      return TransactionKind.upgrade;
    case 'downgrade':
      return TransactionKind.downgrade;
    default:
      return null;
  }
}

extension TransactionKindX on TransactionKind {
  String get label => switch (this) {
        TransactionKind.subscription => 'Đăng ký gói',
        TransactionKind.renew => 'Gia hạn gói',
        TransactionKind.upgrade => 'Nâng gói',
        TransactionKind.downgrade => 'Hạ gói',
      };
}

/// KYC items that can be rejected individually.
enum RejectableItem { cccdFront, cccdBack, selfie }

extension RejectableItemX on RejectableItem {
  String get id {
    switch (this) {
      case RejectableItem.cccdFront:
        return 'cccdFront';
      case RejectableItem.cccdBack:
        return 'cccdBack';
      case RejectableItem.selfie:
        return 'selfie';
    }
  }

  String get label {
    switch (this) {
      case RejectableItem.cccdFront:
        return 'CCCD mặt trước';
      case RejectableItem.cccdBack:
        return 'CCCD mặt sau';
      case RejectableItem.selfie:
        return 'Selfie';
    }
  }

  static RejectableItem? fromId(String id) {
    for (final item in RejectableItem.values) {
      if (item.id == id) return item;
    }
    return null;
  }
}
