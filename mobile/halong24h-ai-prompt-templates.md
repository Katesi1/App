# Halong24h — AI Prompt Templates for Devs

> Bộ prompt template để dev paste vào **Claude Code / Cursor / GitHub Copilot Chat / Windsurf** sinh code đúng design system v2.
> Mỗi prompt đã có **system context** + **placeholder** rõ ràng — chỉ điền vào và run.
>
> Phiên bản: 1.0
> Ngày: 27/04/2026

---

## Mục lục

1. [Cách dùng](#cách-dùng)
2. [System Context Block (paste 1 lần / session)](#system-context-block)
3. [Prompt 1 — Build screen mới from scratch](#prompt-1--build-screen-mới-from-scratch)
4. [Prompt 2 — Refactor screen cũ sang v2](#prompt-2--refactor-screen-cũ-sang-v2)
5. [Prompt 3 — Build 1 reusable widget](#prompt-3--build-1-reusable-widget)
6. [Prompt 4 — Apply theme color v2 cho widget cũ](#prompt-4--apply-theme-color-v2-cho-widget-cũ)
7. [Prompt 5 — Tạo Riverpod controller + repository](#prompt-5--tạo-riverpod-controller--repository)
8. [Prompt 6 — Tạo skeleton loading variant](#prompt-6--tạo-skeleton-loading-variant)
9. [Prompt 7 — Tạo unit + widget tests](#prompt-7--tạo-unit--widget-tests)
10. [Prompt 8 — Audit hardcoded colors](#prompt-8--audit-hardcoded-colors)
11. [Prompt 9 — Verify dark mode](#prompt-9--verify-dark-mode)
12. [Prompt 10 — Add animation cho widget](#prompt-10--add-animation-cho-widget)
13. [Prompt 11 — Tạo empty/error state](#prompt-11--tạo-emptyerror-state)
14. [Prompt 12 — Convert mockup HTML → Flutter widget](#prompt-12--convert-mockup-html--flutter-widget)
15. [Tips dùng prompt hiệu quả](#tips-dùng-prompt-hiệu-quả)

---

## Cách dùng

### Bước 1 — Setup session

Mỗi session AI mới (Claude Code / Cursor chat mới):
1. Paste **System Context Block** (section dưới) **đầu tiên**
2. Đợi AI confirm "đã hiểu"
3. Sau đó paste prompt cụ thể (Prompt 1-12)

### Bước 2 — Điền placeholder

Mỗi prompt có chỗ ghi `{{PLACEHOLDER}}` — thay bằng nội dung thực:
- `{{SCREEN_NAME}}` — tên screen, ví dụ "Property Detail"
- `{{ROLE}}` — Customer / Owner / Admin / Sale
- `{{COMPONENT_DESC}}` — mô tả component cần build
- `{{FILE_PATH}}` — đường dẫn file
- `{{COLOR_TOKEN}}` — token màu, ví dụ "jade500"

### Bước 3 — Sau khi AI gen code

Verify checklist:
- [ ] Mọi `Color(0xFF...)` đã thay bằng `context.colors.x` hoặc `AppColors.xxx`
- [ ] Có hỗ trợ light + dark theme (no `Brightness.dark` check trừ khi đặc biệt)
- [ ] Component có `Animated*` hoặc `flutter_animate` entry animation
- [ ] Border radius dùng `AppRadius`, spacing dùng `AppSpacing`
- [ ] Font weight đậm (w700-w800) cho headings và labels

---

## System Context Block

> **Paste vào đầu mỗi session AI**. Sau khi AI confirm "đã hiểu", mới paste prompt cụ thể.

```
Bạn là senior Flutter dev cho app Halong24h — app đặt phòng homestay/khách sạn vùng Hạ Long. Khi tôi yêu cầu code, bạn TUÂN THỦ NGHIÊM NGẶT design system v2 sau:

## TECH STACK
- Flutter 3.x + Material 3
- State: flutter_riverpod 2.6+ với code gen (@riverpod annotation)
- Routing: go_router 14
- HTTP: dio 5
- Animation: flutter_animate
- Image: cached_network_image
- Font: google_fonts (Nunito)
- Cấu trúc: features/<feature>/{controllers,data,views/widgets}

## COLOR SYSTEM v2 — JADE BAY

### Brand colors (không đổi giữa light/dark)
- jade500 (primary) #0F5A6B  — MAIN brand
- jade300 #5BA8B5
- jade50 #E6F4F5
- gold500 (secondary premium) #E5B547
- gold700 #A8821F (text gold trên bg sáng)
- coral500 (warm accent NEW) #F2856B
- coral700 #B85A3F

### Dark mode
- darkBg #0A1F26
- darkSurface #0F2F38
- darkContainer #143E48
- darkBorder #1B5664
- darkTextPrimary #E6F4F7
- jadeBright #5BCEDC (text/icon brand on dark)
- goldBright #F4CD7A
- coralBright #F7AB94

### Cách dùng trong widget
- KHÔNG hardcode hex: SAI `Color(0xFF0F5A6B)`, ĐÚNG `context.colors.brand`
- KHÔNG dùng Colors.green/red từ Flutter: ĐÚNG `context.colors.success/error`
- Token text: textPrimary, textSecondary, textTertiary, textBrand, textBrandAccent (gold), textBrandWarm (coral), textOnPrimary
- Token bg: bgCanvas, bgSurface, bgSurfaceContainer, bgSurfaceElevated
- Token border: borderSubtle, borderDefault, borderStrong, borderBrand, borderGold, borderCoral

## TYPOGRAPHY (Nunito)
- displayLarge..Small: w400
- headlineLarge..Small: w800 (đẩy mạnh từ v1 w600-700)
- titleLarge..Small: w800
- bodyLarge..Small: w500
- labelLarge..Small: w700-800
- overline (NEW): 10-11px w800 letter-spacing 0.4-0.5

## SPACING / RADIUS
- Spacing: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48
- Radius: xs=4, sm=8, md=12, lg=16, xl=18-24, 3xl=28, full=100

## SIGNATURE PATTERNS (phải dùng đúng)

1. Hero gradient card với decorative blobs (3 absolute positioned circles, white 6%, gold 16%, coral 10%)
2. Floating overlap (margin-top: -42px) khi card đè header gradient
3. Status strip border-left 3px (success/warning/error/brand variants) — pattern xuất hiện rất nhiều
4. AI Insight card cam vàng — brand identity, phải có ở mọi screen có aggregated data
5. Live dot pulse animation (success/warning/brand)
6. Avatar gradient theo archetype (vip purple, regular green, new blue, warning amber, inactive grey)
7. Premium ribbon (gradient gold) — top-left khi isPremium
8. Hot badge (solid coral) — top-left khi isHot, offset 32 nếu cùng premium

## QUY TẮC TUYỆT ĐỐI

- Mọi screen có Scaffold + AppBar + bottom nav (trừ modal/wizard)
- Mọi color qua context.colors.x (extension đã setup ThemeExtension)
- Mọi text dùng Theme.of(context).textTheme.* (không hardcode TextStyle nếu không cần)
- Empty state: illustration trong circle 96x96 với primary 8% bg + title w700 + subtext muted
- Error state: cùng pattern empty, icon error, retry button
- Loading: skeleton variant matching component thật
- Animation entry: fadeIn 300-400ms + slideY 0.08-0.20 + stagger 60-80ms × index
- Tap feedback: AnimatedScale 0.97 trong 120ms
- Mọi text bằng tiếng Việt
- Format tiền: "1.500.000đ"
- Format ngày: "dd/MM/yyyy" hoặc "27 / 04 / 2026"

## OUTPUT FORMAT KHI TÔI YÊU CẦU CODE

1. File path đầy đủ (lib/features/.../views/...dart)
2. Imports đầy đủ
3. Code đầy đủ chạy được, không placeholder "// TODO"
4. Comment giải thích logic phức tạp (không comment trivial)
5. Cuối code: ghi 1-2 dòng note về integration (provider nào watch, route nào push)

## KHI THIẾU CONTEXT

Hỏi tôi thay vì assume:
- Role/viewMode nào?
- Data từ provider nào?
- Light/dark cùng support hay chỉ 1?
- Có animation entry không?

Confirm là bạn đã hiểu và sẵn sàng nhận yêu cầu cụ thể.
```

---

## Prompt 1 — Build screen mới from scratch

```
Build cho tôi screen "{{SCREEN_NAME}}" cho role {{ROLE}} viewMode {{VIEW_MODE}}, theme {{THEME}} (light/dark/cả hai).

## Mục đích screen
{{SCREEN_PURPOSE}}

## Sections từ trên xuống
{{SECTIONS_LIST}}
Ví dụ:
1. AppBar custom với title "Lịch tổng phòng" + filter icon + period chip "Hôm nay"
2. Period segmented (Tuần/2 tuần/Tháng) — pill bg slate100
3. Date navigator prev/next với label
4. KPI strip 4 số (lấp đầy / xác nhận / đang giữ / đêm trống)
5. Gantt grid 7 cột × N rows với booking pills
6. Selected booking detail card (floating bottom)

## Data
{{DATA_DESCRIPTION}}
Ví dụ:
- Provider: timelineDataProvider (AsyncNotifierProvider.family<TimelineData, CalendarFilter>)
- Model: TimelineData { rooms, bookings, blockedSlots, dynamicPricing }
- Filter: CalendarFilter { startDate, view: week/twoWeeks/month, homestayIds }

## Acceptance
- Pull-to-refresh
- Swipe horizontal trên grid để đổi tuần
- Tap empty cell → push /bookings/new với date+room pre-filled
- Tap pill booking → expand selected detail card
- Long-press pill + drag → chuyển phòng/đổi ngày (P2 sprint sau)

## Output

Hãy tạo:
1. File chính: lib/features/{{FEATURE}}/views/{{SCREEN_NAME_SNAKE}}_screen.dart
2. Widget con tách riêng nếu > 80 dòng (vào subfolder widgets/)
3. Skeleton loading variant
4. Empty state khi không có data
5. Error state với retry

Nếu cần data model mới, gen luôn trong lib/features/{{FEATURE}}/data/models/.
Nếu cần controller mới, gen với @riverpod annotation.
```

---

## Prompt 2 — Refactor screen cũ sang v2

```
Tôi có screen cũ đang dùng color v1 (ocean/teal/gold đục) ở file:
{{FILE_PATH}}

Hãy refactor screen này theo design system v2:

## Yêu cầu

1. Thay mọi hardcoded `Color(0xFF...)` bằng `context.colors.x` token v2
2. Thay token cũ bị deprecated:
   - `AppColors.ocean` → `AppColors.jade500` (hoặc `context.colors.brand`)
   - `AppColors.oceanMid` → `AppColors.jade300`
   - `AppColors.oceanBright` → `AppColors.jadeBright`
   - `AppColors.gold` → `AppColors.gold500`
   - `AppColors.teal` → xóa hoặc thay jade300
3. Đẩy headline weight w600-700 → w800
4. Thay card radius 16 → 18 (mặc định mới)
5. Thêm signature patterns nếu phù hợp:
   - Hero gradient ở top thay solid header
   - AI insight card khi có aggregated data
   - Status strip border-left khi có context info
6. Verify cả light + dark mode

## Code hiện tại

```dart
{{PASTE_HERE}}
```

## Output

1. Refactored code đầy đủ
2. Diff highlight: dòng nào thay, vì sao
3. Note nếu cần thêm widget shared mới (kèm spec ngắn)
```

---

## Prompt 3 — Build 1 reusable widget

```
Build cho tôi widget reusable shared: {{WIDGET_NAME}}

## Path
lib/shared/widgets/{{CATEGORY}}/{{WIDGET_NAME_SNAKE}}.dart

## Anatomy
{{ANATOMY_DESCRIPTION}}
Ví dụ:
- Container với gradient coral subtle (rgba(242,133,107, 0.12 → 0.04))
- Border 1px coral 30% alpha
- Padding 14
- Radius 16
- Layout: row [icon container 36×36 coral solid] + [content column: overline + title + body + 2 buttons]

## Variants
{{VARIANTS_LIST}}
Ví dụ:
- type: VoucherType.firstOrder | VoucherType.returnGuest | VoucherType.weekend
- countdown: bool — show countdown days remaining
- claimable: bool — show "Claim" button or "Already claimed"

## Props (constructor params)
{{PROPS_LIST}}
Ví dụ:
- final Voucher voucher;
- final VoidCallback? onTap;
- final VoidCallback? onClaim;

## Behavior
- Tap card → onTap callback
- Tap "Claim" button → onClaim callback (with optimistic UI)
- Hover (web) → scale 1.02

## Animation
- Entry: fadeIn 400ms + slideY begin 0.1
- Tap: AnimatedScale 0.97 / 120ms
- Claimed transition: AnimatedSwitcher 300ms

## Output

1. Code đầy đủ
2. Example usage trong comment đầu file
3. Note dependencies (nếu cần thêm package, ghi rõ pubspec entry)
```

---

## Prompt 4 — Apply theme color v2 cho widget cũ

```
Tôi paste 1 đoạn widget cũ. Hãy chỉ apply color v2 — KHÔNG thay đổi logic, layout, animation.

## Quy tắc

1. Mọi `Color(0xFF...)` → `context.colors.x`
2. `Colors.white` → `colors.bgSurface` (cho card/container) hoặc `colors.textOnPrimary` (cho text on brand)
3. `Colors.black` → `colors.textPrimary`
4. `Colors.grey/grey.shade*` → `colors.textTertiary` hoặc `colors.borderDefault` tùy context
5. `AppColors.ocean` deprecated → `AppColors.jade500` hoặc `colors.brand`
6. Mọi `MaterialColor.shadeXXX` → tra cứu sang token v2 phù hợp

## Code

```dart
{{PASTE_HERE}}
```

## Output

1. Code refactored với chỉ color thay đổi
2. Bảng diff: hex/token cũ → token mới + lý do
3. Verify dark mode work? Yes/No + giải thích
```

---

## Prompt 5 — Tạo Riverpod controller + repository

```
Tạo cho tôi controller + repository pattern cho feature: {{FEATURE_NAME}}

## Models
{{MODELS_LIST}}
Ví dụ:
- BookingDetail { id, propertyId, guestId, checkIn, checkOut, status, totalAmount, deposit, payments }
- BookingFilter { status?, dateRange?, guestId? }

## Endpoints
{{ENDPOINTS_LIST}}
Ví dụ:
- GET /bookings/:id → BookingDetail
- PATCH /bookings/:id/status → BookingDetail
- POST /bookings/:id/cancel → void
- POST /bookings/:id/checkin → void

## Operations cần
{{OPERATIONS_LIST}}
Ví dụ:
- fetch single booking by id
- update status with optimistic update
- cancel with confirm
- checkin (call separate endpoint)

## Path

- Repository: lib/features/{{FEATURE}}/data/repositories/{{FEATURE}}_repository.dart
- Controller: lib/features/{{FEATURE}}/controllers/{{FEATURE}}_controller.dart
- Models: lib/features/{{FEATURE}}/data/models/...

## Output

1. Repository abstract class + implementation với Dio
2. Controller @riverpod class với:
   - build() async fetch
   - update operations với optimistic + revert on error
3. Provider for repository
4. Mock data class for development (kDebugMode)
5. Note testing approach (mock repository + controller tests)
```

---

## Prompt 6 — Tạo skeleton loading variant

```
Tạo skeleton variant cho widget: {{WIDGET_NAME}}

## Widget gốc
{{PASTE_ORIGINAL_OR_DESCRIBE}}

## Yêu cầu

1. File: lib/shared/widgets/skeletons/{{WIDGET_NAME_SNAKE}}_skeleton.dart
2. Shape giống y component thật (cùng radius, cùng layout sub-blocks)
3. Dùng package shimmer hoặc tự viết với AnimatedBuilder
4. Color scheme:
   - Light: shimmer base #E2E8F0, highlight #F1F5F9
   - Dark: shimmer base #143E48, highlight #1A4D58
5. Animation 1500ms linear infinite

## Output

1. Code skeleton đầy đủ
2. Example usage trong list (3 items skeleton stagger fadeIn)
3. Performance note (dispose controller khi unmount)
```

---

## Prompt 7 — Tạo unit + widget tests

```
Viết tests cho widget/controller sau:

{{TARGET_DESCRIPTION}}
{{PASTE_CODE}}

## Yêu cầu

1. Unit tests (controller):
   - Happy path: fetch success → AsyncData
   - Error path: fetch fail → AsyncError với message đúng
   - Operations: optimistic update + revert on error
2. Widget tests:
   - Renders với mock data
   - Tap interactions trigger expected callbacks
   - State changes (loading → data → error) render đúng
3. Golden tests:
   - Light mode screenshot
   - Dark mode screenshot

## Mock setup

Dùng `mocktail` cho mocking. Setup `ProviderScope.overrideProvider`.

## Output

1. File test: test/features/{{FEATURE}}/...
2. Test coverage estimate (%)
3. Edge cases có thể bỏ qua (ghi rõ lý do)
```

---

## Prompt 8 — Audit hardcoded colors

```
Tôi paste folder/file. Hãy audit tất cả hardcoded color và đề xuất thay token v2.

## Files

```
{{PASTE_FILES_OR_PATHS}}
```

## Yêu cầu

1. Liệt kê mọi `Color(0xFF...)` và `Colors.xxx` được dùng
2. Mỗi cái propose token thay thế, giải thích context
3. Ưu tiên: dùng `context.colors.x` (theme-aware) > `AppColors.xxx` (constant) > raw hex (chỉ khi không thay được)
4. Flag những chỗ KHÔNG nên thay (ví dụ: brand color của partner, official palette)

## Output

Format bảng markdown:

| File | Line | Hex/Const cũ | Token v2 đề xuất | Lý do |
|---|---|---|---|---|
| home.dart | 42 | Color(0xFF0A4F6E) | context.colors.brand | Là primary, dùng theme-aware |
```

---

## Prompt 9 — Verify dark mode

```
Tôi paste 1 widget. Verify dark mode hoạt động đúng:

```dart
{{PASTE_HERE}}
```

## Checklist

1. Mọi color qua context.colors.x (không hardcode)
2. Text contrast ≥ 4.5:1 cả 2 mode (verify với cặp màu cụ thể)
3. Border vẫn nhìn được trên dark bg
4. Shadow đủ mạnh ở dark (rgba black 0.3-0.4 thay vì 0.06-0.08 light)
5. Image/icon có color filter phù hợp dark
6. Pull-to-refresh indicator color đúng theme
7. Status bar foreground tự động (không stuck)

## Output

1. Issues tìm được (highlight dòng + lý do)
2. Fix code đầy đủ với cả 2 mode work
3. Screenshot verify suggestion (chạy trên emulator dark + light, screenshot, đính kèm trong PR)
```

---

## Prompt 10 — Add animation cho widget

```
Add animations cho widget này:

```dart
{{PASTE_HERE}}
```

## Animations cần

{{ANIMATIONS_LIST}}
Ví dụ:
- Entry: fadeIn 400ms + slideY begin 0.1 (khi widget mount lần đầu)
- Stagger: trong list, delay 80ms × index
- Tap: AnimatedScale 0.97 / 120ms
- State change: AnimatedSwitcher khi data thay đổi
- Pulse infinite: cho LiveDot (chỉ khi visible)

## Quy tắc

1. Dùng `flutter_animate` nếu có thể (cleaner syntax)
2. Animations không block user interaction
3. Animation pause khi widget out of viewport (perf)
4. Respect `MediaQuery.disableAnimations` cho user accessibility

## Output

1. Code đã add animations
2. Note performance impact (CPU, jank risk)
3. Test approach (`tester.pumpAndSettle()` để wait animation)
```

---

## Prompt 11 — Tạo empty/error state

```
Tạo Empty + Error state widget cho context: {{CONTEXT}}

Ví dụ:
- Property list trống → "Chưa có property nào — Thêm property đầu tiên"
- Search không có kết quả → "Không tìm thấy phòng — Thử filter khác"
- Network error → "Mất kết nối — Thử lại"

## Yêu cầu

1. File: lib/shared/widgets/states/{{TYPE}}_state.dart (empty_state.dart hoặc error_state.dart)
2. Layout:
   - Center icon trong circle 96×96 với colors.brand 8% bg (empty) hoặc colors.error 8% bg (error)
   - Title w700 size 16 textPrimary
   - Subtext muted 50% opacity textPrimary
   - Optional CTA button (FilledButton.tonal hoặc OutlinedButton)
3. Animation:
   - Icon: scale elastic begin (0.7, 0.7) + fadeIn 600ms
   - Text: fadeIn cascade 200ms delay
   - CTA: fadeIn 500ms delay

## Variants

Empty state: noData, noSearchResult, noBookings, noWishlist
Error state: networkError, serverError, notFound, permissionDenied

## Output

1. Code đầy đủ với props (title, subtitle, icon, ctaLabel, onCtaTap)
2. Variants pattern (factory constructors hoặc enum)
3. Example usage cho 3 contexts
```

---

## Prompt 12 — Convert mockup HTML → Flutter widget

```
Tôi có mockup HTML này (từ designer). Convert sang Flutter widget với design system v2:

```html
{{PASTE_HTML}}
```

## Quy tắc convert

1. CSS pixel value → Flutter dp (1:1)
2. CSS rgba/hex → tra token v2 nearest match (KHÔNG copy hex trực tiếp)
3. CSS gradient → Flutter LinearGradient/RadialGradient
4. CSS box-shadow → Flutter BoxShadow (multiple if multiple shadows)
5. CSS border-radius → BorderRadius.circular hoặc BorderRadius.only
6. CSS flex → Row/Column với MainAxisAlignment + CrossAxisAlignment
7. CSS position absolute → Stack + Positioned
8. CSS transform translate → Transform.translate
9. CSS gap → SizedBox spacers (Flutter chưa support gap natively)
10. SVG inline → flutter_svg hoặc CustomPaint nếu đơn giản

## Output

1. Code Flutter đầy đủ chạy được (KHÔNG placeholder)
2. Tách sub-widgets khi > 80 dòng
3. Mọi color/spacing/radius dùng token v2
4. Note color mapping (CSS hex → token chosen)
5. Note animation cần thêm (HTML không có animation, Flutter cần thêm fadeIn entry)
6. Verify checklist:
   - [ ] Dark mode works
   - [ ] Responsive (không hardcode width)
   - [ ] Tap targets ≥ 44×44
   - [ ] Text không overflow ở narrow screen
```

---

## Tips dùng prompt hiệu quả

### Tip 1 — Workflow recommended

```
1. Mở Cursor/Claude Code chat mới
2. Paste System Context Block → đợi confirm
3. Paste Prompt cụ thể với placeholder điền sẵn
4. AI gen code → review nhanh
5. Nếu cần điều chỉnh nhỏ: "Sửa giùm phần X thành Y" trong cùng chat
6. Nếu sang task khác: bắt đầu chat mới + paste lại System Context
```

### Tip 2 — Đừng skip System Context

Mỗi session AI mới nếu không paste System Context, nó sẽ:
- Hardcode `Color(0xFF...)` vì không biết token
- Dùng radius 8 thay 18 (default Flutter)
- Quên `flutter_animate` entry animations
- Quên dark mode support

→ Tốn thời gian fix sau hơn là paste 1 lần đầu.

### Tip 3 — Provide visual reference khi possible

Khi build screen mới:
- Attach screenshot mockup HTML (nếu có)
- Hoặc paste HTML markup vào prompt
- AI hiểu visual layout tốt hơn description từ chữ

### Tip 4 — Iterate nhỏ

Đừng yêu cầu "Build cả tab Profile với 10 sub-screens" cùng 1 prompt → AI gen sai logic, hard to review.

Chia nhỏ:
1. Prompt 1: Profile main screen layout
2. Prompt 2: Settings sub-section
3. Prompt 3: Edit profile form
4. ...

### Tip 5 — Validate output

Sau mỗi AI response, run nhanh:

```bash
# Check hardcoded colors
grep -r "Color(0xFF" lib/features/customer_home/

# Check formatting
flutter analyze lib/features/customer_home/

# Run tests nếu có
flutter test test/features/customer_home/
```

Nếu thấy hardcoded color → reply: "Bạn còn hardcode `Color(0xFF...)` ở dòng X. Sửa lại dùng token."

### Tip 6 — Combine prompts khi chain task

Ví dụ task: "Build Property Detail screen + tests + skeleton":

```
Combo prompt:
1. Áp Prompt 1 (build screen)
2. Trong cùng chat, sau khi screen xong: "Bây giờ áp Prompt 6 cho widget này — tạo skeleton variant"
3. Tiếp: "Áp Prompt 7 — viết tests"
```

AI giữ context, output consistent.

### Tip 7 — Khi AI gen sai design system

Reply mẫu để correct:

```
Code bạn vừa gen có vấn đề:
1. Dùng `Color(0xFF1E6B4A)` ở dòng 42 — đây là token cũ v1, phải dùng `context.colors.brand` (jade500 v2 = #0F5A6B)
2. Card radius 16, design system v2 dùng 18 cho card mặc định
3. Headline weight w600, phải w800

Sửa lại theo đúng design system v2 đã định nghĩa trong System Context.
```

### Tip 8 — Lưu prompt tốt vào template repo

Prompts này có thể tune theo project:
- Tạo file `.cursorrules` (Cursor) hoặc `.aider.conf.yml` (Aider) chứa System Context
- AI tự load context mỗi session, không cần paste tay
- Update khi design system v3 ra mắt

---

## Phụ lục — Prompt cho specific Halong24h scenarios

### Build Property Detail screen (Customer view)

```
[Paste System Context]

Áp Prompt 1 với:
- SCREEN_NAME: Property Detail (Customer view)
- ROLE: Customer
- VIEW_MODE: customer
- THEME: cả light + dark
- SECTIONS:
  1. Hero image carousel (full-width 75% screen height)
  2. Floating back button + share/wishlist top bar
  3. Sticky bottom CTA "Đặt phòng" với price summary
  4. Property name + rating + location strip
  5. Description với "Xem thêm"
  6. Amenities grid 4 cột (icon container + label)
  7. Reviews preview top 3 + "Xem 145 đánh giá →"
  8. Map preview 16:9 với pin Hạ Long
  9. House rules
  10. Cancellation policy
  11. Similar properties horizontal carousel
- DATA: propertyDetailProvider.family<PropertyDetail, String>
- ACCEPTANCE: scroll trên hero image parallax effect, tap image → fullscreen viewer, sticky bottom CTA luôn visible
```

### Build Checkout flow 3-step

```
[Paste System Context]

Áp Prompt 1 với:
- SCREEN_NAME: Checkout flow (3-step wizard)
- Stepper: Review → Guest info → Payment → Confirm
- Mỗi step là sub-screen riêng:
  1. ReviewStep: hiển thị booking summary (property card mini + dates + guests + price breakdown)
  2. GuestInfoStep: form name/phone/email + special requests
  3. PaymentStep: select method (VNPay QR / MoMo / Bank QR / Card) + show payment UI
  4. ConfirmStep: success animation + booking code + share + "Xem booking"
- DATA: checkoutControllerProvider giữ state qua các step
- ACCEPTANCE:
  - Back button quay lại step trước (không reset data)
  - Validate trước khi cho next
  - Payment timeout 15 phút với countdown
  - Success animation với SVG illustration
```

---

**Phiên bản**: 1.0
**Cập nhật cuối**: 27/04/2026
**Companion docs**:
- `halong24h-color-system-v2.md` — color tokens
- `halong24h-component-specs-v2.md` — component anatomy
- `halong24h-customer-home-implementation-spec.md` — implementation spec mẫu
