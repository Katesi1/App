/// Enums cho verify + subscription flow.
library;

/// Trạng thái tổng hợp của hồ sơ verify.
enum VerifyStatus {
  draft, // Owner đang fill, chưa upload đủ
  kycSubmitted, // Đã upload CCCD + selfie
  paymentPending, // Chưa thanh toán
  awaitingApproval, // Đã nộp hồ sơ, chờ admin duyệt (Option A)
  approved, // Admin đã duyệt → trial active
  rejected, // Admin reject (toàn bộ hoặc một phần)
  refunded, // Đã hoàn tiền
}

/// Mặt CCCD cần chụp.
enum CCCDSide { front, back }

enum BillingCycle { monthly, yearly }

/// 6 tier theo số phòng cố định. Plan = tier; user không tự chọn số phòng
/// (số phòng = thuộc tính của tier). Enterprise = không giới hạn, giá liên hệ.
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

  /// Số phòng cố định của tier. Enterprise = -1 (custom/unlimited).
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
        return 'STK + nội dung CK · Đối soát 1–3 giờ';
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
