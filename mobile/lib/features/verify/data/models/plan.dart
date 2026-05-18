import 'package:equatable/equatable.dart';

import 'verify_enums.dart';

/// Subscription plan — tier-based, each tier maps to a fixed room count.
///
/// The user does NOT pick a room count — once a tier is selected, `rooms` is
/// derived from it. Enterprise: `monthlyPrice = 0` represents "Contact us"
/// (custom contract).
class Plan extends Equatable {
  final String id;
  final Tier tier;

  /// Allowed room count (= `tier.rooms`). Enterprise = `-1` (unlimited).
  final int rooms;

  /// Price VND/month. `0` = "Contact us" (Enterprise only).
  final int monthlyPrice;

  final List<String> features;

  const Plan({
    required this.id,
    required this.tier,
    required this.rooms,
    required this.monthlyPrice,
    required this.features,
  });

  bool get isEnterprise => tier.isEnterprise;
  bool get hasFixedPrice => monthlyPrice > 0;

  /// Parse from backend `GET /billing/plans`. Backend returns `id` like
  /// `rooms_5`, `enterprise`, etc. — tier is derived from `id`.
  factory Plan.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final tier = _tierFromId(id);
    return Plan(
      id: id,
      tier: tier,
      rooms: (json['rooms'] as num?)?.toInt() ?? tier.rooms,
      monthlyPrice: (json['monthlyPrice'] as num?)?.toInt() ?? 0,
      features: List<String>.from(json['features'] as List? ?? const []),
    );
  }

  static Tier _tierFromId(String id) => switch (id) {
        'rooms_1' || 'mini' => Tier.rooms1,
        'rooms_5' || 'starter' => Tier.rooms5,
        'rooms_10' || 'standard' => Tier.rooms10,
        'rooms_20' || 'pro' || 'professional' => Tier.rooms20,
        'rooms_50' || 'business' => Tier.rooms50,
        'enterprise' => Tier.enterprise,
        _ => Tier.rooms5,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'tier': tier.name,
        'rooms': rooms,
        'monthlyPrice': monthlyPrice,
        'features': features,
      };

  @override
  List<Object?> get props => [id, tier, rooms, monthlyPrice, features];
}

/// 6-plan default catalog — fallback when backend is unreachable.
///
/// Suggested pricing (round numbers, growing volume discount — tune later):
/// | Tier        | Rooms | Monthly      | Per-room/month |
/// |-------------|-------|--------------|----------------|
/// | Mini        | 1     | 199.000      | 199.000        |
/// | Starter     | 5     | 599.000      | 119.800        |
/// | Standard    | 10    | 999.000      | 99.900         |
/// | Pro         | 20    | 1.799.000    | 89.950         |
/// | Business    | 50    | 3.999.000    | 79.980         |
/// | Enterprise  | ∞     | Contact us   | —              |
const kDefaultPlans = <Plan>[
  Plan(
    id: 'rooms_1',
    tier: Tier.rooms1,
    rooms: 1,
    monthlyPrice: 199000,
    features: [
      'Booking + Calendar',
      'Check-in / Check-out',
      'Báo cáo cơ bản',
    ],
  ),
  Plan(
    id: 'rooms_5',
    tier: Tier.rooms5,
    rooms: 5,
    monthlyPrice: 599000,
    features: [
      'Tất cả tính năng Mini',
      'Pricing rules cơ bản',
      'Multi-staff (3 nhân viên)',
    ],
  ),
  Plan(
    id: 'rooms_10',
    tier: Tier.rooms10,
    rooms: 10,
    monthlyPrice: 999000,
    features: [
      'Tất cả tính năng Starter',
      'Dynamic pricing',
      'Housekeeping + Expenses',
      'Báo cáo nâng cao',
    ],
  ),
  Plan(
    id: 'rooms_20',
    tier: Tier.rooms20,
    rooms: 20,
    monthlyPrice: 1799000,
    features: [
      'Tất cả tính năng Standard',
      'Multi-staff không giới hạn',
      'Multi-property',
    ],
  ),
  Plan(
    id: 'rooms_50',
    tier: Tier.rooms50,
    rooms: 50,
    monthlyPrice: 3999000,
    features: [
      'Tất cả tính năng Pro',
      'Channel sync (Booking.com, Agoda...)',
      'API + Webhook',
    ],
  ),
  Plan(
    id: 'enterprise',
    tier: Tier.enterprise,
    rooms: -1, // unlimited
    monthlyPrice: 4999000,
    features: [
      'Số phòng không giới hạn',
      'Tất cả tính năng Business',
      'SLA + hỗ trợ riêng 24/7',
      'Onboarding 1-1',
    ],
  ),
];

/// Pricing util. Simpler than the previous version (no rooms × price + floor)
/// — each tier has a fixed `monthlyPrice`.
class PlanPriceCalculator {
  PlanPriceCalculator._();

  /// 20% discount when choosing yearly.
  static const double yearlyDiscount = 0.20;

  /// 10% VAT.
  static const double vatRate = 0.10;

  static int monthly(Plan plan) => plan.monthlyPrice;

  static int yearlyAfterDiscount(Plan plan) =>
      (plan.monthlyPrice * 12 * (1 - yearlyDiscount)).round();

  static int yearlyBeforeDiscount(Plan plan) => plan.monthlyPrice * 12;

  static int yearlySavings(Plan plan) =>
      yearlyBeforeDiscount(plan) - yearlyAfterDiscount(plan);

  static int vat(int subtotal) => (subtotal * vatRate).round();

  /// Total = subtotal + VAT (if included). Returns `0` for Enterprise ("Contact us").
  static int total(Plan plan, BillingCycle cycle, {bool includeVat = true}) {
    if (!plan.hasFixedPrice) return 0;
    final subtotal = cycle == BillingCycle.yearly
        ? yearlyAfterDiscount(plan)
        : monthly(plan);
    return includeVat ? subtotal + vat(subtotal) : subtotal;
  }

  /// Look up a plan by tier within the catalog.
  static Plan planFor(Tier tier, List<Plan> catalog) =>
      catalog.firstWhere((p) => p.tier == tier);
}
