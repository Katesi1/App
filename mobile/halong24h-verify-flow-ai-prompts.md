# Halong24h — AI Prompt Pack for Verify + Subscription Flow

> Bộ prompt template để dev paste vào **Claude Code / Cursor / Copilot** sinh code 8 screens verify flow.
> Companion với `halong24h-verify-subscription-spec.md`.
>
> **QUAN TRỌNG**: System Context block này UPDATE từ bản trước — palette là **CALM OPERATIONS** (không phải v2 vibe coding cũ).
>
> Ngày: 27/04/2026
> Phiên bản: 2.0 (calm operations)

---

## Mục lục

1. [Cách dùng](#1-cách-dùng)
2. [System Context UPDATED (paste 1 lần / session)](#2-system-context-updated)
3. [Prompt 1 — Setup palette + theme](#3-prompt-1--setup-palette--theme)
4. [Prompt 2 — Screen 1 Paywall Modal](#4-prompt-2--screen-1-paywall-modal)
5. [Prompt 3 — Screen 2 CCCD Capture](#5-prompt-3--screen-2-cccd-capture)
6. [Prompt 4 — Screen 3 Selfie Face Match](#6-prompt-4--screen-3-selfie-face-match)
7. [Prompt 5 — Screen 4 Select Plan](#7-prompt-5--screen-4-select-plan)
8. [Prompt 6 — Screen 5 Payment](#8-prompt-6--screen-5-payment)
9. [Prompt 7 — Screen 6 Pending Approval](#9-prompt-7--screen-6-pending-approval)
10. [Prompt 8 — Screen 7 Trial Active](#10-prompt-8--screen-7-trial-active)
11. [Prompt 9 — Screen 8 Rejected](#11-prompt-9--screen-8-rejected)
12. [Prompt 10 — Controller + Repository](#12-prompt-10--controller--repository)
13. [Prompt 11 — Tests](#13-prompt-11--tests)
14. [Workflow recommended (5 ngày)](#14-workflow-recommended-5-ngày)
15. [Tips & validation](#15-tips--validation)

---

## 1. Cách dùng

### Bước 1 — Setup session

Mỗi session AI mới (Cursor/Claude Code chat mới):
1. Paste **System Context UPDATED** (section 2)
2. Đợi AI confirm "đã hiểu"
3. Paste prompt cụ thể (section 3-13)

### Bước 2 — Validate output

Sau khi AI gen code, check:
- [ ] Không hardcode `Color(0xFF...)` — phải qua `context.colors.x`
- [ ] Không có glow shadow excessive (chỉ FAB + active state)
- [ ] Không có decorative blobs trong manager screens
- [ ] Status pill radius 4-6, không phải 100
- [ ] Headings w700 default, w800 chỉ titleLarge
- [ ] Button primary bg `#B5D4DA`, text `#16252B` (không phải bg `#7AB5BD` text white)

### Bước 3 — Iterate nếu sai

Reply mẫu:

```
Code có vấn đề:
1. Dòng X dùng `Color(0xFF7AB5BD)` cho button bg, sai design system.
   Button primary phải dùng `colors.brand` = `#B5D4DA` text `colors.bgCanvas` = `#16252B`.
2. Status pill dòng Y có `borderRadius: 100` — calm operations dùng radius 4-6.
3. Icon container có `boxShadow` glow — bỏ ở mọi container trừ FAB.

Sửa lại đúng calm operations palette.
```

---

## 2. System Context UPDATED

> **Paste vào đầu mỗi session AI**.

```
Bạn là senior Flutter dev cho app Halong24h — SaaS B2B mobile cho Owner/Sale quản lý homestay vùng Hạ Long. Khi tôi yêu cầu code, bạn TUÂN THỦ NGHIÊM NGẶT design system "CALM OPERATIONS" sau:

## TECH STACK
- Flutter 3.x + Material 3
- State: flutter_riverpod 2.6+ với code gen (@riverpod annotation)
- Routing: go_router 14
- HTTP: dio 5
- Animation: flutter_animate
- Image: cached_network_image
- Camera: camera package + image_picker
- Font: google_fonts (Nunito)
- Cấu trúc: features/<feature>/{controllers, data/{models, repositories}, views/widgets}

## ROLES
- Free Owner: đăng ký xong, chưa verify, dùng app như Customer (xem property + đặt booking)
- Verified Owner: đã verify CCCD + paid, full quyền quản lý property
- Sale: được Owner invite qua email, không cần verify
- Admin Halong24h: duyệt KYC, có app riêng hoặc role-gated

## COLOR PALETTE — CALM OPERATIONS (DARK MODE)

### Tại sao palette này
Trước có dark mode "vibe coding" với glow + saturation cao + blobs decorative → mỏi mắt sau dùng nhiều giờ. Calm operations giải quyết: lighter bg, muted saturation, glow chỉ active state.

### Tokens DARK MODE (KHÔNG hardcode hex, dùng AppColors.x):

CANVAS & SURFACE:
- darkBg          #16252B  (canvas bg)
- darkSurface     #1E343A  (card bg)
- darkSurfaceAlt  #1B2D33  (appbar, bottomnav)
- darkContainer   #243439  (icon container, search bg)
- darkBorder      #2A4147  (border default)
- darkDivider     #243439  (item separator)

TEXT:
- textPrimary     #D6DDE0  (heading, body)
- textSecondary   #A8B0B4  (subtitle)
- textTertiary    #8FB0B8  (muted, meta)
- textHint        #8A9398  (placeholder)
- textDisabled    #6A7378

BRAND JADE (muted, không neon):
- jadeText        #B5D4DA  (text on dark, button primary BG)
- jadeMuted       #7AB5BD  (icon, accent)
- jadeBg          #2A4147  (selected pill bg)
- jadePillBg      #1F353A  (info card, status strip bg)

GOLD:
- goldText        #C9A567
- goldMuted       #B89C59
- goldBg          #383021
- goldBorder      #4A3F25
- goldPillBg      #2A2419

CORAL:
- coralText       #C9A084
- coralMuted      #B86D5A  (notification badge)
- coralBg         #3A2820

STATUS (calmer):
- successText     #6FA88B  (sage, KHÔNG neon green)
- successBg       #1F3A2D
- successBorder   #2D4D3D
- warningText     #C9A567  (mustard)
- warningBg       #2A2419
- warningBorder   #4A3F25
- errorText       #C97A6F  (rose)
- errorBg         #3A2421
- errorBorder     #4D2E29
- infoText        #7AB5BD
- infoBg          #1F353A
- vipText         #A488B8
- vipBg           #2D2438

### Cách dùng:
- KHÔNG hardcode hex: SAI `Color(0xFF7AB5BD)`, ĐÚNG `context.colors.brandLight` hoặc `AppColors.jadeMuted`
- KHÔNG dùng Colors.green/red từ Flutter
- Button primary: bg `colors.brand` = jadeText (#B5D4DA), text `colors.bgCanvas` (#16252B)
- Button secondary: bg `colors.borderDefault` (#2A4147), text `colors.textPrimary`
- Outline button: bg `bgSurface`, border 1.5px `colors.brand`, text `colors.brand`

## TYPOGRAPHY (Nunito)
- displayLarge..Small: w400
- headlineLarge..Small: w800
- titleLarge: w800
- titleMedium: w700  ← QUAN TRỌNG: không phải w800
- titleSmall: w700
- bodyLarge..Small: w500
- labelLarge..Small: w700
- overline (NEW): 10-11px w700 letter-spacing 0.3-0.5

## SPACING / RADIUS
- Spacing: xs=4, sm=8, md=16, lg=24, xl=32, xxl=48
- Radius: xs=4, sm=8, md=12, lg=14-16, xl=18-22, 3xl=24-28
- Card mặc định: lg (14-16), không phải 18

## QUY TẮC TUYỆT ĐỐI CHO MANAGER SCREENS

1. KHÔNG glow shadow màu trên icon containers
   - SAI: `BoxShadow(color: AppColors.jadeMuted.withOpacity(0.3), blurRadius: 10)`
   - ĐÚNG: bg `darkContainer`, không shadow
2. KHÔNG decorative blobs/stars trong gradient cards
3. Status pill radius 4-6, KHÔNG full pill 100
   - SAI: `borderRadius: BorderRadius.circular(100)` cho status badge
   - ĐÚNG: `borderRadius: BorderRadius.circular(4)`
4. Headings w700 default, w800 chỉ titleLarge
5. Border decorative 2px chỉ dùng cho "popular" card hoặc highlighted item
6. CTA primary: bg jadeText (light), text darkBg (dark)
7. Trial/promo badge: bg goldBg, text goldText, radius 4

## SIGNATURE PATTERNS

1. Stepper progress 4 segments
   - Active: 3px height, jadeMuted
   - Inactive: 3px, darkContainer
   - Border-radius 100 (chỉ cho progress bar segments)

2. Camera frame overlay
   - 4 corner brackets size 18×18, border 2.5px jadeText
   - Scan line 1px, gradient horizontal transparent → jadeMuted → transparent
   - Center hint icon container 48×48, radius 12, bg darkBorder

3. Status strip (border-left)
   - Container: bg infoBg/successBg/warningBg/errorBg
   - Border-left 3px (cùng màu accent)
   - Border-radius 0/10/10/0 (right corners only)
   - Padding 11px 13px
   - Icon 14, color matching accent
   - Text 11px w700 textPrimary + 10px w500 textSecondary

4. Status timeline (vertical)
   - Container card với rail 1.5px darkBorder ở left 27px
   - Steps: icon 28×28 radius 50%
     - Done: bg successBorder, border 2px successText, check icon
     - Current: bg goldBg, border 2px goldText, dot 8×8 inner
     - Pending: bg darkContainer, border 2px #4A5560

5. Plan card highlighted
   - Bg bgSurface, border 2px brandLight (jadeMuted)
   - Ribbon "PHỔ BIẾN NHẤT" position top -8 right 14
     - bg brandLight, text bgCanvas, padding 2px 8px, radius 4, font 9px w700

6. Order summary breakdown
   - Card bg bgSurface, border 1px borderDefault, radius 12, padding 14
   - Mỗi line: label trái + value phải (12px w500/w700)
   - Discount line: value successText
   - Divider 1px darkDivider
   - Total: label 13px w700 + value 18px w700 jadeText

## ANIMATIONS (flutter_animate)
- Entry: fadeIn 300-400ms + slideY 0.08-0.10
- Stagger: delay 60-80ms × index
- Tap: AnimatedScale 0.97 / 120ms easeOut
- Status pulse: scale 1 → 1.05, alternate, 2s (chỉ live indicator)
- Modal slide-up: 300ms easeOutCubic

## QUY TẮC OUTPUT KHI YÊU CẦU CODE

1. File path đầy đủ
2. Imports đầy đủ
3. Code chạy được, không "// TODO"
4. Comment chỉ explain logic phức tạp
5. Cuối code: note integration (provider watch, route push)
6. Format tiền: "1.500.000đ" (dấu chấm phân cách)
7. Format ngày: "dd/MM/yyyy" hoặc "27 / 04 / 2026"
8. Tất cả text bằng tiếng Việt

## KHI THIẾU CONTEXT

Hỏi tôi thay vì assume:
- Role nào (Free/Verified/Sale/Admin)?
- Provider nào watch?
- Có animation entry không?
- Edge case nào cần handle?

Confirm bạn đã hiểu calm operations palette và sẵn sàng nhận yêu cầu cụ thể.
```

---

## 3. Prompt 1 — Setup palette + theme

```
Update file `lib/core/theme/app_colors.dart` và `lib/core/theme/app_color_scheme.dart` cho palette CALM OPERATIONS dark mode.

## Action

1. Update `app_colors.dart`:
   - Update các token darkBg, darkSurface, darkBorder... theo bảng calm operations
   - Rename `jadeBright` → `jadeMuted`, `goldBright` → `goldText`, `coralBright` → `coralText`, etc.
   - Giữ alias deprecated cho backward compat:
     ```
     @Deprecated('Use jadeMuted instead')
     static const jadeBright = jadeMuted;
     ```

2. Update `AppColorScheme.dark()`:
   - Mapping mới theo calm operations
   - Đặc biệt: `brand = jadeText (#B5D4DA)` cho button primary BG
   - `brandLight = jadeMuted (#7AB5BD)` cho icon, accent
   - Text on primary button: `bgCanvas (#16252B)` (KHÔNG phải white)

3. Update `ThemeData.dark()` trong `app_theme.dart`:
   - `FilledButton` style: bg jadeText, text darkBg
   - `Card` style: bg darkSurface, border darkBorder, radius 14
   - `InputDecorationTheme`: filled bg darkContainer, border darkBorder, focus jadeMuted

4. Update light mode tương ứng (giữ logic v2 nhưng cleanup nếu có vibe coding artifacts)

## Output

1. File `app_colors.dart` đầy đủ
2. File `app_color_scheme.dart` đầy đủ
3. File `app_theme.dart` đầy đủ
4. Migration note: list token cũ → mới, action dev cần làm
5. Estimated time để refactor app cũ: bao nhiêu giờ?

## Light theme có cần update không?

Light theme giữ nguyên v2 cũ (jade #0F5A6B), không cần thay vì:
- Light mode không có vấn đề "mỏi mắt" như dark
- 2 theme có vibe khác nhau OK (giống Apple App Store light vs dark)

Chỉ cần verify mọi color token có cả light + dark variant trong AppColorScheme.
```

---

## 4. Prompt 2 — Screen 1 Paywall Modal

```
Build cho tôi `PaywallModal` widget — bottom sheet cho Free Owner khi click action bị lock.

## Path
`lib/features/verify/views/paywall_modal.dart`

## Trigger
Free Owner click "Tạo property" / "Quản lý phòng" / "Báo cáo doanh thu". Modal hiện thay vì navigate.

## Anatomy

```
┌─────────────────────────────────┐
│         ━━━━ (drag handle)       │
│                                  │
│         [🏠] icon gold rounded   │
│                                  │
│       Đăng phòng để kiếm tiền   │
│   Để bắt đầu nhận booking, bạn  │
│   cần verify CCCD và mua gói    │
│                                  │
│  ┌─ QUY TRÌNH 4 BƯỚC ──────┐   │
│  │ ① Chụp CCCD + Selfie    │   │
│  │ ② Thông tin homestay     │   │
│  │ ③ Chọn gói + Thanh toán  │   │
│  │ ④ Chờ admin duyệt        │   │
│  └──────────────────────────┘   │
│                                  │
│  [Để sau]      [Bắt đầu ngay →] │
│  Điều khoản dịch vụ              │
└─────────────────────────────────┘
```

## Tokens (calm operations dark)

- Bottom sheet: bg `colors.bgSurfaceElevated` (#1E343A), border-radius top 24
- Drag handle: 40×4, bg #4A5560
- Icon container: 60×60, radius 16, bg goldBg (#383021), icon goldMuted (#B89C59) size 28
- Title: 18px w700 textPrimary
- Subtitle: 13px w500 textSecondary, line-height 1.45, text-align center
- Step preview card: bg bgCanvas (#16252B), border 1px borderDefault, radius 12, padding 14
- Step circle: 24×24, radius 50%, bg darkBorder, text jadeText 11px w700
- Step title: 12px w700 textPrimary
- Step subtitle: 11px w500 textHint
- Button "Để sau": bg darkBorder, text textPrimary, w700, height 52, radius 10
- Button "Bắt đầu ngay" (primary): bg jadeText (#B5D4DA), text bgCanvas (#16252B), w700, height 52, radius 10, có icon arrow right
- Disclaimer: 10px w500 textHint, link "Điều khoản dịch vụ" color jadeMuted

## Props

```dart
class PaywallModal extends StatelessWidget {
  final VoidCallback onProceed;
  final VoidCallback? onDefer;
  final bool hasDraft;        // Nếu owner đã từng start verify → hiện "Tiếp tục từ bước X?"
  final int? draftStep;        // Step number cuối user reach
  // ...
}
```

## Behavior

- Tap drag handle hoặc swipe down → close modal
- Tap "Để sau" → close modal, return to previous screen
- Tap "Bắt đầu ngay" → close modal + push verify flow
  - Nếu hasDraft: text button đổi thành "Tiếp tục bước $draftStep"
- Tap "Điều khoản dịch vụ" → open in-app webview

## Animation

- Modal slide up từ bottom: 300ms easeOutCubic
- Backdrop scrim fade in: 200ms, color rgba(0,0,0, 0.6)
- Step list items: stagger fadeIn 60ms × index, slideX begin -0.05

## Helper function show modal

```dart
Future<bool?> showPaywallModal(BuildContext context, {
  bool hasDraft = false,
  int? draftStep,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => PaywallModal(
      hasDraft: hasDraft,
      draftStep: draftStep,
      onProceed: () => Navigator.pop(context, true),
      onDefer: () => Navigator.pop(context, false),
    ),
  );
}
```

## Output

1. File `paywall_modal.dart` đầy đủ
2. Helper function show modal
3. Example usage trong RoomManagementScreen khi free owner tap "+ Tạo property"
```

---

## 5. Prompt 3 — Screen 2 CCCD Capture

```
Build screen `CCCDCaptureScreen` cho bước 1/4 verify flow — chụp CCCD mặt trước.

## Path
`lib/features/verify/views/cccd_capture_screen.dart`

## Anatomy

(Layout như mockup)
- AppBar custom với back + overline "BƯỚC 1/4 · Verify CCCD" + title "Mặt trước CCCD"
- Stepper progress 4 segments (1 active jadeMuted, 3 inactive darkContainer)
- Hint description text
- Camera frame area 200px height với:
  - 4 corner brackets jadeText size 18×18
  - Scan line ngang giữa, gradient horizontal
  - Center icon container + hint text
- Status strip "Lưu ý quan trọng" border-left jadeMuted
- 2 buttons: icon-only (upload) + filled primary (open camera)

## Tokens (xem System Context)

## Props

```dart
class CCCDCaptureScreen extends ConsumerStatefulWidget {
  final CCCDSide side;  // front | back
  final VoidCallback onSuccess;
  // ...
}

enum CCCDSide { front, back }
```

## Camera integration

Dùng package `camera` cho realtime camera + auto-detection. Hoặc đơn giản hơn: dùng `image_picker` với `ImageSource.camera`:

```dart
final picker = ImagePicker();
final XFile? image = await picker.pickImage(
  source: ImageSource.camera,
  maxWidth: 1920,
  imageQuality: 85,
);
if (image != null) {
  await ref.read(verifyFlowControllerProvider.notifier)
      .uploadCCCDFront(File(image.path));
}
```

Note: bạn có thể bắt đầu với image_picker simple, sau đó upgrade sang full camera package với auto-detect.

## State machine

- idle: hiện hint + 2 buttons
- capturing: đang chụp, show loading overlay
- uploading: file đang upload, progress bar
- success: navigate to next step
- error: snackbar đỏ + cho retry

## API integration

```dart
// Watch state
final state = ref.watch(verifyFlowControllerProvider);

// Action
await ref.read(verifyFlowControllerProvider.notifier).uploadCCCDFront(file);
```

## Edge cases

1. Camera permission denied → alternate UI với 2 options: cấp quyền + upload ảnh sẵn
2. OCR confidence < 0.8 → toast warning + cho retry, max 3 lần
3. File > 10MB → compress trước upload
4. Network fail → retry logic với exponential backoff

## Output

1. File screen đầy đủ với state management
2. Helper widget `CameraFrameOverlay` (corner brackets + scan line) — file riêng `lib/features/verify/views/widgets/camera_frame_overlay.dart`
3. Helper widget `StepperProgress` — `lib/features/verify/views/widgets/stepper_progress.dart`
4. Test scenarios cho QA list
```

---

## 6. Prompt 4 — Screen 3 Selfie Face Match

```
Build screen `SelfieCaptureScreen` cho bước 3/4 verify flow.

## Path
`lib/features/verify/views/selfie_capture_screen.dart`

## Anatomy

- AppBar custom (giống Screen 2)
- Stepper progress (3/4 active)
- Card success xanh sage hiển thị info từ CCCD đã verify (Nguyễn Văn Tuấn · 001192012345)
  - Bg successBg (#1F3A2D), border successBorder (#2D4D3D)
  - Icon container 32×32 bg successBorder, check icon successText
- Hint text 2 dòng
- Camera area 220px:
  - Oval frame 140×180, border 2px dashed #4A5560
  - Person icon center khi chưa detect
  - Live status indicator bottom: dot 6×6 + text màu warning
- Tips card với 3 bullet checkmark
- Button primary "Bắt đầu chụp selfie"

## Tokens

(xem System Context)

## Camera + face detection

Phức tạp hơn CCCD vì cần realtime face detection. Options:

1. **Simple**: dùng `image_picker` rồi upload, server-side face match (recommended cho MVP)
2. **Advanced**: dùng `google_mlkit_face_detection` realtime overlay + capture khi face stable

```dart
// Simple version
final image = await ImagePicker().pickImage(source: ImageSource.camera);
if (image != null) {
  try {
    await ref.read(verifyFlowControllerProvider.notifier)
        .uploadSelfie(File(image.path));
  } on FaceMismatchException catch (e) {
    showAppSnackbar(
      context,
      'Khuôn mặt không khớp với CCCD (score: ${e.score})',
      type: SnackbarType.error,
    );
  }
}
```

## Face match logic

```dart
// Trong VerifyFlowController
Future<void> uploadSelfie(File image) async {
  final result = await ref.read(verifyRepositoryProvider).uploadSelfie(
    image,
    cccdFrontId: state.cccdFront!.id,
  );
  
  if (result.faceMatchScore < 0.85) {
    final attempts = state.selfieFailAttempts + 1;
    state = state.copyWith(selfieFailAttempts: attempts);
    
    if (attempts >= 3) {
      throw FaceMismatchTooManyAttemptsException();
    }
    throw FaceMismatchException(score: result.faceMatchScore);
  }
  
  state = state.copyWith(
    selfie: result,
    faceMatchScore: result.faceMatchScore,
    selfieFailAttempts: 0,
    status: VerifyStatus.kycSubmitted,
  );
}
```

## UI states

- idle: hint + button "Bắt đầu chụp selfie"
- capturing: loading overlay
- mismatch: cho retry với count "Lần thử X/3"
- maxAttempts: lock screen với contact support button
- success: navigate to next step

## Edge cases

1. Đeo kính/khẩu trang → trên web có thể warn, mobile thường đợi server detect và return error
2. Ánh sáng yếu → server reject với code "POOR_LIGHTING"
3. Multiple faces trong frame → server reject với code "MULTIPLE_FACES"
4. 3 lần fail → lock 1 giờ + email admin manual review

## Output

1. File screen đầy đủ
2. Custom exceptions: `FaceMismatchException`, `FaceMismatchTooManyAttemptsException`
3. UI cho lock state (sau 3 lần fail)
4. Test scenarios
```

---

## 7. Prompt 5 — Screen 4 Select Plan

```
Build screen `SelectPlanScreen` cho bước 5/7 — chọn gói subscription.

## Path
`lib/features/verify/views/select_plan_screen.dart`

## Anatomy

(Layout như mockup spec section 5.4)
- AppBar custom với back + overline + title
- Card "Số phòng dự kiến: 15 phòng" với link "Sửa →"
- Toggle Monthly/Yearly với badge -20% gold
- 3 plan cards stacked (vertical):
  - Starter (default style)
  - Professional (HIGHLIGHTED — border 2px brandLight + ribbon "PHỔ BIẾN NHẤT")
  - Enterprise (default style)
- Trial banner sage green
- Button primary "Chọn [Plan name] → Thanh toán"

## Tokens (xem System Context)

## Logic auto-suggest tier

```dart
TierEnum suggestTier(int rooms) {
  if (rooms <= 20) return TierEnum.starter;
  if (rooms <= 50) return TierEnum.professional;
  return TierEnum.enterprise;
}
```

## Logic calculate price

```dart
class PlanPriceCalculator {
  static int calculateMonthly(int rooms, Plan plan) {
    final raw = rooms * plan.pricePerRoomPerMonth;
    return raw < plan.minChargePerMonth ? plan.minChargePerMonth : raw;
  }
  
  static int calculateYearlyAfterDiscount(int rooms, Plan plan) {
    final monthly = calculateMonthly(rooms, plan);
    return (monthly * 12 * 0.8).round();  // 20% discount
  }
  
  static int calculateSavingsVsLowerTier(int rooms, Plan currentPlan, Plan lowerPlan) {
    final current = calculateMonthly(rooms, currentPlan);
    final lower = calculateMonthly(rooms, lowerPlan);
    return lower - current;
  }
}
```

## Plan card widget

Tách riêng `PlanCard` widget — `lib/features/verify/views/widgets/plan_card.dart`:

```dart
class PlanCard extends StatelessWidget {
  final Plan plan;
  final int rooms;
  final BillingCycle cycle;
  final bool isSuggested;
  final bool isSelected;
  final VoidCallback onTap;
}
```

3 visual states:
1. Default: border 1px borderDefault
2. Suggested (Pro): border 2px brandLight + ribbon "PHỔ BIẾN NHẤT" + tagline "Phù hợp với bạn" jadeMuted
3. Selected (sau khi user tap): same as default + check icon ở corner

## Format price

Dùng `intl` package:

```dart
String formatVND(int amount) {
  final formatter = NumberFormat('#,###', 'vi_VN');
  return '${formatter.format(amount).replaceAll(',', '.')}đ';
}
```

Output: "2.985.000đ"

## Behavior

- Tap toggle Monthly/Yearly → `setState` `_billingCycle = ...`, mọi plan card recalculate price
- Tap plan card → `setState` `_selectedPlan = plan`, CTA text update với tên plan
- Tap "Sửa →" room count → `Navigator.pop(context)` quay về step 4
- Tap CTA → `ref.read(verifyFlowControllerProvider.notifier).selectPlan(plan, cycle)` + push Screen 5

## Animation

- Cards entry stagger 80ms × index, fadeIn + slideY 0.1
- Toggle change: AnimatedContainer 200ms cho price text

## Output

1. `select_plan_screen.dart`
2. `plan_card.dart` widget
3. `plan_price_calculator.dart` utility
4. Format helpers (formatVND, formatPercent)
```

---

## 8. Prompt 6 — Screen 5 Payment

```
Build screen `PaymentScreen` cho bước 6/7 — thanh toán.

## Path
`lib/features/verify/views/payment_screen.dart`

## Anatomy

- AppBar custom
- Order summary card với breakdown 4 lines:
  - Plan × period: 26.820.000đ (textPrimary w700)
  - Giảm năm -20%: -5.364.000đ (successText w700, có dấu trừ)
  - VAT 10%: +2.146.000đ
  - Divider
  - Tổng: 23.602.000đ (jadeText, 18px w700)
  - Trial badge: bg successBg, text successText, "7 ngày trial · Tính từ ngày được duyệt"
- 3 payment method tiles (radio):
  - VNPay QR (selected default — border 2px brandLight)
  - Chuyển khoản ngân hàng
  - Thẻ tín dụng/ghi nợ
- 14-day refund disclaimer status strip
- Button primary "Thanh toán an toàn 23.602.000đ"

## Payment method tile widget

`lib/features/verify/views/widgets/payment_method_tile.dart`:

```dart
class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;
}
```

Tile structure:
- Padding 12, radius 12
- Border 1px (default) hoặc 2px brandLight (selected)
- Layout row: radio circle + logo container 36×28 + content (title + subtitle)
- Radio: empty circle border 1.5px (unselected) hoặc filled brandLight với check icon (selected)
- Logo container bg darkBorder, icon brand-color (VNPay xanh, MoMo hồng, etc.)
- Title 12px w700, subtitle 10px w500 textHint

## Payment flow

```dart
Future<void> _handlePayment() async {
  setState(() => _isLoading = true);
  
  try {
    final session = await ref
        .read(verifyFlowControllerProvider.notifier)
        .initiatePayment(_selectedMethod);
    
    // Navigate based on method
    switch (_selectedMethod) {
      case PaymentMethod.vnpayQR:
        await _showVNPayQRDialog(session);
        break;
      case PaymentMethod.bankTransfer:
        await _showBankTransferDialog(session);
        break;
      case PaymentMethod.card:
        await _navigateToCardForm(session);
        break;
    }
    
    // Polling for payment status
    await _pollPaymentStatus(session.sessionId);
  } catch (e) {
    showAppSnackbar(context, 'Lỗi: $e', type: SnackbarType.error);
  } finally {
    setState(() => _isLoading = false);
  }
}

Future<void> _pollPaymentStatus(String sessionId) async {
  // Poll mỗi 3s, max 5 phút (100 lần)
  for (var i = 0; i < 100; i++) {
    await Future.delayed(const Duration(seconds: 3));
    final status = await ref
        .read(verifyFlowControllerProvider.notifier)
        .checkPaymentStatus();
    
    if (status == PaymentStatus.paid) {
      // Navigate to pending screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/verify/pending');
      }
      return;
    }
    if (status == PaymentStatus.failed || status == PaymentStatus.expired) {
      throw Exception('Thanh toán thất bại');
    }
  }
}
```

## VNPay QR dialog

```dart
Future<void> _showVNPayQRDialog(PaymentSession session) async {
  await showDialog(
    context: context,
    builder: (_) => VNPayQRDialog(
      qrCode: session.qrCode!,
      amount: session.totalAmount,
      expiresAt: session.expiresAt,
    ),
  );
}
```

QR dialog hiện ảnh QR + countdown 15 phút + button "Tôi đã thanh toán" + "Huỷ".

## Output

1. `payment_screen.dart`
2. `payment_method_tile.dart`
3. `vnpay_qr_dialog.dart`
4. `bank_transfer_dialog.dart`
5. `order_summary_card.dart`
6. Helper polling logic
```

---

## 9. Prompt 7 — Screen 6 Pending Approval

```
Build screen `PendingApprovalScreen` — sau khi payment success, chờ admin duyệt 24h.

## Path
`lib/features/verify/views/pending_approval_screen.dart`

## Anatomy

(Layout như mockup spec section 5.6)
- AppBar simple "Hồ sơ đã gửi"
- Hero icon area:
  - 80×80 container, radius 24, bg infoBg, border 1px borderDefault
  - Clock icon 36×36 jadeMuted
  - Badge gold tick góc dưới-phải -4/-4 (22×22, bg goldText, border 3px canvas, icon dark)
- Title 18px w700 + subtitle với "24 giờ" highlight goldText
- Status timeline card với 4 steps + vertical rail
- Email notification status strip (jade variant)
- 2 actions: "Liên hệ HT" + "Về trang chủ"

## Status timeline widget

Tách riêng `lib/features/verify/views/widgets/status_timeline.dart`:

```dart
class StatusTimeline extends StatelessWidget {
  final List<TimelineStep> steps;
}

class TimelineStep {
  final String title;
  final String? subtitle;
  final TimelineStepStatus status; // done | current | pending
}
```

Timeline render:
- Container card padding 14, bg bgSurface, border, radius 14
- Position relative
- Vertical rail: position absolute left 27, top 30, bottom 30, width 1.5px, bg darkBorder
- Mỗi step: row gap 12, padding 6 vertical
  - Done: circle bg successBorder, border 2px successText, check icon
  - Current: circle bg goldBg, border 2px goldText, dot 8 inner
  - Pending: circle bg darkContainer, border 2px #4A5560, empty
- Step title:
  - Done/current: 12px w700 textPrimary
  - Pending: 12px w700 textHint
- Subtitle:
  - Done: 10px w600 successText
  - Current: 10px w600 goldText
  - Pending: 10px w500 textDisabled

## Polling logic

Stream-based, dùng riverpod:

```dart
final approvalStatusStreamProvider = StreamProvider<VerifyStatus>((ref) async* {
  final controller = ref.read(verifyFlowControllerProvider.notifier);
  while (true) {
    await Future.delayed(const Duration(seconds: 30));
    await controller.checkApprovalStatus();
    final state = ref.read(verifyFlowControllerProvider);
    yield state.status;
    
    if (state.status == VerifyStatus.approved || state.status == VerifyStatus.rejected) {
      break;
    }
  }
});
```

Trong screen:

```dart
ref.listen(approvalStatusStreamProvider, (previous, current) {
  current.whenData((status) {
    if (status == VerifyStatus.approved) {
      Navigator.pushReplacementNamed(context, '/verify/approved');
    } else if (status == VerifyStatus.rejected) {
      Navigator.pushReplacementNamed(context, '/verify/rejected');
    }
  });
});
```

## FCM push notification

Cũng nên handle push notification khi admin duyệt (cho trường hợp app background):

```dart
// Trong AppService init
FirebaseMessaging.onMessage.listen((message) {
  if (message.data['type'] == 'verify_approved') {
    // Navigate or update state
  }
});
```

## Edge cases

1. Quá 24h chưa duyệt: hiện banner escalation đỏ "Quá thời gian dự kiến" + button "Liên hệ urgent"
2. Network offline: silent retry polling, không show error
3. App killed: resume polling khi mở lại

## Animation

- Hero icon: scale begin (0.8, 0.8) elasticOut 600ms + fadeIn
- Title + subtitle: stagger fadeIn
- Timeline steps: stagger fadeIn 80ms × index
- Current step (gold): pulse scale 1 → 1.05 alternate 2s

## Output

1. `pending_approval_screen.dart`
2. `status_timeline.dart` widget reusable
3. `approval_status_stream_provider`
4. Push notification handler stub
```

---

## 10. Prompt 8 — Screen 7 Trial Active

```
Build screen `TrialActiveScreen` — sau khi admin duyệt, trial 7 ngày bắt đầu.

## Path
`lib/features/verify/views/trial_active_screen.dart`

## Anatomy

(Layout như mockup spec section 5.7)
- Banner success ở top:
  - Bg successBg, border-bottom 1px successBorder
  - Padding 14
  - Icon container 36×36 bg successBorder, check icon successText
  - Title 14px w700 + subtitle 11px w500 textTertiary
- Card "Bắt đầu từ đây":
  - Bg bgSurface, border 1px borderDefault, radius 14, padding 16
  - Overline 11px w700 textTertiary letter-spacing
  - Title 16px w700, subtitle 12px line-height 1.5
  - Divider 1px darkDivider
  - 4 bullet items với check icon successText
  - CTA button primary "Tạo homestay đầu tiên →"
- Subscription card:
  - Bg bgSurface, border 1px, radius 14, padding 14
  - Header row: overline "GÓI CỦA BẠN" + trial badge "TRIAL · 6N 23H" (bg goldBg, text goldText, radius 4)
  - Plan name 16px w700
  - Subtitle "23.602.000đ/năm · Tự động gia hạn"
  - Divider
  - 2 cột grid: trial end date | charge start date

## Realtime countdown

```dart
class TrialCountdownText extends StatefulWidget {
  final DateTime trialEndsAt;
}

class _TrialCountdownTextState extends State<TrialCountdownText> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    setState(() {
      _remaining = widget.trialEndsAt.difference(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    if (d.isNegative) return 'Đã hết';
    if (d.inDays > 0) {
      final hours = d.inHours % 24;
      return '${d.inDays} ngày ${hours}h';
    }
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return '${hours}h ${minutes} phút';
  }
  
  @override
  Widget build(BuildContext context) {
    return Text(
      _format(_remaining),
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: context.colors.goldText,
      ),
    );
  }
}
```

Display: "TRIAL · 6 ngày 23h" hoặc "TRIAL · 5h 42 phút" nếu dưới 24h.

## Format date VN

```dart
String formatDateVN(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
```

Display: "04/05/2026"

## Behavior

- Tap "Tạo homestay đầu tiên" → `Navigator.pushNamed(context, '/properties/new')` (property creation wizard 8 steps, không trong scope spec)
- Tap subscription card → `Navigator.pushNamed(context, '/subscription')` (My Subscription detail, Phase 3)
- Pull-to-refresh: invalidate `verifyFlowControllerProvider` để fetch latest

## Edge cases

1. Trial < 24h còn lại: badge thay đổi màu warningText (cam) + animation pulse
2. Trial < 1h: banner warning ở top "Trial sắp hết, gia hạn ngay?"
3. Auto-charge fail sau trial: navigate to read-only mode screen

## Animation

- Banner success: slideY begin -0.5 end 0, easeOutCubic, 400ms
- Card "Bắt đầu": fadeIn + slideY 0.1, delay 200ms
- Subscription card: fadeIn + slideY, delay 400ms
- Trial badge < 24h: pulse scale 1 → 1.05 alternate 2s

## Output

1. `trial_active_screen.dart`
2. `trial_countdown_text.dart` widget realtime
3. Format date helpers
4. Integration với route `/verify/approved`
```

---

## 11. Prompt 9 — Screen 8 Rejected

```
Build screen `RejectedScreen` — khi admin reject hồ sơ verify.

## Path
`lib/features/verify/views/rejected_screen.dart`

## Anatomy

(Layout như mockup spec section 5.8)
- Banner rose top:
  - Bg errorBg, border-bottom 1px errorBorder
  - Icon container 36×36 bg errorBorder, X icon errorText
  - Title 14px w700 + subtitle 11px w600 errorText
- Reason quote card:
  - Bg bgSurface, border 1px borderDefault, radius 12, padding 12
  - Quote text 11px w500 textSecondary line-height 1.5
  - Divider + signature 10px w500 textHint
- Money safety status strip (jade variant):
  - Bg infoBg, border-left 3px jadeMuted
  - Title "Tiền của bạn an toàn" 11px w700
  - Body 10px w500 textSecondary giải thích refund
- Need-to-fix list card:
  - 3 items (cccdFront, cccdBack, selfie)
  - Mỗi item: icon container 24×24 + label + status text + chevron right
  - Rejected item: bg errorBorder, X icon errorText, status "Cần chụp lại" errorText, có chevron
  - Approved item: bg successBorder, check icon successText, status "Đã duyệt" successText, không chevron
- 2 actions:
  - "Yêu cầu hoàn tiền" (secondary): bg darkBorder, text textPrimary
  - "Bổ sung ngay" (primary): bg jadeText, text bgCanvas

## Logic

```dart
class RejectedScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verifyFlowControllerProvider);
    final rejectedItems = state.rejectedItems;  // ['cccdFront']
    
    final items = [
      _RejectableItem('cccdFront', 'CCCD mặt trước'),
      _RejectableItem('cccdBack', 'CCCD mặt sau'),
      _RejectableItem('selfie', 'Selfie'),
    ];
    
    return Scaffold(/* ... */);
  }
}

class _RejectableItem {
  final String id;
  final String label;
}
```

## Item tap navigation

Tap item rejected → navigate đến screen tương ứng với current data preserved:

```dart
void _onItemTap(String itemId) {
  final route = switch (itemId) {
    'cccdFront' => '/verify/cccd?side=front',
    'cccdBack' => '/verify/cccd?side=back',
    'selfie' => '/verify/selfie',
    _ => null,
  };
  if (route != null) {
    Navigator.pushNamed(context, route, arguments: {'isResubmit': true});
  }
}
```

## Refund flow

Tap "Yêu cầu hoàn tiền" → confirm dialog:

```dart
Future<void> _requestRefund() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: context.colors.bgSurfaceElevated,
      title: const Text('Hoàn tiền 100%?'),
      content: const Text(
        'Hồ sơ verify sẽ bị huỷ và bạn cần đăng ký lại nếu muốn dùng. '
        'Tiền sẽ được hoàn vào phương thức thanh toán gốc trong 3-7 ngày.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hoàn tiền'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    try {
      await ref.read(verifyFlowControllerProvider.notifier).requestRefund();
      // Show confirmation screen
      Navigator.pushReplacementNamed(context, '/verify/refunded');
    } catch (e) {
      showAppSnackbar(context, 'Lỗi: $e', type: SnackbarType.error);
    }
  }
}
```

## Resubmit flow

Tap "Bổ sung ngay" → navigate đến rejected item đầu tiên:

```dart
void _onResubmit() {
  final firstRejected = state.rejectedItems.firstOrNull;
  if (firstRejected != null) {
    _onItemTap(firstRejected);
  }
}
```

Sau khi user re-upload xong tất cả rejected items, screen detect và auto-call resubmit:

```dart
// Trong screens cccd/selfie capture
if (widget.isResubmit) {
  ref.read(verifyFlowControllerProvider.notifier).resubmitItem(itemId);
  // Nếu hết rejected items → navigate về pending screen
}
```

## Edge cases

1. Multi-item reject (cả 3 items reject): list show all, tap each navigate đúng
2. Refund đã processed: screen update với "Đã hoàn 23.602K vào VNPay" thay button refund
3. Admin reject lý do không rõ ràng: contact support button hiện thay quote card

## Output

1. `rejected_screen.dart`
2. `_RejectableItemTile` widget
3. Refund confirm dialog
4. Resubmit flow integration
5. `refunded_screen.dart` confirmation
```

---

## 12. Prompt 10 — Controller + Repository

```
Build full data layer cho verify feature: models, repository, controller.

## Models cần

(Xem spec section 6.1 cho full models)

Path: `lib/features/verify/data/models/`
- `verify_state.dart` (Freezed, có @JsonSerializable cho local storage)
- `cccd_upload.dart`
- `selfie_upload.dart`
- `ocr_result.dart`
- `plan.dart`
- `payment_session.dart`

Dùng `freezed_annotation` + `json_serializable`. Run `dart run build_runner build --delete-conflicting-outputs`.

## Repository

Path: `lib/features/verify/data/repositories/`

```dart
// verify_repository.dart (abstract)
abstract class VerifyRepository {
  Future<CCCDUpload> uploadCCCDFront(File image);
  Future<CCCDUpload> uploadCCCDBack(File image);
  Future<SelfieUpload> uploadSelfie(File image, {required String cccdFrontId});
  
  Future<List<Plan>> fetchPlans();
  
  Future<PaymentSession> initiatePayment({
    required String planId,
    required BillingCycle billingCycle,
    required PaymentMethod method,
    required int rooms,
  });
  Future<PaymentStatus> checkPaymentStatus(String sessionId);
  
  Future<SubmissionResult> submitForApproval();
  Future<ApprovalResult> checkApprovalStatus(String submissionId);
  Future<void> resubmit({required List<String> items});
  Future<RefundResult> requestRefund(String submissionId);
}

// verify_repository_impl.dart
class VerifyRepositoryImpl implements VerifyRepository {
  final Dio _dio;
  
  VerifyRepositoryImpl(this._dio);
  
  @override
  Future<CCCDUpload> uploadCCCDFront(File image) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path),
    });
    final response = await _dio.post('/verify/cccd-front', data: formData);
    return CCCDUpload.fromJson(response.data);
  }
  
  // ... implement các methods khác
}

// Provider
@riverpod
VerifyRepository verifyRepository(VerifyRepositoryRef ref) {
  return VerifyRepositoryImpl(ref.read(dioProvider));
}
```

## Controller

(Xem spec section 6.2 cho full controller)

Path: `lib/features/verify/controllers/verify_flow_controller.dart`

Tất cả operations đã list trong spec. Đặc biệt note:

1. **Save draft local storage**: mỗi state change → save JSON sang `SharedPreferences` để resume nếu user close app
2. **Optimistic update**: cho operations nhẹ, revert nếu fail
3. **Polling**: implement riêng provider cho approval status stream

## Local storage

Path: `lib/core/storage/local_storage.dart`

```dart
@riverpod
class LocalStorage extends _$LocalStorage {
  late SharedPreferences _prefs;
  
  @override
  FutureOr<void> build() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  void saveVerifyDraft(VerifyFlowState state) {
    _prefs.setString('verify_draft', jsonEncode(state.toJson()));
  }
  
  VerifyFlowState? getVerifyDraft() {
    final json = _prefs.getString('verify_draft');
    if (json == null) return null;
    return VerifyFlowState.fromJson(jsonDecode(json));
  }
  
  void clearVerifyDraft() {
    _prefs.remove('verify_draft');
  }
}
```

## Mock data cho dev

Path: `lib/features/verify/data/mock/mock_verify_repository.dart`

```dart
class MockVerifyRepository implements VerifyRepository {
  @override
  Future<CCCDUpload> uploadCCCDFront(File image) async {
    await Future.delayed(const Duration(seconds: 2));  // simulate network
    return CCCDUpload(
      id: 'cccd_front_001',
      imageUrl: 'https://placeholder.com/cccd_front',
      ocrResult: const OCRResult(
        cccdNumber: '001192012345',
        fullName: 'NGUYỄN VĂN TUẤN',
        dob: '1992-05-12',
        // ...
      ),
      confidence: 0.94,
      uploadedAt: DateTime.now(),
    );
  }
  
  // ... implement mock cho các methods khác
}
```

Use trong `kDebugMode`:

```dart
@riverpod
VerifyRepository verifyRepository(VerifyRepositoryRef ref) {
  if (kDebugMode && useMockData) {
    return MockVerifyRepository();
  }
  return VerifyRepositoryImpl(ref.read(dioProvider));
}
```

## Output

1. Models đầy đủ (với @freezed + @JsonSerializable)
2. Repository abstract + impl
3. Controller với @riverpod + tất cả operations
4. Mock repository cho dev
5. Local storage integration
6. Approval status stream provider
7. Note dependencies cần thêm vào pubspec
```

---

## 13. Prompt 11 — Tests

```
Viết tests cho verify feature.

## Test files cần

```
test/features/verify/
├── controllers/
│   └── verify_flow_controller_test.dart
├── data/
│   ├── models/
│   │   ├── verify_state_test.dart
│   │   └── plan_test.dart
│   └── repositories/
│       └── verify_repository_test.dart
└── views/
    ├── paywall_modal_test.dart
    ├── cccd_capture_screen_test.dart
    ├── selfie_capture_screen_test.dart
    ├── select_plan_screen_test.dart
    ├── payment_screen_test.dart
    ├── pending_approval_screen_test.dart
    ├── trial_active_screen_test.dart
    └── rejected_screen_test.dart

test/golden/verify/
├── paywall_modal_dark.png
├── cccd_capture_dark.png
├── selfie_capture_dark.png
├── select_plan_dark.png
├── payment_screen_dark.png
├── pending_approval_dark.png
├── trial_active_dark.png
└── rejected_dark.png
```

## Unit tests

(Xem spec section 10.1 cho full list)

Coverage minimum 75% cho `lib/features/verify/`.

```dart
group('VerifyFlowController', () {
  test('uploadCCCDFront updates state with cccdFront', () async {
    final container = ProviderContainer(overrides: [
      verifyRepositoryProvider.overrideWithValue(MockVerifyRepository()),
    ]);
    
    final controller = container.read(verifyFlowControllerProvider.notifier);
    final mockFile = File('test/fixtures/sample_cccd.jpg');
    
    await controller.uploadCCCDFront(mockFile);
    
    final state = container.read(verifyFlowControllerProvider);
    expect(state.cccdFront, isNotNull);
    expect(state.cccdFront!.id, 'cccd_front_001');
  });
  
  test('uploadSelfie throws FaceMismatchException when score < 0.85', () async {
    // Setup mock to return low score
    final mockRepo = MockVerifyRepository(faceMatchScore: 0.65);
    final container = ProviderContainer(overrides: [
      verifyRepositoryProvider.overrideWithValue(mockRepo),
    ]);
    
    expect(
      () => container.read(verifyFlowControllerProvider.notifier).uploadSelfie(mockFile),
      throwsA(isA<FaceMismatchException>()),
    );
  });
  
  // ... thêm tests theo spec
});
```

## Widget tests

(Xem spec section 10.2)

```dart
testWidgets('PaywallModal renders 4 steps', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: PaywallModal(onProceed: () {})),
  ));
  
  expect(find.text('Đăng phòng để kiếm tiền'), findsOneWidget);
  expect(find.text('Chụp CCCD + Selfie'), findsOneWidget);
  expect(find.text('Thông tin homestay'), findsOneWidget);
  expect(find.text('Chọn gói + Thanh toán'), findsOneWidget);
  expect(find.text('Chờ admin duyệt'), findsOneWidget);
});

testWidgets('SelectPlanScreen toggle Yearly recalculates prices', (tester) async {
  // Setup with rooms = 15
  // Render screen
  // Verify monthly price 2.985.000đ
  // Tap "Hàng năm" toggle
  // Verify yearly price 2.388.000đ (after -20%)
});
```

## Golden tests

```dart
testWidgets('paywall_modal_dark golden', (tester) async {
  await loadAppFonts();
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(
      backgroundColor: AppColors.darkBg,
      body: PaywallModal(onProceed: () {}),
    ),
  ));
  await expectLater(
    find.byType(PaywallModal),
    matchesGoldenFile('../../../golden/verify/paywall_modal_dark.png'),
  );
});
```

## Integration tests

```
test/integration/verify_full_flow_test.dart
```

Test full happy path: paywall → cccd front → cccd back → selfie → property info → plan → payment → pending → approved → trial active.

## Output

1. Unit tests đầy đủ cho controller
2. Widget tests cho 8 screens
3. Golden tests setup + 8 golden files
4. Integration test happy path + reject path
5. Mock repository setup
6. Test fixtures (sample CCCD images)
7. Coverage report (target ≥ 75%)
```

---

## 14. Workflow recommended (5 ngày)

### Ngày 1 — Foundation

**Sáng (4h)**:
- Paste System Context
- Áp Prompt 1 (palette + theme)
- Update `app_colors.dart`, `app_color_scheme.dart`, `app_theme.dart`
- Smoke test app cũ vẫn chạy được với palette mới
- Áp Prompt 10 (controller + repository) — phần models + repository abstract

**Chiều (4h)**:
- Tiếp Prompt 10 — repository impl + mock repository
- Setup LocalStorage cho draft
- Build provider + controller skeleton
- Test smoke với mock data

### Ngày 2 — Verify KYC screens

**Sáng (4h)**:
- Áp Prompt 2 (PaywallModal) — Screen 1
- Tích hợp với Property Management screen (trigger paywall khi free owner click)
- Test flow trigger

**Chiều (4h)**:
- Áp Prompt 3 (CCCDCaptureScreen) — Screen 2
- Build CameraFrameOverlay + StepperProgress reusable widgets
- Test với image_picker, mock OCR response

### Ngày 3 — Selfie + Subscription

**Sáng (4h)**:
- Áp Prompt 4 (SelfieCaptureScreen) — Screen 3
- Mock face match logic + error handling (3 lần fail)

**Chiều (4h)**:
- Áp Prompt 5 (SelectPlanScreen) — Screen 4
- Build PlanCard + PlanPriceCalculator
- Test toggle Monthly/Yearly + auto-suggest

### Ngày 4 — Payment + Approval

**Sáng (4h)**:
- Áp Prompt 6 (PaymentScreen) — Screen 5
- Build PaymentMethodTile + OrderSummaryCard
- VNPay QR dialog (mock first, real integration sau)
- Polling logic

**Chiều (4h)**:
- Áp Prompt 7 (PendingApprovalScreen) — Screen 6
- Build StatusTimeline reusable
- Approval status stream provider
- FCM push notification handler stub

### Ngày 5 — Final + Tests

**Sáng (4h)**:
- Áp Prompt 8 (TrialActiveScreen) — Screen 7
- TrialCountdownText realtime
- Áp Prompt 9 (RejectedScreen) — Screen 8
- Refund + resubmit flow

**Chiều (4h)**:
- Áp Prompt 11 (Tests)
- Run all tests, fix failing
- Manual QA full flow trên device
- Screenshot 8 screens cho PR

### Buffer (Ngày 6-7)

- Polish animations
- Edge case handling
- Backend integration (thay mock bằng real API)
- Code review fixes

---

## 15. Tips & validation

### Tip 1 — Đừng skip Prompt 1

Update palette là foundation. Nếu skip → mọi screen sau phải fix lại hardcode color → tốn gấp đôi thời gian.

### Tip 2 — Test với mock data trước

Đừng đợi backend xong. Build full flow với MockVerifyRepository → swap sang real API ngày cuối.

### Tip 3 — Validate sau mỗi screen

```bash
# Check hardcoded colors
grep -r "Color(0xFF" lib/features/verify/

# Check radius 100 cho status pill (anti-pattern)
grep -r "BorderRadius.circular(100)" lib/features/verify/

# Check glow shadow (anti-pattern)
grep -rn "BoxShadow" lib/features/verify/ | grep -v "rgba(0,0,0"
```

### Tip 4 — Iterate khi AI sai

Reply mẫu khi gặp anti-pattern:

```
Tôi thấy code có vấn đề:
1. Dòng 42: dùng `Color(0xFF7AB5BD)` cho button bg → calm operations dùng `colors.brand` = #B5D4DA cho button primary BG, text là #16252B (dark canvas).
2. Dòng 67: status pill `borderRadius: 100` → calm operations dùng radius 4-6 cho status pill, không phải full pill.
3. Dòng 89: icon container có `BoxShadow(color: AppColors.jadeMuted.withOpacity(0.3))` → bỏ glow ở mọi container manager, chỉ giữ ở FAB.

Sửa lại theo calm operations.
```

### Tip 5 — Combo prompts khi chain task

Trong cùng chat:

```
Áp Prompt 3 cho Screen 2 (CCCDCaptureScreen)
[AI gen]

OK rồi, áp tiếp Prompt 11 cho widget test của screen này
[AI gen tests]
```

AI giữ context, output consistent.

### Tip 6 — Giữ pubspec.yaml updated

Verify flow cần thêm:

```yaml
dependencies:
  camera: ^0.10.5
  image_picker: ^1.0.4
  shared_preferences: ^2.2.2
  flutter_animate: ^4.3.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  dio: ^5.3.3
  intl: ^0.18.1

dev_dependencies:
  freezed: ^2.4.5
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
  mocktail: ^1.0.1
  golden_toolkit: ^0.15.0
```

---

## Phụ lục — Quick reference

### Token cheat sheet (calm operations dark)

```
Button primary:       bg #B5D4DA, text #16252B
Button secondary:     bg #2A4147, text #D6DDE0
Button outline:       bg #1E343A, border #B5D4DA, text #B5D4DA

Card default:         bg #1E343A, border #2A4147, radius 14
Card highlighted:     bg #1E343A, border 2px #7AB5BD

Text heading:         #D6DDE0 w800 (titleLarge), w700 (titleMedium)
Text body:            #D6DDE0 w500
Text muted:           #A8B0B4 w500
Text hint:            #8A9398 w500
Text brand link:      #7AB5BD w700

Status pill success:  bg #1F3A2D, text #6FA88B, radius 4
Status pill warning:  bg #2A2419, text #C9A567, radius 4
Status pill error:    bg #3A2421, text #C97A6F, radius 4
Status pill info:     bg #1F353A, text #7AB5BD, radius 4

Status strip success: bg gradient(rgba success 0.08 → 0.02), border-left 3px #6FA88B
Status strip info:    bg #1F353A, border-left 3px #7AB5BD
```

---

**Phiên bản**: 2.0 (calm operations)
**Ngày**: 27/04/2026
**Companion**: `halong24h-verify-subscription-spec.md`
**Use cho**: Verify + Subscription Flow 8 screens
