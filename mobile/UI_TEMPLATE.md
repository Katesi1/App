# UI Template — Homestay Management App

Tài liệu này định nghĩa design language, animation patterns và UI components chuẩn cho app.
Thiên hướng: **sáng màu** (Light mode mặc định) + hỗ trợ **Dark mode**.

---

## Nguồn tham khảo

| Nguồn | Link |
|-------|------|
| Flutter Animations docs | https://docs.flutter.dev/ui/animations |
| Material 3 Flutter | https://m3.material.io/components |
| flutter_animate package | https://pub.dev/packages/flutter_animate |
| animations package (Material motion) | https://pub.dev/packages/animations |
| Lottie for Flutter | https://pub.dev/packages/lottie |
| Flutter UI Cookbook | https://docs.flutter.dev/cookbook/animation |
| Material 3 Demo app | https://flutter.github.io/samples/material_3.html |
| Flutter Shaders / Custom paint | https://docs.flutter.dev/ui/design/graphics/fragment-shaders |

---

## Color System (Light & Dark)

### Light Theme (mặc định)

```dart
// lib/core/theme/app_theme.dart
static const _primaryLight   = Color(0xFF1E6B4A); // Xanh lá đậm (thiên nhiên, homestay)
static const _secondaryLight = Color(0xFFF5A623); // Cam vàng ấm (accent)
static const _surfaceLight   = Color(0xFFF8F9FA); // Nền sáng nhẹ
static const _bgLight        = Color(0xFFFFFFFF);
static const _errorLight     = Color(0xFFD32F2F);

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: _primaryLight,
    secondary: _secondaryLight,
    surface: _surfaceLight,
    background: _bgLight,
    error: _errorLight,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF1C1B1F),
  ),
  // Xem thêm typography bên dưới
);
```

### Dark Theme

```dart
static const _primaryDark   = Color(0xFF4CAF82); // Xanh lá sáng hơn cho dark bg
static const _secondaryDark = Color(0xFFFFB74D); // Cam nhạt hơn
static const _surfaceDark   = Color(0xFF1E1E2E); // Nền tối nhưng không đen tuyệt đối
static const _bgDark        = Color(0xFF121212);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: _primaryDark,
    secondary: _secondaryDark,
    surface: _surfaceDark,
    background: _bgDark,
    onPrimary: Colors.black,
    onSurface: Color(0xFFE6E1E5),
  ),
);
```

### Theme Switching (Riverpod)

```dart
// lib/shared/providers/theme_provider.dart
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() {
    // Load từ SharedPreferences
    return ThemeMode.light;
  }

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    // Save to SharedPreferences
  }
}

// Trong MaterialApp:
MaterialApp.router(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ref.watch(themeNotifierProvider),
)
```

---

## Typography

```dart
// Dùng Google Fonts: Nunito (friendly, readable) cho body
// Playfair Display hoặc Merriweather cho headings (premium feel)
static final textTheme = TextTheme(
  displayLarge:  GoogleFonts.nunito(fontSize: 57, fontWeight: FontWeight.w400),
  headlineLarge: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w700),
  headlineMedium:GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w600),
  titleLarge:    GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w600),
  titleMedium:   GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w500),
  bodyLarge:     GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w400),
  bodyMedium:    GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400),
  labelLarge:    GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
);
```

> Package cần thêm: `google_fonts: ^6.x`

---

## Spacing & Shape System

```dart
// Spacing constants
class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

// Border radius
class AppRadius {
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 24;
  static const double full = 100; // Pill shape
}
```

---

## Animation Patterns

### 1. Implicit Animations (đơn giản nhất — dùng nhiều nhất)

```dart
// AnimatedContainer — size, color, padding thay đổi mượt
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  decoration: BoxDecoration(
    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  child: ...,
)

// AnimatedOpacity — fade in/out
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 200),
  child: ...,
)

// AnimatedSwitcher — chuyển đổi giữa 2 widget
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  transitionBuilder: (child, animation) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(scale: animation, child: child),
  ),
  child: isLoading
      ? const LoadingWidget(key: ValueKey('loading'))
      : content,
)
```

