/// Enums cho verify + subscription flow.
library;

/// Trạng thái tổng hợp của hồ sơ verify.
enum VerifyStatus {
  draft, // Owner đang fill, chưa upload đủ
  kycSubmitted, // Đã upload CCCD + selfie
  paymentPending, // Chưa thanh toán
  awaitingApproval, // Payment OK, chờ admin duyệt
  approved, // Admin đã duyệt → trial active
  rejected, // Admin reject (toàn bộ hoặc một phần)
  refunded, // Đã hoàn tiền
}

/// Mặt CCCD cần chụp.
enum CCCDSide { front, back }

enum BillingCycle { monthly, yearly }

enum Tier { starter, professional, enterprise }

extension TierX on Tier {
  String get displayName {
    switch (this) {
      case Tier.starter:
        return 'Starter';
      case Tier.professional:
        return 'Professional';
      case Tier.enterprise:
        return 'Enterprise';
    }
  }

  String get tagline {
    switch (this) {
      case Tier.starter:
        return 'Cho homestay nhỏ';
      case Tier.professional:
        return 'Phù hợp với hầu hết homestay';
      case Tier.enterprise:
        return 'Cho chuỗi homestay';
    }
  }
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

/// Item có thể bị reject riêng lẻ trong KYC.
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
