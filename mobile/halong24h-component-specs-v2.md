# Halong24h — Component Specs v2.0

> Companion document cho **Color System v2.0**.
> Focus: anatomy + state + Flutter skeleton của 10 signature component.
> Dùng kèm với `halong24h-color-system-v2.md`.
>
> Ngày: 27/04/2026
> Phiên bản: 2.0

---

## Mục lục

1. [Tổng quan & cách đọc](#1-tổng-quan--cách-đọc)
2. [Property Card v2 (Customer view)](#2-property-card-v2--customer-view)
3. [Property Card v2 (Manager view)](#3-property-card-v2--manager-view)
4. [Greeting Header gradient](#4-greeting-header-gradient)
5. [Premium Ribbon (NEW)](#5-premium-ribbon-new)
6. [Hot Badge (NEW)](#6-hot-badge-new)
7. [AI Insight Card (NEW signature)](#7-ai-insight-card-new-signature)
8. [Status Strip border-left (NEW signature pattern)](#8-status-strip-border-left-new-signature-pattern)
9. [Live Status Indicator (NEW)](#9-live-status-indicator-new)
10. [Calendar Grid Cell (refresh)](#10-calendar-grid-cell-refresh)
11. [Booking Card v2](#11-booking-card-v2)
12. [Empty / Error State (refresh)](#12-empty--error-state-refresh)
13. [Composition patterns](#13-composition-patterns--cách-ghép-components)
14. [Implementation roadmap](#14-implementation-roadmap)

---

## 1. Tổng quan & cách đọc

### 1.1 Quan hệ với Color System v2

Tài liệu này **không lặp lại color tokens** — mọi tham chiếu màu dạng `colors.brand`, `colors.bgSurface`... đều có trong file `halong24h-color-system-v2.md` section 4 (Component Color Map). Dev cần mở 2 file song song khi build.

### 1.2 Cấu trúc mỗi component spec

```
1. Where used (screen nào)
2. Visual description (anatomy + dimension)
3. State matrix (default, premium, hot, loading...)
4. Spacing / Radius / Shadow tokens
5. Animation
6. Flutter widget skeleton
7. Edge cases
```

### 1.3 Quy ước

- Tất cả dimension dùng `AppSpacing` (xs=4, sm=8, md=16, lg=24, xl=32) và `AppRadius` (xs=4, sm=8, md=12, lg=16, xl=24)
- Mọi màu tham chiếu qua `context.colors.x` (không hardcode)
- Mọi text dùng theme từ `Theme.of(context).textTheme` + override weight nếu cần
- Animation dùng `flutter_animate` package

---

## 2. Property Card v2 — Customer view

### 2.1 Where used

- Customer Home (featured properties section)
- Search Result list
- Wishlist
- Similar properties trong Property Detail
- My Bookings completed (link quay lại property cũ)

### 2.2 Anatomy

```
┌─────────────────────────────────┐  width: full, max 360
│ ╔═══════════════════════════╗  │
│ ║      IMAGE 16:10           ║  │  height: width × 0.625
│ ║                            ║  │
│ ║  [♡ wishlist 32×32]   [📷] ║  │  top-right: image count
│ ║                            ║  │
│ ║                            ║  │
│ ║   [🔥 HOT]                 ║  │  top-left (optional badge)
│ ║                            ║  │
│ ║              [1.500.000đ]  ║  │  bottom-right: price pill
│ ╚════════════════════════════╝  │
│                                  │
│  Phòng View Vịnh           ★4.8 │  title w800 size 17 + rating
│  Sea Pearl Halong, Hạ Long      │  location w600 muted size 12
│                                  │
│  [👥 4]  [🛏 2]  [🚿 1]           │  info chips row
│                                  │
│  💰 1.500.000đ / đêm    [→ Xem] │  price footer + CTA chevron
└─────────────────────────────────┘
```

Padding info section: `AppSpacing.md` (16px)
Gap giữa rows: `AppSpacing.sm` (8px)

### 2.3 State matrix

| State | Trigger | Visual change |
|---|---|---|
| `default` | normal | Border `borderDefault`, no badge |
| `premium` | `property.isPremium == true` | Border `borderGold` (2px), Premium ribbon top-left float |
| `hot` | `property.isHot == true` (booking velocity high) | Hot badge top-left absolute trong image |
| `wishlisted` | `wishlist.contains(propertyId)` | Heart icon filled coral |
| `loading` | data đang tải | Skeleton variant |
| `pressed` | tap đang giữ | scale 0.97 |
| `unavailable` | hết phòng cho dates đang search | Overlay grey 40%, text "Hết phòng" |

> **Lưu ý**: `premium` và `hot` có thể **đồng thời** — Premium ribbon top-left **góc trên cùng**, Hot badge ngay dưới (offset 32px). Không hiển thị cả 2 trong cùng vị trí.

### 2.4 Color tokens

Tham chiếu Color System v2 section 4.4 (Card Room/Property). Bổ sung cho variants v2:

| Variant | Border | Shadow |
|---|---|---|
| Default | `colors.borderDefault` | `0 6px 20px rgba(15,23,42, 0.06)` light / `0 4px 18px rgba(0,0,0, 0.30)` dark |
| Premium | `colors.borderGold` (2px) | `0 6px 20px rgba(229,181,71, 0.18)` light / `rgba(229,181,71, 0.30)` dark |
| Hot | `colors.borderDefault` (badge nổi, không cần border accent) | giữ default shadow |

### 2.5 Spacing & Radius

```dart
// Container ngoài
borderRadius: BorderRadius.circular(24),  // xl
padding: EdgeInsets.zero,                 // image edge-to-edge

// Image section
aspectRatio: 16 / 10,
borderRadius: BorderRadius.vertical(
  top: Radius.circular(24),
),

// Info section
padding: EdgeInsets.all(16),  // md
spacing: 8 (sm) giữa rows
```

### 2.6 Animation

```dart
// Entry (khi list load)
.fadeIn(duration: 300.ms)
.slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic, delay: (index * 80).ms)

// Tap feedback
AnimatedScale(
  scale: _isPressed ? 0.97 : 1.0,
  duration: 120.ms,
  curve: Curves.easeOut,
)

// Wishlist tap (heart icon)
.scale(begin: Offset(1, 1), end: Offset(1.3, 1.3), duration: 200.ms)
.then().scale(begin: Offset(1.3, 1.3), end: Offset(1, 1), duration: 200.ms)
```

### 2.7 Flutter widget skeleton

```dart
class CustomerPropertyCard extends ConsumerWidget {
  final Property property;
  final int index;
  final VoidCallback? onTap;

  const CustomerPropertyCard({
    super.key,
    required this.property,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isWishlisted = ref.watch(wishlistProvider).contains(property.id);

    final borderColor = property.isPremium
        ? colors.borderGold
        : colors.borderDefault;
    final borderWidth = property.isPremium ? 2.0 : 1.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: property.isPremium
                  ? AppColors.gold500.withOpacity(0.18)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(context, isWishlisted),
            _buildInfoSection(context),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, end: 0, delay: (index * 80).ms);
  }

  Widget _buildImageSection(BuildContext context, bool isWishlisted) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        children: [
          // Image
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: property.coverImage,
              fit: BoxFit.cover,
              placeholder: (_, __) => const PropertyImageSkeleton(),
            ),
          ),
          // Bottom gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          // Hot badge top-left (if hot)
          if (property.isHot)
            Positioned(top: 8, left: 8, child: HotBadge()),
          // Premium ribbon top-left (if premium, offset if also hot)
          if (property.isPremium)
            Positioned(
              top: property.isHot ? 40 : 8,
              left: 8,
              child: PremiumRibbon(),
            ),
          // Wishlist heart top-right
          Positioned(
            top: 8,
            right: 8,
            child: WishlistButton(propertyId: property.id),
          ),
          // Image count badge
          Positioned(
            top: 8,
            right: 52, // offset cho heart
            child: ImageCountBadge(count: property.images.length),
          ),
          // Price pill bottom-right
          Positioned(
            bottom: 8,
            right: 8,
            child: PricePill(price: property.minPricePerNight),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + rating
          Row(
            children: [
              Expanded(
                child: Text(
                  property.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (property.rating != null) RatingBadge(rating: property.rating!),
            ],
          ),
          const SizedBox(height: 4),
          // Location
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: colors.brand),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${property.propertyName}, ${property.city}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Info chips
          Row(
            children: [
              InfoChip(icon: Icons.people, text: '${property.maxGuests}'),
              const SizedBox(width: 8),
              InfoChip(icon: Icons.bed, text: '${property.bedrooms}'),
              const SizedBox(width: 8),
              InfoChip(icon: Icons.bathtub, text: '${property.bathrooms}'),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 2.8 Edge cases

- **Image fail load** → fallback gradient `colors.brand → colors.brandLight` + icon `home_outlined` white center
- **Property name dài hơn 1 dòng** → ellipsis, không wrap
- **Property `unavailable`** cho date search → overlay grey 40% + text "Hết phòng" center, opacity card 70%, disable tap

---

## 3. Property Card v2 — Manager view

### 3.1 Where used

- Property Management (list của owner)
- Admin view all properties

### 3.2 Khác biệt với Customer view

Manager cần thấy data vận hành thay vì marketing:

| Customer view | Manager view |
|---|---|
| Hot badge / Premium ribbon | **Status pill** (Hoạt động / Tạm nghỉ / Bảo trì) |
| Wishlist heart | **Settings menu** (3-dot) — Edit / Disable / Delete |
| Price pill = giá hiện tại | Price pill + **occupancy %** ngay bên |
| Rating ★4.8 | Rating ★4.8 + **số booking đang active** |
| Footer: CTA "Xem" | Footer: 4 stat (today bookings, this week revenue, available rooms, pending) |

### 3.3 Anatomy

```
┌─────────────────────────────────┐
│ ╔═══════════════════════════╗  │
│ ║      IMAGE 16:10           ║  │
│ ║  [● Hoạt động]      [⋯]    ║  │  status pill + menu
│ ║                            ║  │
│ ║  [📷 12]                   ║  │  image count
│ ║                            ║  │
│ ║              [1.500.000đ]  ║  │
│ ║              [78% lấp đầy] ║  │  occupancy chip
│ ╚════════════════════════════╝  │
│                                  │
│  Sea Pearl Halong          ★4.8 │
│  PROP-007 · Hạ Long, Bãi Cháy   │  property code chip + city
│                                  │
│  ┌─ Mini stats grid ────────┐   │
│  │ [🏠 8]    [📅 6]          │   │  rooms / bookings today
│  │ [💰 12tr] [⚠ 2]           │   │  revenue week / pending
│  └──────────────────────────┘   │
│                                  │
│  [Quản lý phòng →]              │  CTA primary
└─────────────────────────────────┘
```

### 3.4 State matrix

| State | Visual |
|---|---|
| `active` | Status pill xanh `colors.success` |
| `paused` | Status pill amber `colors.warning` + image opacity 70% |
| `maintenance` | Status pill slate `colors.borderStrong` + slash overlay nhẹ image |
| `pendingApproval` | Status pill jade `colors.brand` + ribbon "Chờ duyệt" |

### 3.5 Mini stats grid

Layout 2×2, gap 8px. Mỗi stat:
- Icon container 28×28, radius 8, bg `rgba(brand, 0.10)` light / `rgba(brand, 0.18)` dark
- Number w800 size 16
- Label w600 size 10 muted

Stat items:
1. Số phòng tổng (`brand` icon)
2. Booking hôm nay (`gold` icon)
3. Doanh thu tuần (`success` icon)
4. Pending action (`warning` icon, màu coral nếu count > 0)

### 3.6 Edge cases

- Property mới tạo (không có booking) → mini stats hiển thị "Chưa có dữ liệu" placeholder
- Property bị admin disable → toàn card opacity 50%, badge đỏ "Bị tạm khoá" thay status pill

---

## 4. Greeting Header gradient

### 4.1 Where used

- Customer Home (top of screen)
- Manager Dashboard (top)
- My Bookings (top, smaller variant)
- Property Management (top, smaller variant)

### 4.2 Anatomy

```
╔══════════════════════════════════╗  width: full
║                                  ║  height: 200-260
║   Chào buổi sáng,            🔔  ║  greeting + bell + avatar
║   Anh Tuấn 👋          [A]       ║  
║   Thứ Hai, 27 / 04 / 2026         ║
║                                  ║
║   ┌──────────────────────────┐   ║
║   │ 🔍 Tìm phòng tại Hạ Long │   ║  search bar nổi (nếu có)
║   └──────────────────────────┘   ║
║                                  ║
╚══════════════════════════════════╝  bottom corners 28
       ↓ (overlap với content -42)
```

### 4.3 Layers (z-order)

1. **Background**: linear gradient `colors.brand → colors.brandLight` (theme-aware)
2. **Decorative blob 1**: white 6% alpha, position absolute top-right, 180×180 circle, offset (-50, -30)
3. **Decorative blob 2**: gold 16% alpha, position absolute bottom-right, 90×90 circle, offset (60, -20)
4. **Decorative blob 3** (optional): white 5% alpha, position absolute bottom-left, 70×70
5. **Content**: greeting + bell + avatar (z=2, position relative)
6. **Search bar nổi** (optional): white surface với shadow, radius full, position absolute bottom

### 4.4 Tokens

```dart
// Container
height: search bar shown ? 240 : 180
padding: EdgeInsets.fromLTRB(16, statusBarHeight + 14, 16, 56)
// (padding-bottom 56 để search bar nổi đè 1/2)

// Border radius
borderRadius: BorderRadius.vertical(bottom: Radius.circular(28))

// Background gradient
gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [colors.brand, colors.brandLight],  // theme-aware
)

// Text
greeting: rgba(255,255,255, 0.85), w600, size 12-14
name: white, w800, size 22
date: rgba(255,255,255, 0.85), w600, size 11

// Bell button
size 38×38, radius 12, bg rgba(255,255,255, 0.18)
backdrop-filter: blur(10px)  // optional iOS-feel

// Bell badge dot
size 16×16 (min), bg colors.brandWarm (coral), border 2px brand
text white w800 size 9
position: top -3, right -3

// Avatar
size 38×38, radius full, bg white, text colors.brand w800 size 14
shadow: 0 2px 8px rgba(0,0,0, 0.15)
```

### 4.5 Search bar nổi (variant)

Khi có search bar, header cao thêm 60px. Search bar:

```dart
Positioned(
  bottom: 0,
  left: 16,
  right: 16,
  child: Transform.translate(
    offset: const Offset(0, -56 + 24),  // overlap header
    child: Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
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
          // Filter icon trong rounded square
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.brand.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.tune, color: colors.brand, size: 16),
          ),
        ],
      ),
    ),
  ),
)
```

### 4.6 Animation

- Header **không animation entry** (visible from frame 1, không jarring)
- Greeting text staggered: `.fadeIn(300ms)` → `.slideX(begin: -0.1)`
- Bell badge **pulse infinite** (chỉ khi có unread): `.scale(begin: 1, end: 1.1, duration: 800ms, infinite, alternate)`
- Avatar **scale on tap**: 0.92, duration 120ms

### 4.7 Edge cases

- Tên user dài → max 1 line ellipsis, font-size scale xuống 18 nếu cần
- Avatar không có ảnh → initial chữ cái đầu, gradient theo `colors.brand`
- Status bar dark/light auto: brightness `Brightness.light` (foreground white) khi gradient dùng

---

## 5. Premium Ribbon (NEW)

### 5.1 Where used

- Property Card top-left khi `property.isPremium`
- Room Card khi room thuộc tier premium
- Special offer cards trong Customer Home featured section

### 5.2 Anatomy

Ribbon nhỏ floating, KHÔNG phải badge vuông thông thường.

```
   ╱ ★ Premium ╲
  ╱──────────────╲
```

Hoặc đơn giản hơn (recommend):

```
[★ PREMIUM]
```

Pill shape, gradient gold.

### 5.3 Tokens

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.gold500, AppColors.gold300],  // light + dark giữ nguyên gradient
    ),
    borderRadius: BorderRadius.circular(100),
    boxShadow: [
      BoxShadow(
        color: AppColors.gold500.withOpacity(0.35),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.star, size: 9, color: Color(0xFFFFFFFF)),
      const SizedBox(width: 3),
      Text(
        'PREMIUM',
        style: TextStyle(
          color: const Color(0xFFFFFFFF),  // white cả 2 theme
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    ],
  ),
)
```

### 5.4 Variants

| Variant | Khi dùng |
|---|---|
| `PREMIUM` (default) | Property thuộc tier cao cấp, owner trả phí premium listing |
| `LUXURY` | Tier cao hơn premium |
| `EDITOR'S CHOICE` | Admin curate manually |

### 5.5 Animation

- Khi card xuất hiện: `.scale(begin: 0.8, end: 1, duration: 400ms, curve: Curves.elasticOut, delay: 200ms)`
- Subtle shine animation infinite (optional, low priority): gradient sweep ngang qua ribbon mỗi 4s

---

## 6. Hot Badge (NEW)

### 6.1 Where used

- Property Card top-left khi `property.isHot` (booking velocity cao trong 7 ngày)
- Search result properties trending
- Notification "Phòng đang hot"

### 6.2 Anatomy

```
[🔥 HOT]
```

Pill solid coral, KHÔNG gradient (giữ tone "warm urgent" mạnh).

### 6.3 Tokens

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: context.colors.brandWarm,  // coral500 light, coralBright dark
    borderRadius: BorderRadius.circular(100),
    boxShadow: [
      BoxShadow(
        color: AppColors.coral500.withOpacity(0.30),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('🔥', style: const TextStyle(fontSize: 10)),
      const SizedBox(width: 3),
      Text(
        'HOT',
        style: TextStyle(
          color: context.colors.textOnCoral,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    ],
  ),
)
```

### 6.4 Variants

| Variant | Trigger |
|---|---|
| `HOT` | Bookings trong 7 ngày tăng > 200% so với 7 ngày trước |
| `MỚI` | Property tạo trong 14 ngày (text "MỚI" thay 🔥) |
| `−20%` | Có voucher giảm giá active (text "−X%" thay 🔥, font-size lớn hơn) |
| `CHỈ CÒN N PHÒNG` | Inventory thấp cho date search |

### 6.5 Animation

- Subtle bounce infinite: `.shimmer(duration: 2000ms, infinite)` hoặc:
- `.scale(begin: 1, end: 1.05, duration: 600ms, curve: Curves.easeInOut, infinite, alternate)` — pulse chậm

> Animation nên **rất nhẹ** — Hot badge đã đủ nổi, animation mạnh sẽ làm card cảm giác spam/thiếu trang trọng.

---

## 7. AI Insight Card (NEW signature)

### 7.1 Where used

Đây là **brand identity** của app v2 — phải có ở mọi screen có aggregated data:

- Customer Home — gợi ý property phù hợp
- Manager Dashboard — gợi ý hành động (tăng giá cuối tuần, gửi voucher)
- Property Detail Manager — gợi ý optimize giá / amenity
- Booking List — gợi ý chăm sóc khách quay lại
- Reports — gợi ý insight từ data
- Pricing rules editor — gợi ý price phù hợp thị trường

### 7.2 Anatomy

```
┌─────────────────────────────────────┐
│ ┌──┐                                │
│ │✨│  GỢI Ý TỪ AI                   │
│ └──┘  ─────────────                 │
│       12 khách quen chưa quay lại   │  body w700 size 12
│       sau 90 ngày — gửi voucher     │
│       giảm 15% cuối tuần?           │
│                                      │
│       [Gửi ngay]  [Xem danh sách]   │  CTA filled gold + outlined gold
└─────────────────────────────────────┘
```

### 7.3 Tokens

```dart
Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.gold500.withOpacity(theme.brightness == Brightness.dark ? 0.20 : 0.12),
        AppColors.gold300.withOpacity(theme.brightness == Brightness.dark ? 0.08 : 0.04),
      ],
    ),
    border: Border.all(
      color: AppColors.gold500.withOpacity(theme.brightness == Brightness.dark ? 0.45 : 0.30),
      width: 1,
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Icon container
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppColors.gold500,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold500.withOpacity(0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 11),
      // Content
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GỢI Ý TỪ AI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: context.colors.textBrandAccent,  // gold700 light, goldBright dark
              ),
            ),
            const SizedBox(height: 3),
            Text(
              insight.message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Buttons row
            Row(
              children: [
                _ActionButton.filled(
                  label: 'Gửi ngay',
                  onTap: () => _executeAction(),
                ),
                const SizedBox(width: 6),
                _ActionButton.outlined(
                  label: 'Xem danh sách',
                  onTap: () => _showDetail(),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
)
```

### 7.4 Variants by data type

| Variant | Icon | When |
|---|---|---|
| `suggestion` | `auto_awesome` ✨ | Hành động đề xuất (default) |
| `alert` | `warning_amber` ⚠ | Cảnh báo cần xem ngay (vẫn dùng gold border, không đổi sang error red) |
| `opportunity` | `trending_up` 📈 | Cơ hội tăng doanh thu |
| `info` | `lightbulb` 💡 | Thông tin hữu ích, không cần action |

### 7.5 State

- Default: hiện đầy đủ
- `dismissed`: user dismiss → fade out + slide up + remove from list, lưu `dismissedAt` để không show lại trong 7 ngày
- `actioned`: user đã click "Gửi ngay" → card thay thành success state với icon check + "Đã gửi voucher cho 12 khách"

### 7.6 Animation

```dart
// Entry
.fadeIn(duration: 400.ms)
.slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic)

// Icon container subtle floating
.shimmer(duration: 3000.ms, color: Colors.white.withOpacity(0.3), infinite)

// Sau khi user actioned
AnimatedSwitcher(
  duration: 300.ms,
  child: actioned ? SuccessVariant(...) : SuggestionVariant(...),
)

// Dismiss
.fadeOut(duration: 200.ms).slideY(begin: 0, end: -0.2)
```

### 7.7 Backend / data flow

```dart
// AsyncNotifier
@riverpod
class AIInsightsController extends _$AIInsightsController {
  @override
  Future<List<AIInsight>> build({required InsightContext ctx}) async {
    // ctx: dashboard, propertyDetail, customerHome, ...
    final response = await ref.read(insightRepositoryProvider).fetch(ctx);
    return response.where((i) => !_isDismissed(i.id)).toList();
  }

  Future<void> dismiss(String insightId) async {
    await ref.read(insightRepositoryProvider).dismiss(insightId);
    state = AsyncData(state.value!.where((i) => i.id != insightId).toList());
  }

  Future<void> execute(AIInsight insight) async {
    state = AsyncLoading();
    final result = await ref
        .read(insightRepositoryProvider)
        .executeAction(insight);
    // optimistic update with success state
    state = AsyncData([
      insight.copyWith(actionedResult: result),
      ...state.value!.where((i) => i.id != insight.id),
    ]);
  }
}
```

Backend rules đơn giản (server-side cron):
- "Gửi voucher khách quay lại": query `guests where lastStay > 90 days AND totalStays >= 2 AND tag != at_risk_dismissed`
- "Tăng giá cuối tuần": phát hiện 80%+ occupancy 4 cuối tuần liền + giá hiện tại < market
- "Khách VIP đang ở": realtime check `bookings where guest.tag = vip AND status = checkedIn`

### 7.8 Edge cases

- Không có insight → ẩn card hoàn toàn (đừng show "Chưa có gợi ý"). Card chỉ tồn tại khi có giá trị.
- Insight đang loading → mini skeleton variant (40px high, không hiện full card)
- Action fail → toast error, card revert về suggestion state

---

## 8. Status Strip border-left (NEW signature pattern)

### 8.1 Where used

Pattern này **xuất hiện rất nhiều**:

- Booking card "Sắp đến: 27/04 · Lavender View"
- Booking detail "Đã thu cọc 1tr"
- Customer profile "Đang ở · check-out 12:00"
- Notification item context
- Activity feed
- Property card "Còn 2 phòng cho ngày bạn chọn"

### 8.2 Anatomy

```
┌▌─────────────────────────────────┐  border-left 3px color
│▌ [icon] Text quan trọng nhất    │  
└▌─────────────────────────────────┘
```

Container chứa: icon trái (size 14, color = strip color) + text 1 dòng (size 11, weight 700, color textPrimary) + optional highlight word.

### 8.3 Tokens

```dart
class StatusStrip extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? highlight;  // optional, sẽ render bằng colors.brand
  final SemanticColor variant; // success, warning, error, info, brand

  // Build
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = _getColor(colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.02),
          ],
        ),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(0),
          bottomLeft: Radius.circular(0),
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                children: [
                  TextSpan(text: _beforeHighlight(text, highlight)),
                  if (highlight != null)
                    TextSpan(
                      text: highlight,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  TextSpan(text: _afterHighlight(text, highlight)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(AppColorScheme colors) => switch (variant) {
        SemanticColor.success => colors.success,
        SemanticColor.warning => colors.warning,
        SemanticColor.error => colors.error,
        SemanticColor.brand => colors.brand,
        SemanticColor.info => colors.brand,
      };
}
```

### 8.4 Variants

| Variant | Khi dùng | Example |
|---|---|---|
| `success` (xanh) | Đã làm xong, dương tính | "Đã thu cọc 1tr" |
| `warning` (cam) | Cần chú ý nhưng chưa critical | "Khách chưa check-in, đã trễ 30 phút" |
| `error` (đỏ) | Có vấn đề | "Booking conflict với P02" |
| `brand` (jade) | Thông tin context | "Sắp đến: 27/04 · Lavender View" |
| `accent` (gold) | Premium / VIP context | "Khách VIP — Lần 4 ở" |

### 8.5 Animation

- Entry trong card: `.fadeIn(200ms).slideX(begin: -0.05)`
- Không cần exit/state animation phức tạp

---

## 9. Live Status Indicator (NEW)

### 9.1 Where used

- "Đang cập nhật" trong Dashboard
- "Đang chờ thanh toán" trong Checkout QR
- "Đang ở" trong Booking Detail (khách đang check-in)
- "Realtime sync" trong Calendar Owner
- "X người đang xem property này" — social proof Customer Home

### 9.2 Anatomy

```
[●] Đang chờ khách quét...
 ↑ pulse dot
```

Dot 6-8px + glow ring + text bên cạnh.

### 9.3 Tokens

```dart
class LiveDot extends StatefulWidget {
  final SemanticColor variant;  // success, warning, brand
  final String? label;
  final double size;

  // ...
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(context.colors);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size + 12,
          height: widget.size + 12,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse ring
                  Container(
                    width: widget.size + (_controller.value * 8),
                    height: widget.size + (_controller.value * 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.25 * (1 - _controller.value)),
                    ),
                  ),
                  // Solid dot
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(width: 6),
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}
```

### 9.4 Variants

| Variant | Color | Use |
|---|---|---|
| `success` | green | "Online" / "Connected" / "Sync xong" |
| `warning` | amber | "Đang chờ action" / "Awaiting payment" |
| `brand` | jade | "Đang xem" / "Live data" |

### 9.5 Performance

- AnimationController dùng `vsync` từ State với `SingleTickerProviderStateMixin`
- Khi widget không visible (scroll out of viewport) → pause animation:

```dart
@override
Widget build(BuildContext context) {
  return VisibilityDetector(
    key: Key('live-dot-${widget.label}'),
    onVisibilityChanged: (info) {
      if (info.visibleFraction > 0) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    },
    child: ...,
  );
}
```

---

## 10. Calendar Grid Cell (refresh)

### 10.1 Where used

- `CalendarGridWidget` — Owner Calendar, Property Calendar, Booking Calendar, Customer date picker

### 10.2 Anatomy mỗi cell

```
┌────────────┐
│            │
│    27      │  ← number, w700/w800 if today
│   ●        │  ← status dot bottom
│            │
└────────────┘
size: 1/7 width × 1/7 (square hoặc tỉ lệ tuỳ height)
```

### 10.3 4 cell states

| State | Background | Number color | Dot | Notes |
|---|---|---|---|---|
| `vacant` | `colors.successBg` | `colors.textPrimary` | 4×4 dot `colors.success` | Còn trống, có thể đặt |
| `booked/hold` | amber bg | `colors.textPrimary` | dot amber | Đã có người giữ |
| `occupied` | jade bg light | `colors.textPrimary` | dot brand | Khách đang ở |
| `maintenance` | slate bg + slash pattern | `colors.textTertiary` | dot slate | Bảo trì |

### 10.4 Modifier states (overlay)

- `today`: ring 2px `colors.brand` quanh cell
- `selected`: border 2px `colors.brand` (filled không thay đổi)
- `weekend`: number color `#1976D2` (light) / `#60A5FA` (dark)
- `holiday`: number color `#E65100` (light) / `#FB923C` (dark)
- `range start/end` (date picker): bg solid `colors.brand`, number white
- `in range`: bg `colors.brand` 30% alpha, number white

### 10.5 Tokens & build

```dart
class CalendarCell extends StatelessWidget {
  final DateTime date;
  final RoomDayStatus status;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;
  final bool isHoliday;
  final RangeState? rangeState;  // start, inRange, end

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, dotColor) = _getStatusColors(colors);
    final numberColor = _getNumberColor(colors);

    return AnimatedContainer(
      duration: 200.ms,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: colors.brand, width: 2)
            : null,
        // Today ring
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: colors.brand.withOpacity(0.0),
                  spreadRadius: 2,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Slash pattern cho maintenance
          if (status == RoomDayStatus.maintenance)
            Positioned.fill(child: SlashPatternPainter()),
          // Number center
          Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
                color: numberColor,
              ),
            ),
          ),
          // Status dot
          Positioned(
            bottom: 4,
            left: 0, right: 0,
            child: Center(
              child: Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 10.6 Slash pattern cho maintenance

```dart
class SlashPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.slate400.withOpacity(0.16)
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width + size.height; i += 6) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }
}
```

---

## 11. Booking Card v2

### 11.1 Where used

- Booking List (manager + customer)
- Recent activity Dashboard
- Notification deeplink target

### 11.2 Anatomy

```
┌──────────────────────────────────────┐
│ ▌[Avatar M]  Nguyễn Thị Mai          │  ← left status rail 3px
│ ▌            #BK0247 · Lavender View │
│ ▌                          [XÁC NHẬN]│
│ ▌                                    │
│ ▌  ┌────────────────────────────┐   │
│ ▌  │ 27/04 · 14:00  →  30/04 · 12:00│  status strip / time
│ ▌  └────────────────────────────┘   │
│ ▌                                    │
│ ▌  💰 2.850.000đ · Đã thu cọc 1tr · 2 khách
│ ▌                                    │
│ ▌  [Check-in]  [Chi tiết]  [⋯]      │
└──────────────────────────────────────┘
```

Border-left rail 3px màu theo status booking (xanh/cam/đỏ/tím).

### 11.3 State matrix

Tương ứng booking status:

| Status | Rail color | Background | Avatar gradient |
|---|---|---|---|
| `confirmed` | `#22C55E` | bg success very light | green gradient |
| `hold` | `#F59E0B` | bg amber very light | amber gradient |
| `cancelled` | `#EF4444` | bg error very light + opacity 70% | red gradient |
| `completed` | `#7B1FA2` | white | purple gradient |
| `pending` | `colors.brand` | bg jade50 | brand gradient |

### 11.4 Avatar gradient (từ Color System v2 section 3.7 archetype)

Generate từ first letter của tên + status:

```dart
LinearGradient _avatarGradient(String name, BookingStatus status) {
  switch (status) {
    case BookingStatus.confirmed:
      return const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)]);
    case BookingStatus.hold:
      return const LinearGradient(colors: [Color(0xFFFFA726), Color(0xFFFB8C00)]);
    case BookingStatus.completed:
      return const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)]);
    case BookingStatus.cancelled:
      return const LinearGradient(colors: [Color(0xFFB0BEC5), Color(0xFF90A4AE)]);
    case BookingStatus.pending:
      return LinearGradient(colors: [AppColors.jade500, AppColors.jade300]);
  }
}
```

### 11.5 Time strip giữa card

Pattern Status Strip (section 8) variant brand:

```
┌▌──────────────────────────────────┐
│▌ 🕐 27/04 · 14:00  →  30/04 · 12:00│
└▌──────────────────────────────────┘
```

Arrow `→` size 14, color `colors.brand`. Format giờ kèm ngày để Owner check timing nhanh.

### 11.6 Customer view variant

Customer **không thấy**:
- Booking code `#BK0247` (thay bằng "Mã đặt phòng: BK0247" nhỏ ở dưới)
- "Đã thu cọc" detail (chỉ "Đã đặt cọc")
- Action menu 3-dot (admin actions)
- Status pill placement: top-right thay vì float

Customer **thấy thêm**:
- Property image thumbnail nhỏ 40×40 trái
- "Còn X ngày nữa" countdown nếu booking sắp tới
- "Để lại đánh giá" CTA nếu booking completed chưa review

---

## 12. Empty / Error State (refresh)

### 12.1 Pattern v2 — illustration thay vì icon

App v1 hiện dùng icon trong circle. App v2 nâng lên: **SVG illustration nhỏ** từ undraw.co repaint sang palette v2.

### 12.2 Anatomy

```
              ┌─────────────────┐
              │                 │
              │   [SVG illust]  │  ← 160×120 illustration
              │                 │
              └─────────────────┘
              
                  Chưa có phòng nào
              ────────────────────────       title w700 size 16
              
            Hãy thêm phòng đầu tiên của bạn  subtext muted size 13
            
                  [+ Thêm phòng]              CTA optional
```

### 12.3 Illustrations cần (10 SVG asset)

| Asset name | Trigger |
|---|---|
| `empty_rooms.svg` | Property chưa có phòng nào |
| `empty_bookings_owner.svg` | Owner chưa có booking |
| `empty_bookings_customer.svg` | Customer chưa đặt phòng |
| `empty_search.svg` | Search không có kết quả |
| `empty_wishlist.svg` | Wishlist trống |
| `empty_notifications.svg` | Không có thông báo |
| `error_network.svg` | Mất mạng |
| `error_server.svg` | Lỗi server |
| `error_404.svg` | Không tìm thấy |
| `success_booking.svg` | Đặt phòng thành công (cho confirmation screen) |

### 12.4 Repaint rules

Mỗi SVG illustration repaint với rules:

- Primary stroke/fill: `colors.brand` (jade500/jadeBright)
- Secondary fill: `colors.brandLight` (jade300)
- Accent: `colors.brandSecondary` (gold500)
- Background fill: `colors.bgSurfaceContainer`
- Highlight (eyes, smile, important detail): `colors.brandWarm` (coral500)

Dev: dùng package `flutter_svg` + override color qua `theme.dart`:

```dart
SvgPicture.asset(
  'assets/illustrations/empty_search.svg',
  width: 160,
  height: 120,
  colorFilter: ColorFilter.mode(
    context.colors.brand,
    BlendMode.srcIn,
  ),
)
```

> **Lưu ý**: nếu không có budget designer, **temporary fallback** giữ icon trong circle pattern v1 cũng OK. Đây là P2 không block ship.

### 12.5 Error state với retry

```dart
ErrorState(
  illustration: 'error_network.svg',
  title: 'Mất kết nối',
  subtitle: 'Hãy kiểm tra lại internet và thử lại',
  retry: () => ref.invalidate(propertyListProvider),
  retryLabel: 'Thử lại',
)
```

Retry button: `FilledButton.icon` color `colors.error`, white text, icon refresh.

### 12.6 Animation

```dart
// Illustration entry
.scale(begin: Offset(0.7, 0.7), end: Offset(1, 1), curve: Curves.elasticOut, duration: 600.ms)
.fadeIn(duration: 400.ms)

// Title cascade
.fadeIn(duration: 300.ms, delay: 200.ms)
.slideY(begin: 0.2, end: 0, delay: 200.ms)

// Subtitle
.fadeIn(duration: 300.ms, delay: 350.ms)

// CTA
.fadeIn(duration: 300.ms, delay: 500.ms)
```

---

## 13. Composition patterns — cách ghép components

### 13.1 Nguyên tắc layout 1 screen

Mỗi screen nên có **3 tầng visual hierarchy**:

1. **Hero element** (1-2 cái max) — Greeting Header gradient hoặc Hero Stat Card
2. **Content blocks** (3-6) — Cards với border subtle, padding md
3. **Detail / micro components** — Status strip, info chip, badge

KHÔNG dùng quá nhiều hero element cùng screen → visual fatigue.

### 13.2 Spacing giữa sections

```
Header gradient (no margin top)
    ↓ -42px (overlap pattern, nếu có)
First content card
    ↓ AppSpacing.lg (24)
Section heading
    ↓ AppSpacing.sm (8)
Section content
    ↓ AppSpacing.md (16) hoặc lg (24)
Next section heading
    ...
Bottom nav (auto)
```

Bottom padding cuối screen: `AppSpacing.xl + bottomNavHeight` để content không bị che.

### 13.3 Card stacking rules

KHÔNG nest card trong card. Nếu cần "card trong card":
- Outer = container không border, padding md
- Inner = real card với border + radius

Khi list cards:
- Gap giữa cards = `AppSpacing.md` (16)
- KHÔNG dùng Divider giữa card nổi (dùng spacing thay)
- Divider chỉ dùng giữa items trong cùng 1 card

### 13.4 Combo recommended

| Combo | Khi dùng |
|---|---|
| Hero gradient + KPI grid + AI insight | Dashboard, top of Customer Home |
| Property card + Status strip + Hot badge | Search result featured |
| Booking card với rail + time strip | Booking list |
| Empty illustration + AI suggestion CTA | "Chưa có phòng nào — Để AI gợi ý setup?" |
| Live dot + Status pill | Real-time data screens |

---

## 14. Implementation roadmap

### 14.1 Sprint 1 — Foundation (1-2 ngày)

Sau khi áp Color System v2 xong:

- [ ] Tạo widget `PremiumRibbon` + `HotBadge` (file `shared/widgets/badges.dart`)
- [ ] Tạo widget `StatusStrip` với 5 variants (file `shared/widgets/status_strip.dart`)
- [ ] Tạo widget `LiveDot` với pulse animation (file `shared/widgets/live_dot.dart`)
- [ ] Tạo widget `AIInsightCard` reusable (file `shared/widgets/ai_insight_card.dart`)
- [ ] Tạo `AIInsightsController` Riverpod base (file `features/ai_insights/controllers/ai_insights_controller.dart`)

### 14.2 Sprint 2 — Refresh signature components (2-3 ngày)

- [ ] Refactor `PropertyCard` → tách `CustomerPropertyCard` + `ManagerPropertyCard` (2 widgets riêng)
- [ ] Refactor `RoomCard` áp dụng style mới
- [ ] Refactor `BookingCard` áp pattern rail + time strip
- [ ] Refactor `GreetingHeader` thêm decorative blobs (3 blob layered)
- [ ] Refactor `CalendarCell` 4 states + modifiers (today/selected/weekend/range)

### 14.3 Sprint 3 — New patterns trên screens hiện có (3-4 ngày)

Áp Status Strip + AI Insight Card vào screens hiện có:

- [ ] Dashboard: thêm AI Insight Card section
- [ ] Customer Home: thêm AI suggestion (gợi ý property)
- [ ] Property Detail: thêm Status Strip "Còn X phòng cho ngày bạn chọn"
- [ ] Booking List: rail border-left theo status
- [ ] Booking Detail: nhiều Status Strip context (đã thu cọc, sắp đến, etc.)
- [ ] Customer profile: Live dot "Đang ở"

### 14.4 Sprint 4 — Empty/Error refresh (1 ngày, P2 — có thể làm sau)

- [ ] Source 10 SVG illustrations (undraw.co + repaint)
- [ ] Build `EmptyState` + `ErrorState` widget reusable
- [ ] Replace ở mọi screen có empty state hiện tại

### 14.5 Sprint 5 — QA + polish (1-2 ngày)

- [ ] Test mọi widget mới ở light + dark
- [ ] Test animation perf trên device thấp (Android 8, iPhone 8)
- [ ] Audit accessibility — VoiceOver/TalkBack đọc đúng
- [ ] Document Storybook (nếu team có) cho 10 widget mới

### 14.6 Tổng workload

| Phase | Time | Người |
|---|---|---|
| Foundation widgets | 1.5 ngày | 1 dev |
| Refactor signature | 3 ngày | 1 dev |
| Apply to screens | 4 ngày | 1-2 dev |
| Empty/Error refresh | 1 ngày | 1 dev (sau khi designer giao SVG) |
| QA + polish | 2 ngày | 1 dev + 1 QA |
| **Tổng** | **~11.5 ngày = 2.5 sprints** | |

Cộng với 1.5 ngày Color System v2 trước đó → **~3 sprints để hoàn tất visual upgrade toàn bộ app**.

---

## Phụ lục — Quick reference

### Khi nào dùng widget nào

| Tình huống | Component |
|---|---|
| Show property cho customer browse | `CustomerPropertyCard` |
| Show property cho owner manage | `ManagerPropertyCard` |
| Property thuộc tier cao cấp | + `PremiumRibbon` |
| Property booking velocity cao | + `HotBadge` |
| Notification time-sensitive | `LiveDot.warning` + text |
| Hiển thị metric realtime (đang viewing) | `LiveDot.brand` |
| Status info trong card (đã thu, sắp đến) | `StatusStrip` |
| AI gợi ý hành động | `AIInsightCard` |
| Calendar 1 ngày | `CalendarCell` với props status/today/selected |
| Booking trong list | `BookingCard` với rail variant theo status |
| List trống | `EmptyState` với illustration |
| Lỗi load | `ErrorState` với retry |

### File references

- Color tokens → `halong24h-color-system-v2.md`
- Component anatomy + code → file này
- Design brief gốc → `design-brief.md` v1.0 (sections 3.1-3.18)

---

**Phiên bản**: 2.0
**Cập nhật cuối**: 27/04/2026
**Companion với**: `halong24h-color-system-v2.md`
**File này thay thế**: section 3 (Component Patterns) trong `design-brief.md` v1.0 (mở rộng + bổ sung)