### 2. flutter_animate (cần thêm vào pubspec)

```dart
// pubspec.yaml: flutter_animate: ^4.x

// Stagger animation cho list items
ListView.builder(
  itemBuilder: (context, index) => RoomCard(room: rooms[index])
    .animate(delay: Duration(milliseconds: index * 80))
    .fadeIn(duration: 400.ms)
    .slideX(begin: 0.2, end: 0),
)

// Shimmer loading effect
Container(width: 200, height: 20, color: Colors.grey)
  .animate(onPlay: (c) => c.repeat())
  .shimmer(duration: 1200.ms, color: Colors.white38)

// Bounce khi tap
GestureDetector(
  onTap: ...,
  child: card
    .animate(target: isTapped ? 1 : 0)
    .scale(begin: Offset(1, 1), end: Offset(0.95, 0.95)),
)
```

### 3. Hero Animations (shared element transitions)

```dart
// Trong danh sách (room_card.dart):
Hero(
  tag: 'room-image-${room.id}',
  child: CachedNetworkImage(imageUrl: room.imageUrl),
)

// Trong detail screen:
Hero(
  tag: 'room-image-${room.id}',
  child: CachedNetworkImage(imageUrl: room.imageUrl),
)
```

### 4. Material Motion (animations package)

```dart
// pubspec.yaml: animations: ^2.x

// Container Transform (card → detail)
OpenContainer(
  closedBuilder: (context, openContainer) => RoomCard(onTap: openContainer),
  openBuilder: (context, _) => RoomDetailScreen(roomId: room.id),
  transitionDuration: const Duration(milliseconds: 400),
  closedShape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
)

// Shared Axis (onboarding, tabs)
PageTransitionSwitcher(
  transitionBuilder: (child, animation, secondaryAnimation) =>
      SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        child: child,
      ),
  child: currentPage,
)

// Fade Through (bottom nav switching)
PageTransitionSwitcher(
  transitionBuilder: (child, animation, secondaryAnimation) =>
      FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      ),
  child: _pages[_selectedIndex],
)
```

### 5. Page Route Transitions (GoRouter)

```dart
// Custom transition cho GoRoute
GoRoute(
  path: '/rooms/:id',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: RoomDetailScreen(roomId: state.pathParameters['id']!),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  ),
)
```

---

## Component Templates

### Card Component (Room Card)

```dart
// Thiết kế: elevation nhẹ, rounded corners lớn, image top + info bottom
// Nguồn cảm hứng: Airbnb card style
class RoomCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image với badge giá
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                child: CachedNetworkImage(
                  imageUrl: room.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _PriceBadge(price: room.price),
              ),
            ],
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                _StatusChip(status: room.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Loading Skeleton (Shimmer)

```dart
// Dùng shimmer package hoặc flutter_animate
// Thay thế cho CircularProgressIndicator — UX đẹp hơn nhiều
class RoomCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Container(height: 180, color: Colors.grey.shade300)
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Container(height: 16, width: double.infinity, color: Colors.grey.shade300)
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms, delay: 200.ms),
                const SizedBox(height: 8),
                Container(height: 12, width: 100, color: Colors.grey.shade300)
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms, delay: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Empty State

```dart
// Dùng Lottie animation thay vì icon tĩnh
class EmptyState extends StatelessWidget {
  final String message;
  final String? lottieAsset; // path to .json lottie file

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lottieAsset != null)
            Lottie.asset(lottieAsset!, width: 200, repeat: true)
          else
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      )
      .animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.1, end: 0),
    );
  }
}
```

### Bottom Sheet (thay Dialog)

