import 'package:equatable/equatable.dart';

import 'verify_enums.dart';

/// Subscription plan (tier).
class Plan extends Equatable {
  final String id;
  final Tier tier;

  /// Đơn giá VND/phòng/tháng.
  final int pricePerRoomPerMonth;

  /// Min charge/tháng (sàn giá khi số phòng nhỏ).
  final int minChargePerMonth;
  final int? maxRooms;
  final List<String> features;

  const Plan({
    required this.id,
    required this.tier,
    required this.pricePerRoomPerMonth,
    required this.minChargePerMonth,
    this.maxRooms,
    required this.features,
  });

  /// Parse từ backend `GET /billing/plans`. Backend trả về:
  /// `{ id, name, pricePerRoom, minCharge, maxRooms, yearlyDiscountPct, vatPct, features[] }`
  /// trong đó `id` là `"starter"|"professional"|"enterprise"` — derive tier từ id.
  factory Plan.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final tierStr = (json['tier'] as String?) ?? id;
    final tier = Tier.values.firstWhere(
      (t) => t.name == tierStr,
      orElse: () => Tier.starter,
    );
    return Plan(
      id: id,
      tier: tier,
      pricePerRoomPerMonth: (json['pricePerRoom'] ??
          json['pricePerRoomPerMonth'] ??
          json['price_per_room_per_month']) as int,
      minChargePerMonth: (json['minCharge'] ??
          json['minChargePerMonth'] ??
          json['min_charge_per_month']) as int,
      maxRooms: (json['maxRooms'] ?? json['max_rooms']) as int?,
      features: List<String>.from(json['features'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tier': tier.name,
        'pricePerRoom': pricePerRoomPerMonth,
        'minCharge': minChargePerMonth,
        'maxRooms': maxRooms,
        'features': features,
      };

  @override
  List<Object?> get props =>
      [id, tier, pricePerRoomPerMonth, minChargePerMonth, maxRooms, features];
}

/// Catalog 3 plan mặc định — dùng khi backend không reachable.
/// IDs khớp với backend (`starter`, `professional`, `enterprise`).
const kDefaultPlans = <Plan>[
  Plan(
    id: 'starter',
    tier: Tier.starter,
    pricePerRoomPerMonth: 199000,
    minChargePerMonth: 1999000,
    maxRooms: 20,
    features: [
      'Booking + Calendar',
      'Check-in / Check-out',
      'Báo cáo cơ bản',
    ],
  ),
  Plan(
    id: 'professional',
    tier: Tier.professional,
    pricePerRoomPerMonth: 149000,
    minChargePerMonth: 2999000,
    maxRooms: 50,
    features: [
      'Tất cả tính năng Starter',
      'Pricing rules + Dynamic pricing',
      'Housekeeping + Expenses',
      'Báo cáo nâng cao',
    ],
  ),
  Plan(
    id: 'enterprise',
    tier: Tier.enterprise,
    pricePerRoomPerMonth: 99000,
    minChargePerMonth: 4999000,
    features: [
      'Tất cả tính năng Pro',
      'Multi-property + Channel sync',
      'API + Webhook',
      'Hỗ trợ riêng 24/7',
    ],
  ),
];

/// Util tính giá theo công thức spec section 3.2.
class PlanPriceCalculator {
  PlanPriceCalculator._();

  /// Giá hàng tháng cho [rooms] phòng, áp dụng sàn [minChargePerMonth].
  static int monthly(int rooms, Plan plan) {
    final raw = rooms * plan.pricePerRoomPerMonth;
    return raw < plan.minChargePerMonth ? plan.minChargePerMonth : raw;
  }

  /// Giá hàng năm SAU discount 20% (tổng phải trả khi chọn yearly).
  static int yearlyAfterDiscount(int rooms, Plan plan) {
    final m = monthly(rooms, plan);
    return (m * 12 * 0.8).round();
  }

  /// Giá năm GỐC (chưa giảm) — dùng để hiển thị "giảm X" trên order summary.
  static int yearlyBeforeDiscount(int rooms, Plan plan) =>
      monthly(rooms, plan) * 12;

  /// Số tiền tiết kiệm khi chọn yearly thay vì monthly × 12.
  static int yearlySavings(int rooms, Plan plan) =>
      yearlyBeforeDiscount(rooms, plan) - yearlyAfterDiscount(rooms, plan);

  /// VAT 10% trên giá đã giảm.
  static int vat(int subtotal) => (subtotal * 0.1).round();

  /// Tổng thanh toán = subtotal + vat (nếu áp dụng).
  static int total(int rooms, Plan plan, BillingCycle cycle,
      {bool includeVat = true}) {
    final subtotal = cycle == BillingCycle.yearly
        ? yearlyAfterDiscount(rooms, plan)
        : monthly(rooms, plan);
    return includeVat ? subtotal + vat(subtotal) : subtotal;
  }

  /// Auto-suggest tier theo số phòng.
  static Tier suggestTier(int rooms) {
    if (rooms <= 20) return Tier.starter;
    if (rooms <= 50) return Tier.professional;
    return Tier.enterprise;
  }

  /// Lookup plan theo tier trong catalog cố định.
  static Plan planFor(Tier tier, List<Plan> catalog) =>
      catalog.firstWhere((p) => p.tier == tier);
}
