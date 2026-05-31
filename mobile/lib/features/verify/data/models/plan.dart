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

  /// Price VND/year. Set explicitly to match Apple's discrete pricing tiers
  /// (Apple doesn't allow arbitrary VND values — only ~30 fixed points).
  /// If `null`, derived as `monthlyPrice × 12 × (1 - yearlyDiscount)`.
  final int? yearlyPrice;

  final List<String> features;

  const Plan({
    required this.id,
    required this.tier,
    required this.rooms,
    required this.monthlyPrice,
    this.yearlyPrice,
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
      yearlyPrice: (json['yearlyPrice'] as num?)?.toInt(),
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

  /// Public, **null-on-unknown** lookup of a tier from a backend plan id
  /// (`rooms_5`, `starter`, `enterprise`, ...). Unlike [_tierFromId] (used in
  /// parsing, which defaults to Starter), this returns null for null/unknown
  /// ids so callers can render a placeholder ("—") for users who haven't
  /// bought a plan yet.
  static Tier? tierFromId(String? id) => switch (id) {
        'rooms_1' || 'mini' => Tier.rooms1,
        'rooms_5' || 'starter' => Tier.rooms5,
        'rooms_10' || 'standard' => Tier.rooms10,
        'rooms_20' || 'pro' || 'professional' => Tier.rooms20,
        'rooms_50' || 'business' => Tier.rooms50,
        'enterprise' => Tier.enterprise,
        _ => null,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'tier': tier.name,
        'rooms': rooms,
        'monthlyPrice': monthlyPrice,
        if (yearlyPrice != null) 'yearlyPrice': yearlyPrice,
        'features': features,
      };

  @override
  List<Object?> get props =>
      [id, tier, rooms, monthlyPrice, yearlyPrice, features];
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
    yearlyPrice: 1999000, // Apple tier-aligned (~16% discount)
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
    yearlyPrice: 5999000, // Apple tier-aligned (~16% discount)
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
    yearlyPrice: 9999000, // Apple tier-aligned (~16% discount)
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
    yearlyPrice: 17999000, // Apple tier-aligned (~16% discount)
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
    // Apple VND max = 29.999.000đ. Capping here makes Business Yearly the
    // best-value option (37.5% discount) — surface this in marketing.
    yearlyPrice: 29999000,
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

  /// Fallback yearly discount (~16%) when a plan doesn't have an explicit
  /// `yearlyPrice`. Real plans set `yearlyPrice` directly to match Apple's
  /// pricing tiers.
  static const double yearlyDiscount = 0.16;

  /// 10% VAT.
  static const double vatRate = 0.10;

  static int monthly(Plan plan) => plan.monthlyPrice;

  /// Yearly price after the loyalty discount.
  /// Prefers `plan.yearlyPrice` (explicit, aligned with Apple tiers), falls
  /// back to derived value (`monthly × 12 × (1 - discount)`) when not set.
  static int yearlyAfterDiscount(Plan plan) =>
      plan.yearlyPrice ??
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

  /// Look up a plan by tier within the catalog. Falls back to the bundled
  /// default for the same tier if the catalog doesn't carry it — keeps the
  /// UI alive when the backend ships an incomplete plan list.
  static Plan planFor(Tier tier, List<Plan> catalog) =>
      catalog.firstWhere(
        (p) => p.tier == tier,
        orElse: () =>
            kDefaultPlans.firstWhere((p) => p.tier == tier),
      );
}

/// Apple App Store Connect product IDs for each (tier, billing cycle).
///
/// **Setup checklist for App Store Connect:**
///  1. Create one auto-renewable subscription group: `Halong24h Subscriptions`.
///  2. Inside the group, create 12 subscription products (6 tiers × 2 cycles):
///     - Product ID: exactly as listed below (e.g. `com.halong24h.sub.rooms5_monthly`)
///     - Reference name: `Starter Monthly`, `Starter Yearly`, ...
///     - Duration: 1 month / 1 year
///     - Pricing tier: closest VND match to the plan's `monthlyPrice` (or
///       `monthly × 12 × 0.8` for yearly with built-in 20% discount).
///     - Family Sharing: OFF (B2B account).
///     - Free trial: 7 days introductory offer (matches existing flow).
///  3. Enterprise tier: skip — sold via direct contract, not IAP.
///
/// Enterprise (`Tier.enterprise`) has no IAP product — caller should NOT
/// offer IAP for it; show a "Contact sales" CTA instead.
class AppleProductIds {
  AppleProductIds._();

  /// Bundle ID prefix for App Store Connect IAP products.
  /// Must match the `Bundle ID` registered in App Store Connect.
  static const String _prefix = 'com.halong24h.sub';

  /// Map (tier, cycle) → Apple product ID. Returns `null` for Enterprise
  /// (no IAP — contact sales).
  static String? forPlan(Tier tier, BillingCycle cycle) {
    if (tier == Tier.enterprise) return null;
    final tierSlug = switch (tier) {
      Tier.rooms1 => 'rooms1',
      Tier.rooms5 => 'rooms5',
      Tier.rooms10 => 'rooms10',
      Tier.rooms20 => 'rooms20',
      Tier.rooms50 => 'rooms50',
      Tier.enterprise => '', // unreachable
    };
    final cycleSlug = cycle == BillingCycle.yearly ? 'yearly' : 'monthly';
    return '$_prefix.${tierSlug}_$cycleSlug';
  }

  /// Full set of product IDs to query from StoreKit at app start.
  static Set<String> get all => {
        for (final tier in Tier.values.where((t) => t != Tier.enterprise))
          for (final cycle in BillingCycle.values) forPlan(tier, cycle)!,
      };
}