```dart
// Ưu tiên dùng showModalBottomSheet thay Dialog cho mobile UX
// Thiết kế: drag handle, rounded top corners
void showRoomActionSheet(BuildContext context, RoomModel room) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          // Content...
        ],
      ),
    ),
  );
}
```

### FAB với animation

```dart
// Expandable FAB — đẹp hơn FAB đơn
FloatingActionButton.extended(
  onPressed: () => context.push('/rooms/new'),
  icon: const Icon(Icons.add),
  label: const Text('Thêm phòng'),
  backgroundColor: Theme.of(context).colorScheme.primary,
)
.animate(delay: 300.ms)
.slideY(begin: 2, end: 0, curve: Curves.elasticOut)
.fadeIn()
```

### Pull to Refresh

```dart
RefreshIndicator.adaptive( // adaptive: iOS vs Android style
  color: Theme.of(context).colorScheme.primary,
  onRefresh: () => ref.refresh(roomListProvider(homestayId).future),
  child: ListView.builder(...),
)
```

---

## Screen Layout Patterns

### List Screen với Sliver AppBar

```dart
// Collapsible header khi scroll — hiệu ứng đẹp
CustomScrollView(
  slivers: [
    SliverAppBar.large(
      title: const Text('Danh sách phòng'),
      floating: true,
      actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: ...)],
    ),
    SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.md),
      sliver: SliverList.builder(
        itemCount: rooms.length,
        itemBuilder: (context, index) => RoomCard(room: rooms[index])
          .animate(delay: Duration(milliseconds: index * 60))
          .fadeIn()
          .slideY(begin: 0.1, end: 0),
      ),
    ),
  ],
)
```

### Form Screen

```dart
// Floating labels, validation inline, keyboard-aware
Scaffold(
  body: GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard khi tap ngoài
    child: SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(children: [...fields]),
    ),
  ),
  bottomNavigationBar: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: FilledButton(onPressed: submit, child: const Text('Lưu')),
    ),
  ),
)
```

---

## Micro-interactions

```dart
// Tap feedback — scale down
GestureDetector(
  onTapDown: (_) => controller.forward(),
  onTapUp: (_) => controller.reverse(),
  onTapCancel: () => controller.reverse(),
  child: ScaleTransition(
    scale: Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    ),
    child: child,
  ),
)

// Hoặc đơn giản hơn với flutter_animate:
widget
  .animate(target: isTapped ? 1 : 0)
  .scale(begin: const Offset(1, 1), end: const Offset(0.95, 0.95))
  .duration(100.ms)
```

---

## Packages cần thêm vào pubspec.yaml

```yaml
dependencies:
  # Animations
  flutter_animate: ^4.5.0        # Chain animations dễ dàng
  animations: ^2.0.11            # Material motion patterns
  lottie: ^3.1.0                 # After Effects animations

  # UI
  google_fonts: ^6.2.1           # Typography đẹp

  # Đã có sẵn trong dự án:
  # shimmer: ^3.0.0
  # cached_network_image: ^3.x
  # table_calendar: ^3.x
```

---

## Checklist khi tạo màn hình mới

- [ ] Dùng `SliverAppBar` thay vì `AppBar` thường nếu có list dài
- [ ] Loading state → Skeleton shimmer (không dùng spinner đơn giản)
- [ ] Empty state → Lottie animation + message
- [ ] Error state → retry button + message rõ ràng
- [ ] List items → stagger animate khi load lần đầu (delay mỗi item 60-80ms)
- [ ] Navigation → Hero transition nếu có ảnh shared giữa 2 màn
- [ ] Form → keyboard-aware, tap outside to dismiss
- [ ] Bottom actions → BottomSheet thay Dialog khi có thể
- [ ] Tap feedback → scale 0.95 micro-animation
- [ ] Support cả Light và Dark mode (dùng `Theme.of(context).colorScheme`)
- [ ] Không hardcode màu — luôn lấy từ `colorScheme`
