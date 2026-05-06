# Halong24h — Customer Home Implementation Spec

> **Tài liệu giao việc dev** — build Customer Home screen với palette v2 dark + light.
> Companion docs:
> - `halong24h-color-system-v2.md` (color tokens)
> - `halong24h-component-specs-v2.md` (component anatomy)
> - `halong24h-customer-home-mockup.html` (visual reference, dark mode)
>
> Ngày: 27/04/2026
> Sprint target: 1 sprint (5 ngày)

---

## Mục lục

1. [Phạm vi & ưu tiên](#1-phạm-vi--ưu-tiên)
2. [Acceptance criteria](#2-acceptance-criteria)
3. [File structure](#3-file-structure)
4. [Data layer](#4-data-layer)
5. [Widget tree breakdown](#5-widget-tree-breakdown)
6. [Code skeleton từng widget](#6-code-skeleton-từng-widget)
7. [API contracts](#7-api-contracts)
8. [Testing checklist](#8-testing-checklist)
9. [Definition of Done](#9-definition-of-done)
10. [Deliverables](#10-deliverables)

---

## 1. Phạm vi & ưu tiên

### 1.1 Trong scope sprint này

Build Customer Home screen end-to-end với **9 sections** từ trên xuống:

| # | Section | Component reuse | New build |
|---|---|---|---|
| 1 | Greeting Header gradient (với search bar nổi) | — | ✓ `GreetingHeader` |
| 2 | Popular Destinations (4 destination chips) | — | ✓ `DestinationGrid` |
| 3 | AI Insight Card (personal recommendation) | từ `AIInsightCard` shared | — |
| 4 | Top Featured Properties (Premium + Hot variants) | từ `CustomerPropertyCard` shared | — |
| 5 | Voucher Banner Card (coral warm variant) | — | ✓ `VoucherBannerCard` |
| 6 | Activity / Experience carousel (tour, du thuyền) | — | ✓ `ActivityCard` |
| 7 | Bottom Navigation (5 tabs với center FAB) | từ `AppScaffold` shared | — |
| 8 | Pull-to-refresh | Flutter native | — |
| 9 | Skeleton loading states | từ `*Skeleton` shared | — |

### 1.2 Ngoài scope (sprint sau)

- Property Detail screen (tap vào property card → push route)
- Search/Filter modal (tap search bar → push route)
- Notification screen (tap bell → push route)
- Profile screen (tap avatar → push route)
- Wishlist functionality (toggle heart icon → optimistic UI ✓ nhưng backend persist sau)

### 1.3 Ưu tiên (nếu thiếu thời gian)

- **P0 — phải có**: Greeting Header, Top Featured, Bottom Nav, dark + light theme work
- **P1 — nên có**: AI Insight, Popular Destinations, Voucher banner, skeleton loading
- **P2 — nice to have**: Activity carousel, animations chi tiết, decorative stars trong header

---

## 2. Acceptance criteria

### 2.1 Visual

- [ ] Match mockup file `halong24h-customer-home-mockup.html` ≥ 95% pixel-accurate ở **dark mode**
- [ ] Light mode tự động hoạt động (không hardcode dark colors), match Color System v2 light tokens
- [ ] Toggle dark/light qua system setting hoặc app setting → **không reload**, transition mượt 300ms
- [ ] Chạy thử trên iPhone 13 (390×844) + Pixel 5 (393×851) — không vỡ layout
- [ ] Chạy thử iPhone SE 2nd gen (375×667) + Galaxy S8 (360×740) — không scroll horizontal, không cut content
- [ ] Status bar foreground tự động white trên gradient header (không stuck dark)

### 2.2 Functional

- [ ] Pull-to-refresh hoạt động → invalidate `customerHomeProvider`
- [ ] Tap property card → push `/property/:id` (placeholder route OK)
- [ ] Tap heart icon → toggle wishlist (optimistic update, không cần backend)
- [ ] Tap destination chip → push `/search?destination=:slug` (placeholder OK)
- [ ] Tap AI insight CTA "Xem ngay" → push tới target route trong insight data
- [ ] Tap voucher card → show bottom sheet detail (placeholder OK)
- [ ] Tap bell → push `/notifications` (placeholder OK)
- [ ] Tap avatar → push `/profile` (placeholder OK)
- [ ] Center FAB (map pin) → push `/search/map` (placeholder OK)

### 2.3 Performance

- [ ] First paint ≤ 800ms trên iPhone 11 (cold start)
- [ ] Scroll 60fps không drop frame trên Pixel 5
- [ ] Image load progressive (placeholder → real image) qua `cached_network_image`
- [ ] Skeleton hiện trong < 100ms khi data đang load
- [ ] Animation on mount staggered, không trigger lại khi pull-to-refresh

### 2.4 Accessibility

- [ ] VoiceOver/TalkBack đọc đúng order: greeting → destinations → AI insight → properties
- [ ] Mọi tappable có `Semantics(button: true, label: "...")`
- [ ] Heart icon có state "Đã thích" / "Chưa thích" cho screen reader
- [ ] Contrast ratio đã verify (xem QA section 8)

---

## 3. File structure

### 3.1 Thư mục mới cần tạo

```
lib/
├── features/
│   └── customer_home/
│       ├── controllers/
│       │   └── customer_home_controller.dart       (NEW)
│       ├── data/
│       │   ├── models/
│       │   │   ├── customer_home_data.dart         (NEW)
│       │   │   ├── destination.dart                 (NEW)
│       │   │   ├── ai_insight.dart                  (NEW, shared)
│       │   │   ├── voucher.dart                     (NEW)
│       │   │   └── activity.dart                    (NEW)
│       │   └── repositories/
│       │       └── customer_home_repository.dart    (NEW)
│       └── views/
│           ├── customer_home_screen.dart            (NEW — ROOT)
│           └── widgets/
│               ├── greeting_header.dart             (NEW)
│               ├── popular_destinations.dart        (NEW)
│               ├── voucher_banner_card.dart         (NEW)
│               ├── activity_carousel.dart           (NEW)
│               └── customer_home_skeleton.dart      (NEW)
└── shared/
    └── widgets/
        ├── badges/                                   (đã có ở sprint trước)
        │   ├── premium_ribbon.dart
        │   └── hot_badge.dart
        ├── cards/
        │   ├── customer_property_card.dart          (đã có)
        │   ├── ai_insight_card.dart                 (đã có)
        │   └── status_strip.dart                    (đã có)
        └── live_dot.dart                             (đã có)
```

### 3.2 File hiện có cần update

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart                         (UPDATE — đã spec ở Color System v2)
│   │   ├── app_color_scheme.dart                   (NEW — đã spec)
│   │   └── app_theme.dart                          (UPDATE — đã spec)
│   └── routing/
│       └── app_router.dart                         (UPDATE — thêm routes mới)
└── main.dart                                        (UPDATE — apply theme mới)
```

### 3.3 Asset cần thêm

```
assets/
├── illustrations/
│   ├── empty_search.svg                            (P2 — có thể skip)
│   ├── empty_wishlist.svg                          (P2)
│   └── error_network.svg                           (P2)
└── images/
    └── destinations/                                (placeholder OK)
        ├── bai_chay.jpg
        ├── tuan_chau.jpg
        ├── cat_ba.jpg
        └── dao_ngoc.jpg
```

> Asset thật có thể dùng Unsplash temporarily. Production cần hợp đồng licensing.

---

## 4. Data layer

### 4.1 Models

#### `customer_home_data.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_home_data.freezed.dart';
part 'customer_home_data.g.dart';

@freezed
class CustomerHomeData with _$CustomerHomeData {
  const factory CustomerHomeData({
    required String userName,
    required UserGreeting greeting,           // morning/afternoon/evening
    required int unreadNotifications,
    required List<Destination> popularDestinations,
    required List<AIInsight> personalInsights,
    required List<Property> topFeatured,
    required List<Voucher> activeVouchers,
    required List<Activity> activities,
  }) = _CustomerHomeData;

  factory CustomerHomeData.fromJson(Map<String, dynamic> json) =>
      _$CustomerHomeDataFromJson(json);
}

enum UserGreeting { morning, afternoon, evening, night }
```

#### `destination.dart`

```dart
@freezed
class Destination with _$Destination {
  const factory Destination({
    required String slug,           // "bai-chay"
    required String name,           // "Bãi Cháy"
    required String emoji,          // "🏖️"
    required int propertyCount,     // 142
    required DestinationTheme theme, // jade/gold/coral/slate
  }) = _Destination;
}

enum DestinationTheme { jade, gold, coral, slate }
```

#### `ai_insight.dart`

```dart
@freezed
class AIInsight with _$AIInsight {
  const factory AIInsight({
    required String id,
    required AIInsightType type,    // suggestion/alert/opportunity/info
    required String overline,        // "GỢI Ý TỪ AI"
    required String message,
    required AIInsightAction primaryAction,
    AIInsightAction? secondaryAction,
    DateTime? expiresAt,
  }) = _AIInsight;
}

@freezed
class AIInsightAction with _$AIInsightAction {
  const factory AIInsightAction({
    required String label,
    required String? routeTarget,    // "/property/123?promo=SUMMER30"
    Map<String, dynamic>? params,
  }) = _AIInsightAction;
}

enum AIInsightType { suggestion, alert, opportunity, info }
```

#### `voucher.dart`

```dart
@freezed
class Voucher with _$Voucher {
  const factory Voucher({
    required String id,
    required String code,            // "FIRST500K"
    required String title,           // "Voucher 500K cho lần đặt đầu"
    required String subtitle,        // "Áp dụng đến 30/04 · Đơn từ 2tr"
    required int discountAmount,     // 500000 (đ)
    required DateTime expiresAt,
    required int minOrderAmount,
    String? icon,                    // emoji "🎁"
  }) = _Voucher;
}
```

#### `activity.dart`

```dart
@freezed
class Activity with _$Activity {
  const factory Activity({
    required String id,
    required String name,            // "Tour vịnh"
    required int priceFrom,          // 350000
    required String coverImage,
    String? badge,                   // "MỚI", "−20%"
  }) = _Activity;
}
```

### 4.2 Repository

```dart
abstract class CustomerHomeRepository {
  Future<CustomerHomeData> fetchHomeData();
  Future<void> dismissInsight(String insightId);
  Future<void> toggleWishlist(String propertyId);
}

class CustomerHomeRepositoryImpl implements CustomerHomeRepository {
  final Dio _dio;
  final AuthService _auth;

  @override
  Future<CustomerHomeData> fetchHomeData() async {
    final response = await _dio.get('/customer/home');
    return CustomerHomeData.fromJson(response.data);
  }
  // ...
}
```

### 4.3 Controller (Riverpod)

```dart
@riverpod
class CustomerHomeController extends _$CustomerHomeController {
  @override
  Future<CustomerHomeData> build() async {
    final repo = ref.read(customerHomeRepositoryProvider);
    return repo.fetchHomeData();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(customerHomeRepositoryProvider);
      return repo.fetchHomeData();
    });
  }

  Future<void> dismissInsight(String insightId) async {
    final current = state.value;
    if (current == null) return;

    // Optimistic update
    state = AsyncData(
      current.copyWith(
        personalInsights: current.personalInsights
            .where((i) => i.id != insightId)
            .toList(),
      ),
    );

    try {
      await ref.read(customerHomeRepositoryProvider).dismissInsight(insightId);
    } catch (e) {
      // Revert on error
      state = AsyncData(current);
      rethrow;
    }
  }
}
```

### 4.4 Wishlist provider (separate, persists)

```dart
@riverpod
class WishlistController extends _$WishlistController {
  @override
  Set<String> build() {
    // Load from local storage or backend
    return ref.read(localStorageProvider).getWishlistIds();
  }

  void toggle(String propertyId) {
    if (state.contains(propertyId)) {
      state = {...state}..remove(propertyId);
    } else {
      state = {...state, propertyId};
    }
    // Persist async, không block UI
    ref.read(localStorageProvider).saveWishlistIds(state);
  }

  bool isWishlisted(String propertyId) => state.contains(propertyId);
}
```

---

## 5. Widget tree breakdown

```
CustomerHomeScreen (Scaffold)
├── extendBodyBehindAppBar: true (gradient header xuyên xuống status bar)
├── body: NestedScrollView hoặc CustomScrollView
│   └── slivers:
│       ├── SliverToBoxAdapter
│       │   └── GreetingHeader (gradient + search bar nổi)
│       ├── SliverPadding (margin top -42, overlap)
│       │   └── SliverToBoxAdapter
│       │       └── PopularDestinations (4 grid chips)
│       ├── SliverPadding
│       │   └── SliverToBoxAdapter
│       │       └── AIInsightCard (nếu có insight)
│       ├── SliverPadding
│       │   └── SliverToBoxAdapter
│       │       └── SectionHeading("Top property mùa hè", "Xem tất cả →")
│       ├── SliverList (top featured properties)
│       │   └── CustomerPropertyCard × N (với premium/hot variants)
│       ├── SliverToBoxAdapter
│       │   └── VoucherBannerCard (nếu có voucher active)
│       ├── SliverPadding
│       │   └── SliverToBoxAdapter
│       │       └── SectionHeading("Hoạt động trải nghiệm")
│       ├── SliverToBoxAdapter
│       │   └── ActivityCarousel (horizontal scroll)
│       └── SliverPadding (bottom safe area)
└── bottomNavigationBar: AppBottomNav (selectedIndex: 0)
```

---

## 6. Code skeleton từng widget

### 6.1 `customer_home_screen.dart` (ROOT)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../controllers/customer_home_controller.dart';
import 'widgets/greeting_header.dart';
import 'widgets/popular_destinations.dart';
import 'widgets/voucher_banner_card.dart';
import 'widgets/activity_carousel.dart';
import 'widgets/customer_home_skeleton.dart';
import '../../../shared/widgets/cards/customer_property_card.dart';
import '../../../shared/widgets/cards/ai_insight_card.dart';
import '../../../shared/widgets/section_heading.dart';
import '../../../shared/widgets/error_state.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(customerHomeControllerProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        color: colors.brand,
        backgroundColor: colors.bgSurfaceElevated,
        onRefresh: () => ref
            .read(customerHomeControllerProvider.notifier)
            .refresh(),
        child: homeAsync.when(
          loading: () => const CustomerHomeSkeleton(),
          error: (err, _) => ErrorState(
            title: 'Không tải được dữ liệu',
            subtitle: 'Hãy kiểm tra mạng và thử lại',
            onRetry: () => ref.invalidate(customerHomeControllerProvider),
          ),
          data: (data) => _buildContent(context, ref, data),
        ),
      ),
      // bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, CustomerHomeData data) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 1. Greeting Header
        SliverToBoxAdapter(
          child: GreetingHeader(
            userName: data.userName,
            greeting: data.greeting,
            unreadNotifications: data.unreadNotifications,
          ),
        ),

        // 2. Popular destinations (overlap -42 với header)
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: PopularDestinations(
                destinations: data.popularDestinations,
              ),
            ),
          ),
        ),

        // 3. AI Insight (optional, nếu có)
        if (data.personalInsights.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: AIInsightCard(
                insight: data.personalInsights.first,
                onPrimaryAction: () => _handleInsightAction(
                  context,
                  data.personalInsights.first.primaryAction,
                ),
                onDismiss: () => ref
                    .read(customerHomeControllerProvider.notifier)
                    .dismissInsight(data.personalInsights.first.id),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),
          ),

        // 4. Top featured properties
        if (data.topFeatured.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
              child: SectionHeading(
                title: 'Top property mùa hè',
                subtitle: 'Đã được ${_formatNumber(data.topFeatured.length * 250)} khách yêu thích',
                trailing: 'Xem tất cả',
                onTrailingTap: () => Navigator.pushNamed(context, '/search'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverList.separated(
              itemCount: data.topFeatured.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, index) => CustomerPropertyCard(
                property: data.topFeatured[index],
                index: index,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/property/${data.topFeatured[index].id}',
                ),
              ),
            ),
          ),
        ],

        // 5. Voucher banner
        if (data.activeVouchers.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: VoucherBannerCard(
                voucher: data.activeVouchers.first,
                onTap: () => _showVoucherDetail(context, data.activeVouchers.first),
              ),
            ),
          ),

        // 6. Activity carousel
        if (data.activities.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
              child: SectionHeading(title: 'Hoạt động trải nghiệm'),
            ),
          ),
          SliverToBoxAdapter(
            child: ActivityCarousel(activities: data.activities),
          ),
        ],

        // 7. Bottom safe area
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  void _handleInsightAction(BuildContext context, AIInsightAction action) {
    if (action.routeTarget != null) {
      Navigator.pushNamed(context, action.routeTarget!, arguments: action.params);
    }
  }

  void _showVoucherDetail(BuildContext context, Voucher voucher) {
    showModalBottomSheet(
      context: context,
      builder: (_) => VoucherDetailSheet(voucher: voucher),
    );
  }

  String _formatNumber(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
```

### 6.2 `greeting_header.dart`

```dart
class GreetingHeader extends StatelessWidget {
  final String userName;
  final UserGreeting greeting;
  final int unreadNotifications;

  const GreetingHeader({
    super.key,
    required this.userName,
    required this.greeting,
    required this.unreadNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 14, 16, 56),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0A1F26), const Color(0xFF0F5A6B), const Color(0xFF1B5664)]
              : [const Color(0xFF0F5A6B), const Color(0xFF1B7E94)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Decorative blobs (z=0)
          Positioned(
            right: -50, top: -30,
            child: _Blob(size: 180, color: Colors.white.withOpacity(isDark ? 0.08 : 0.06)),
          ),
          Positioned(
            right: 60, bottom: -20,
            child: _Blob(size: 90, color: AppColors.gold500.withOpacity(isDark ? 0.14 : 0.16)),
          ),
          Positioned(
            left: -30, bottom: 30,
            child: _Blob(size: 70, color: AppColors.coral500.withOpacity(isDark ? 0.10 : 0.08)),
          ),

          // Stars (chỉ dark mode)
          if (isDark) ...[
            const Positioned(left: '50%', top: 30, child: _Star(size: 4, color: Color(0xFFF4CD7A))),
            const Positioned(left: '40%', top: 60, child: _Star(size: 3, color: Colors.white)),
            const Positioned(right: '35%', top: 40, child: _Star(size: 2, color: Color(0xFFF4CD7A))),
          ],

          // Content (z=2)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _buildGreetingText(context)),
                  _buildNotificationBell(context),
                  const SizedBox(width: 8),
                  _buildAvatar(context),
                ],
              ),
              const SizedBox(height: 14),
              _buildSearchBar(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingText(BuildContext context) {
    final greetingText = switch (greeting) {
      UserGreeting.morning => 'Chào buổi sáng,',
      UserGreeting.afternoon => 'Chào buổi chiều,',
      UserGreeting.evening => 'Chào buổi tối,',
      UserGreeting.night => 'Chào buổi đêm,',
    };
    final emoji = switch (greeting) {
      UserGreeting.morning => '☀️',
      UserGreeting.afternoon => '🌤️',
      UserGreeting.evening || UserGreeting.night => '🌙',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greetingText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$userName $emoji',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          _formatDate(DateTime.now()),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.jadeBright.withOpacity(0.20),
                width: 1,
              ),
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
          ),
        ),
        if (unreadNotifications > 0)
          Positioned(
            top: -3, right: -3,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.coral500,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFF0F5A6B), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.coral500.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$unreadNotifications',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            userName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF0F5A6B),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => Navigator.pushNamed(context, '/search'),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.bgSurfaceContainer,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: colors.brand, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tìm phòng tại Hạ Long...',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: colors.brand.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.tune, color: colors.brand, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const weekdays = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
    return '${weekdays[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';
  }
}

// Helper widgets
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Star extends StatelessWidget {
  final double size;
  final Color color;
  const _Star({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.7),
        boxShadow: [
          BoxShadow(color: color, blurRadius: 8, spreadRadius: 1),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .fadeIn(duration: 1500.ms)
     .then()
     .fadeOut(duration: 1500.ms);
  }
}
```

### 6.3 `popular_destinations.dart`

```dart
class PopularDestinations extends StatelessWidget {
  final List<Destination> destinations;

  const PopularDestinations({super.key, required this.destinations});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurfaceElevated,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderDefault, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: isDark ? 24 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '★ ĐIỂM ĐẾN PHỔ BIẾN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: colors.textBrand,
                ),
              ),
              TextButton(
                onPressed: () {/* push search */},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Xem tất cả →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.textBrand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: destinations
                .map((d) => Expanded(child: _DestinationTile(destination: d)))
                .expand((w) => [w, const SizedBox(width: 8)])
                .take(destinations.length * 2 - 1)
                .toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
}

class _DestinationTile extends StatelessWidget {
  final Destination destination;
  const _DestinationTile({required this.destination});

  @override
  Widget build(BuildContext context) {
    final (bgColors, borderColor) = _getThemeColors(destination.theme, context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pushNamed(
        context,
        '/search',
        arguments: {'destination': destination.slug},
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(destination.emoji, style: const TextStyle(fontSize: 22, height: 1)),
            const SizedBox(height: 4),
            Text(
              destination.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${destination.propertyCount} phòng',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: context.colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (List<Color>, Color) _getThemeColors(DestinationTheme theme, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (theme) {
      DestinationTheme.jade => (
        [
          AppColors.jade500.withOpacity(isDark ? 0.18 : 0.10),
          AppColors.jade500.withOpacity(isDark ? 0.06 : 0.02),
        ],
        AppColors.jade500.withOpacity(isDark ? 0.30 : 0.20),
      ),
      DestinationTheme.gold => (
        [
          AppColors.gold500.withOpacity(isDark ? 0.16 : 0.10),
          AppColors.gold500.withOpacity(isDark ? 0.04 : 0.02),
        ],
        AppColors.gold500.withOpacity(isDark ? 0.28 : 0.20),
      ),
      DestinationTheme.coral => (
        [
          AppColors.coral500.withOpacity(isDark ? 0.16 : 0.10),
          AppColors.coral500.withOpacity(isDark ? 0.04 : 0.02),
        ],
        AppColors.coral500.withOpacity(isDark ? 0.28 : 0.20),
      ),
      DestinationTheme.slate => (
        [
          context.colors.borderStrong.withOpacity(0.20),
          context.colors.borderStrong.withOpacity(0.05),
        ],
        context.colors.borderDefault,
      ),
    };
  }
}
```

### 6.4 `voucher_banner_card.dart`

Component pattern: gradient coral + decorative blob + countdown bên phải. Tham khảo Component Specs v2 section 7 (AI Insight Card) để build tương tự — chỉ thay gradient sang coral và content sang voucher info.

### 6.5 `activity_carousel.dart`

```dart
class ActivityCarousel extends StatelessWidget {
  final List<Activity> activities;

  const ActivityCarousel({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: activities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _ActivityCard(activity: activities[i]),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget { /* ... */ }
```

### 6.6 `customer_home_skeleton.dart`

Skeleton variant của tất cả sections, dùng `shimmer` package:

```dart
class CustomerHomeSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Greeting header skeleton (gradient placeholder)
        Container(height: 220, color: colors.bgSurfaceContainer),
        const SizedBox(height: 14),
        // Destinations skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        // Property cards skeleton (3 items)
        ...List.generate(3, (i) => const PropertyCardSkeleton()),
      ],
    );
  }
}
```

---

## 7. API contracts

### 7.1 `GET /customer/home`

**Response 200**:
```json
{
  "userName": "Anh Tuấn",
  "greeting": "evening",
  "unreadNotifications": 3,
  "popularDestinations": [
    {"slug": "bai-chay", "name": "Bãi Cháy", "emoji": "🏖️", "propertyCount": 142, "theme": "jade"},
    ...
  ],
  "personalInsights": [
    {
      "id": "ins_001",
      "type": "suggestion",
      "overline": "GỢI Ý TỪ AI",
      "message": "Bạn từng ở Sea Pearl Halong — có promo 30% cho lần này, hết hạn 23h59 hôm nay.",
      "primaryAction": {"label": "Xem ngay", "routeTarget": "/property/123", "params": {"promo": "SUMMER30"}},
      "secondaryAction": {"label": "Để sau", "routeTarget": null},
      "expiresAt": "2026-04-27T23:59:59Z"
    }
  ],
  "topFeatured": [
    {
      "id": "prop_001",
      "name": "Sea Pearl Bay Villa",
      "city": "Hạ Long",
      "district": "Bãi Cháy",
      "coverImage": "https://...",
      "imageCount": 24,
      "minPricePerNight": 2500000,
      "rating": 4.9,
      "isPremium": true,
      "isHot": true,
      "maxGuests": 6,
      "bedrooms": 3,
      "bathrooms": 2,
      "availabilityHint": "Còn 2 đêm trống cho cuối tuần này"
    }
  ],
  "activeVouchers": [...],
  "activities": [...]
}
```

### 7.2 `POST /customer/insights/{id}/dismiss`

Response 204 No Content.

### 7.3 `POST /customer/wishlist/toggle`

```json
Request: {"propertyId": "prop_001"}
Response 200: {"wishlisted": true, "totalWishlisted": 12}
```

---

## 8. Testing checklist

### 8.1 Unit tests

- [ ] `customerHomeControllerProvider` — fetch success
- [ ] `customerHomeControllerProvider` — fetch error → AsyncError state
- [ ] `customerHomeControllerProvider` — refresh sets loading then data
- [ ] `customerHomeControllerProvider` — dismissInsight optimistic + revert on fail
- [ ] `wishlistControllerProvider` — toggle add/remove
- [ ] `Destination.theme` mapping → correct color set
- [ ] Date format "Thứ Hai, 27 / 04 / 2026"
- [ ] Greeting time mapping (5-11h morning, 11-13h afternoon, ...)

### 8.2 Widget tests

- [ ] `GreetingHeader` renders userName + correct greeting + emoji
- [ ] `GreetingHeader` notification badge hidden when count = 0
- [ ] `GreetingHeader` notification badge shows count
- [ ] `GreetingHeader` tap bell → navigate to /notifications
- [ ] `PopularDestinations` renders 4 tiles
- [ ] `CustomerPropertyCard` Premium ribbon visible when isPremium = true
- [ ] `CustomerPropertyCard` Hot badge visible when isHot = true
- [ ] `CustomerPropertyCard` both badges stacked when isPremium && isHot
- [ ] `AIInsightCard` dismiss → fade out + remove
- [ ] `VoucherBannerCard` countdown shows correct days remaining
- [ ] `CustomerHomeScreen` shows skeleton when AsyncLoading
- [ ] `CustomerHomeScreen` shows error state when AsyncError
- [ ] Pull-to-refresh triggers `refresh()` on controller

### 8.3 Golden tests (visual regression)

- [ ] `customer_home_dark_full.png` — full screen dark mode
- [ ] `customer_home_light_full.png` — full screen light mode
- [ ] `customer_property_card_premium_dark.png`
- [ ] `customer_property_card_hot_dark.png`
- [ ] `greeting_header_dark.png` + `greeting_header_light.png`
- [ ] `voucher_banner_dark.png` + `voucher_banner_light.png`
- [ ] `popular_destinations_dark.png` + `popular_destinations_light.png`

### 8.4 Manual QA — devices

| Device | Test |
|---|---|
| iPhone 15 Pro | Visual + scroll perf |
| iPhone SE | Layout không vỡ ở narrow width |
| iPad mini | Layout grid breakpoint ổn |
| Pixel 8 | Material ripple, animation |
| Galaxy A53 (mid-range) | Perf không drop frame |
| Tablet Android | Landscape mode |

### 8.5 Accessibility audit

- [ ] Run Flutter `accessibility_test_tools` → 0 critical issues
- [ ] iOS Accessibility Inspector → labels read correctly
- [ ] Android TalkBack → swipe order makes sense
- [ ] Increase font size 200% → no layout overflow
- [ ] Color contrast ≥ 4.5:1 cho mọi text

### 8.6 Contrast verification (WebAIM)

| Pair | Light ratio | Dark ratio | Pass |
|---|---|---|---|
| `textPrimary` / `bgSurface` | 16.0 | 14.2 | AAA |
| `textSecondary` / `bgSurface` | 7.4 | 8.5 | AAA |
| `textTertiary` / `bgSurface` | 4.6 | 5.8 | AA |
| `textBrand` / `bgSurface` | 7.8 | 8.2 | AAA |
| `textOnPrimary` / `brand` | 5.2 | 6.0 | AA+ |
| `gold700` / `gold50` | 7.6 | — | AAA |
| `coralBright` / `darkSurface` | — | 7.4 | AAA |

---

## 9. Definition of Done

PR merge khi tất cả ✓:

- [ ] Code review approved bởi 1 senior dev
- [ ] CI pipeline pass (analyze, test, build APK + IPA)
- [ ] Unit + widget test coverage ≥ 70% cho `features/customer_home/`
- [ ] Golden tests pass
- [ ] Manual QA pass trên ít nhất 2 devices (iOS + Android)
- [ ] Screenshot light + dark mode đính kèm trong PR description
- [ ] Performance: Flutter DevTools timeline không có jank > 16ms
- [ ] No new analyzer warnings
- [ ] Accessibility audit pass
- [ ] Updated documentation:
  - [ ] README mention new screen
  - [ ] CHANGELOG.md entry
  - [ ] If new shared widgets → Storybook/Widgetbook entry

---

## 10. Deliverables

Cuối sprint dev nộp:

1. **Code PR** với commits theo convention `feat(customer-home): ...`
2. **Screenshots** light + dark, ≥ 6 ảnh: greeting header, full screen scroll, premium card, hot card, voucher banner, AI insight, skeleton, error state
3. **Demo video** ngắn 30s: launch app → scroll → tap card → pull-to-refresh
4. **Test report** từ CI pipeline (HTML hoặc PDF)
5. **Performance trace** Flutter DevTools (`.cpuprofile` file)
6. **Note technical debt** nếu có (ví dụ: chưa link backend thật, dùng mock data)

---

## Phụ lục — Q&A thường gặp

**Q: Mock data ở đâu trong sprint này?**
A: Tạo file `lib/features/customer_home/data/mock_data.dart` với hard-coded `CustomerHomeData` instance. Repository inject mock khi `kDebugMode == true`.

**Q: Stars trong gradient header bắt buộc không?**
A: P2, có thể skip. Nhưng đẹp hơn rõ rệt ở dark mode → khuyên có.

**Q: Có cần animation pulse cho notification badge không?**
A: P1, dùng `flutter_animate` `.scale(begin: 1, end: 1.1, duration: 800ms, alternate, infinite)` chỉ khi `unreadNotifications > 0`.

**Q: Heart wishlist persist ở đâu?**
A: Sprint này dùng `SharedPreferences` (lưu list propertyId). Sprint sau migrate sang backend `/customer/wishlist`.

**Q: Test heart icon optimistic update?**
A: Widget test: tap icon → assert `isWishlisted == true` ngay lập tức (không đợi async).

**Q: Bottom nav highlight tab nào?**
A: Tab 0 (Trang chủ) selected.

**Q: Status bar màu gì?**
A: `extendBodyBehindAppBar: true` + `SystemUiOverlayStyle.light` (foreground white) — vì gradient header dark.

---

**Phiên bản**: 1.0
**Ngày giao việc**: 27/04/2026
**Sprint deadline**: 5 ngày làm việc
**Reviewer**: Senior Dev + Designer
**Companion docs**: `halong24h-color-system-v2.md`, `halong24h-component-specs-v2.md`, `halong24h-customer-home-mockup.html`
