# Halong24h — Verify + Subscription Flow Implementation Spec

> Tài liệu giao việc dev — build flow Verify CCCD + Subscription cho Free Owner.
> 8 screens, dark mode "calm operations" palette.
>
> Companion docs:
> - `halong24h-color-system-v2.md` — color tokens
> - `halong24h-component-specs-v2.md` — component anatomy
> - `halong24h-ai-prompt-templates.md` — AI prompt cho dev
>
> Phiên bản: 1.0
> Ngày: 27/04/2026
> Sprint deadline: 7-10 ngày

---

## Mục lục

1. [Business context](#1-business-context)
2. [User flow tổng thể](#2-user-flow-tổng-thể)
3. [Pricing & plans](#3-pricing--plans)
4. [Color palette CALM OPERATIONS (replace v2 cũ)](#4-color-palette-calm-operations-replace-v2-cũ)
5. [8 Screens spec chi tiết](#5-8-screens-spec-chi-tiết)
6. [Data models & state](#6-data-models--state)
7. [API contracts](#7-api-contracts)
8. [File structure](#8-file-structure)
9. [Edge cases](#9-edge-cases)
10. [Testing checklist](#10-testing-checklist)
11. [Definition of Done](#11-definition-of-done)
12. [Migration notes](#12-migration-notes)

---

## 1. Business context

### 1.1 App scope

Halong24h là SaaS B2B cho Owner/Sale quản lý homestay. App mobile = công cụ vận hành. Web (riêng) = customer-facing + chat + voucher creator.

### 1.2 Business model

- **SaaS subscription**: tính theo phòng, 3 tier (Starter / Professional / Enterprise)
- **Annual discount**: −20% khi trả năm
- **Free trial**: 7 ngày, bắt đầu sau khi admin duyệt KYC
- **Refund**: money-back 14 ngày, sau đó no-refund

### 1.3 Roles

| Role | Auth | Verify CCCD | Quản lý property |
|---|---|---|---|
| Free Owner | Đăng ký bình thường | Chỉ khi muốn đăng phòng | KHÔNG |
| Verified Owner | Đã verify + paid | Đã verify | CÓ — full quyền |
| Sale | Owner invite qua email | KHÔNG cần | Có — theo property được assign |
| Admin Halong24h | Internal account | Đã verify nội bộ | Toàn quyền + duyệt KYC |

### 1.4 Free Owner experience

Free Owner đăng ký xong vẫn dùng app như Customer:
- ✓ Xem property của owner khác đã list
- ✓ Tạo booking cho property của người khác (như đặt giúp gia đình/bạn)
- ✓ Xem booking đã đặt
- ✗ Dashboard không có data thật → empty state
- ✗ Quản lý property/phòng/báo cáo → bị lock

**Khi click vào tab/action bị lock** → trigger Paywall modal (Screen 1).

### 1.5 Key business rules

1. **Đếm phòng billing**: tất cả phòng đã tạo (kể cả pause/maintenance), không loại trừ
2. **Verify ngay khi muốn đăng phòng**: không bắt verify lúc đăng ký
3. **Trial 7 ngày**: bắt đầu ngay sau admin duyệt
4. **Admin duyệt trong 24h**: SLA cam kết, nếu quá → admin manager phải xử lý
5. **Read-only mode khi hết hạn**: không khoá hoàn toàn, owner vẫn xem được data cũ

---

## 2. User flow tổng thể

```
┌─────────────────────┐
│ FREE OWNER          │
│ (mới đăng ký)       │
│                     │
│ - Xem property      │
│ - Đặt booking       │
│ - Dashboard empty   │
└──────────┬──────────┘
           │
           │ Click "Đăng phòng" /
           │ "Tạo property"
           ▼
┌─────────────────────┐
│ Screen 1            │
│ PAYWALL MODAL       │
│ - Giải thích flow   │
│ - 4-step preview    │
└──────────┬──────────┘
           │ "Bắt đầu ngay"
           ▼
┌─────────────────────┐
│ Screen 2-3          │
│ KYC VERIFY          │
│ - CCCD mặt trước    │
│ - CCCD mặt sau      │
│ - Selfie face match │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Property info form  │  (không trong scope spec này, đã có)
│ Tên + địa chỉ       │
│ Số phòng dự kiến    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Screen 4            │
│ CHỌN GÓI            │
│ - 3 tier cards      │
│ - Monthly/Yearly    │
│ - Auto-suggest tier │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Screen 5            │
│ THANH TOÁN          │
│ - Order summary     │
│ - Payment methods   │
└──────────┬──────────┘
           │ (payment success)
           ▼
┌─────────────────────┐
│ Screen 6            │
│ PENDING APPROVAL    │
│ - Status timeline   │
│ - Waiting 24h       │
└──────────┬──────────┘
           │
           │ Admin duyệt
     ┌─────┴─────┐
     │           │
   APPROVE     REJECT
     │           │
     ▼           ▼
┌─────────┐  ┌─────────────┐
│Screen 7 │  │Screen 8     │
│TRIAL    │  │REJECTED     │
│ACTIVE   │  │- Lý do      │
│7 ngày   │  │- Bổ sung    │
└─────────┘  └─────────────┘
```

---

## 3. Pricing & plans

### 3.1 3 tiers

| Tier | Price/phòng/tháng | Min charge/tháng | Max phòng | Features |
|---|---|---|---|---|
| **Starter** | 199.000đ | 1.999.000đ (~10 phòng) | 20 | Booking, Calendar, Check-in/out, Báo cáo cơ bản |
| **Professional** | 149.000đ | 2.999.000đ (~20 phòng) | 50 | Starter + Pricing rules + Housekeeping + Expenses + Báo cáo nâng cao |
| **Enterprise** | 99.000đ | 4.999.000đ (~50 phòng) | Không giới hạn | Pro + Multi-property + Channel sync + API + Hỗ trợ riêng |

### 3.2 Annual discount

Trả năm = giá tháng × 12 × 80% (giảm 20%).
Ví dụ Professional 15 phòng:
- Monthly: 2.235.000đ × 12 = 26.820.000đ
- Yearly: 2.235.000đ × 12 × 0.8 = **21.456.000đ** (tiết kiệm 5.364.000đ)

### 3.3 VAT

Tính VAT 10% trên giá đã giảm. Tổng = (price × 0.8) × 1.1 cho yearly.

> **Confirm với business**: nếu Halong24h chưa xuất VAT, bỏ field VAT khỏi summary. Hiện spec mặc định CÓ VAT.

### 3.4 Auto-suggest tier

Khi owner nhập số phòng dự kiến, system suggest tier phù hợp:

```dart
SuggestedTier suggestTier(int rooms) {
  if (rooms <= 20) return SuggestedTier.starter;
  if (rooms <= 50) return SuggestedTier.professional;
  return SuggestedTier.enterprise;
}
```

Card tier suggest sẽ có border 2px brand + ribbon "PHỔ BIẾN NHẤT" + tagline "Phù hợp với bạn".

### 3.5 Refund policy

- 0-14 ngày sau payment: **refund 100%** (money-back guarantee)
- 15+ ngày: **no refund**, có thể downgrade tier hoặc cancel auto-renew

---

## 4. Color palette CALM OPERATIONS (replace v2 cũ)

> **Quan trọng**: Palette này thay thế dark mode v2 trước. Sửa file `app_colors.dart` theo bảng dưới.

### 4.1 Vì sao đổi

Dark mode v2 cũ có vấn đề mỏi mắt sau dùng nhiều giờ:
- Background quá tối (`#0A1F26`) → contrast extreme
- Saturation cao 70-85% → chói trên dark
- Quá nhiều glow shadow màu → mắt phải auto-focus liên tục
- Font weight w800 khắp nơi → không có điểm nghỉ

Calm operations giải quyết: lighter bg, muted saturation, glow chỉ active state, w700 default.

### 4.2 Token mapping

```dart
// CANVAS & SURFACE — light hơn để giảm contrast extreme
darkBg          = Color(0xFF16252B);  // was #0A1F26
darkSurface     = Color(0xFF1E343A);  // was #0F2F38
darkSurfaceAlt  = Color(0xFF1B2D33);  // appbar, bottomnav
darkContainer   = Color(0xFF243439);  // icon container, search
darkBorder      = Color(0xFF2A4147);  // border default
darkDivider     = Color(0xFF243439);  // item separator

// TEXT — ấm hơn, ít chói
textPrimary     = Color(0xFFD6DDE0);  // was #E6F4F7
textSecondary   = Color(0xFFA8B0B4);
textTertiary    = Color(0xFF8FB0B8);
textHint        = Color(0xFF8A9398);
textDisabled    = Color(0xFF6A7378);

// BRAND JADE — muted, không neon
jadeText        = Color(0xFFB5D4DA);  // text on dark
jadeMuted       = Color(0xFF7AB5BD);  // icon, accent (was #5BCEDC)
jadeBg          = Color(0xFF2A4147);  // selected pill bg
jadePillBg      = Color(0xFF1F353A);  // info card bg

// GOLD — muted
goldText        = Color(0xFFC9A567);  // was #F4CD7A
goldMuted       = Color(0xFFB89C59);  // was #E5B547
goldBg          = Color(0xFF383021);  // icon container bg
goldBorder      = Color(0xFF4A3F25);
goldPillBg      = Color(0xFF2A2419);  // alert/insight bg

// CORAL — muted
coralText       = Color(0xFFC9A084);
coralMuted      = Color(0xFFB86D5A);  // was #F2856B (notification badge)
coralBg         = Color(0xFF3A2820);

// STATUS — calmer
successText     = Color(0xFF6FA88B);  // was #4ADE80 (sage thay neon)
successBg       = Color(0xFF1F3A2D);
successBorder   = Color(0xFF2D4D3D);

warningText     = Color(0xFFC9A567);  // mustard thay neon amber
warningBg       = Color(0xFF2A2419);
warningBorder   = Color(0xFF4A3F25);

errorText       = Color(0xFFC97A6F);  // rose thay neon red
errorBg         = Color(0xFF3A2421);
errorBorder     = Color(0xFF4D2E29);

infoText        = Color(0xFF7AB5BD);
infoBg          = Color(0xFF1F353A);

vipText         = Color(0xFFA488B8);  // was #C084FC
vipBg           = Color(0xFF2D2438);
```

### 4.3 Quy tắc dùng

1. **CTA primary**: bg `jadeText` (#B5D4DA), text `darkBg` (#16252B). Không bg jadeMuted vì quá tối.
2. **Glow shadow**: chỉ FAB + active state. Bỏ ở mọi icon container.
3. **Border decorative**: chỉ "popular" card và rejected card. Còn lại border default `#2A4147`.
4. **Status pill**: border-radius 4-6px, KHÔNG full pill 100px.
5. **Font weight**: w700 default, w800 chỉ headlines. Không spam w800.
6. **Decorative blobs/stars**: BỎ HẾT ở manager screens. Chỉ giữ ở Customer-facing screens cảm xúc (nếu có).

---

## 5. 8 Screens spec chi tiết

> Mỗi screen có: vị trí trong flow, anatomy, tokens, interactions, edge cases.

### Screen 1 — Paywall Modal

**Khi hiện**: Free Owner click action bị lock (Tạo property, Quản lý phòng, Báo cáo doanh thu).

**Type**: Modal bottom sheet (không full-screen).

**Anatomy**:
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
│  │ ① Chụp CCCD + Selfie     │   │
│  │ ② Thông tin homestay     │   │
│  │ ③ Chọn gói + Thanh toán  │   │
│  │ ④ Chờ admin duyệt        │   │
│  └──────────────────────────┘   │
│                                  │
│  [Để sau]      [Bắt đầu ngay →] │
│  Điều khoản dịch vụ              │
└─────────────────────────────────┘
```

**Tokens**:
- Bottom sheet bg: `darkSurface` `#1E343A`
- Border top: `darkBorder` `#2A4147`
- Top border-radius: 24px
- Drag handle: `#4A5560`, 40×4
- Icon container: 60×60, radius 16, bg `goldBg` `#383021`, icon `goldMuted`
- Title: 18px, w700, `textPrimary`
- Subtitle: 13px, w500, `textSecondary`, line-height 1.45
- Step preview card: bg `darkBg` `#16252B`, border 1px `darkBorder`, radius 12, padding 14
- Step circle: 24×24, radius 50%, bg `darkBorder`, text `jadeText`
- Button "Để sau" (secondary): bg `darkBorder`, text `textPrimary`
- Button "Bắt đầu ngay" (primary): bg `jadeText`, text `darkBg`, w700
- Disclaimer: 10px, `textHint`, link `jadeMuted`

**Interactions**:
- Tap "Để sau" → close modal, return to previous screen
- Tap "Bắt đầu ngay" → push verify flow (Screen 2)
- Swipe down on drag handle → close (same as "Để sau")
- Tap "Điều khoản dịch vụ" → open in-app webview với ToS

**Animation**:
- Mount: slide up từ bottom, 300ms easeOutCubic
- Backdrop scrim: fade in `rgba(0,0,0, 0.6)`, 200ms
- Step list items: stagger fade-in 60ms × index

**Edge cases**:
- Owner đã từng start verify rồi cancel → modal hiện thêm note "Tiếp tục từ bước X?" với button "Tiếp tục" thay "Bắt đầu ngay"
- Modal trigger từ deep-link → mark source để analytics track funnel

---

### Screen 2 — Chụp CCCD mặt trước

**Vị trí**: Bước 1/4 của Verify flow.

**Anatomy**:
```
┌─────────────────────────────────┐
│ [←] BƯỚC 1/4 · Verify CCCD      │
│     Mặt trước CCCD               │
│ ━━━━━━━ ────── ────── ──────    │ progress bar 4 segments
│                                  │
│ Đặt CCCD vào khung. Đảm bảo     │
│ ánh sáng đủ và không bị bóng.   │
│                                  │
│  ┌──────────────────────────┐   │
│  │ ┌─               ─┐      │   │
│  │ │  [CAMERA FRAME]  │      │   │
│  │ │   với 4 corners  │      │   │
│  │ │   + scan line    │      │   │
│  │ └─               ─┘      │   │
│  │                          │   │
│  │  📷 Đặt CCCD vào khung   │   │
│  │     Tự động chụp khi     │   │
│  │     nhận diện            │   │
│  └──────────────────────────┘   │
│                                  │
│  ┌─ Lưu ý ──────────────────┐   │
│  │ ⓘ CCCD còn hiệu lực · ...│   │
│  └──────────────────────────┘   │
│                                  │
│  [📁]      [📷 Mở camera]       │
└─────────────────────────────────┘
```

**Tokens**:
- AppBar bg: `darkSurfaceAlt` `#1B2D33`
- Back button: 32×32, bg `darkContainer`, icon `textTertiary`
- Overline: 10px w700, `textHint`
- Title: 14px w700, `textPrimary`
- Progress bar segment: 3px, active `jadeMuted`, inactive `darkContainer`
- Camera frame: bg `#0F1F23` (deeper than canvas), radius 16
- Corner brackets: 18×18, border 2.5px `jadeText`
- Scan line: 1px height, gradient `transparent → jadeMuted → transparent`
- Center icon container: 48×48, radius 12, bg `darkBorder`, icon `jadeMuted`
- Hint text: 12px w700 `textPrimary` + 10px w500 `textHint`
- Lưu ý strip: bg `infoBg` `#1F353A`, border-left 3px `jadeMuted`, radius 0/10/10/0
- "Tải ảnh" button (icon-only): 50×52, bg `darkContainer`, icon `textPrimary`
- "Mở camera" button: bg `jadeText`, text `darkBg`, w700, height 52

**Interactions**:
- Tap "Mở camera" → mở native camera với overlay frame
- Tap "Tải ảnh" → mở image picker (gallery)
- Camera auto-detect CCCD trong frame → chụp tự động + chuyển Step 2
- Manual capture button trong camera (nếu auto-detect fail)

**API**:
- `POST /verify/cccd-front` (multipart)
- Response: `{ id, imageUrl, ocrResult: { cccdNumber, fullName, dob, address }, confidence }`
- Nếu confidence < 0.8 → toast warning "OCR chưa rõ, vui lòng chụp lại"

**Edge cases**:
- Camera permission denied → screen alternate với 2 options: "Cấp quyền" hoặc "Tải ảnh sẵn"
- OCR fail nhiều lần (3 lần) → cho phép nhập tay manual + flag review cho admin
- File size > 10MB → compress trước khi upload

---

### Screen 3 — Selfie Face Match

**Vị trí**: Bước 3/4 (sau khi đã chụp CCCD 2 mặt).

**Anatomy**:
```
┌─────────────────────────────────┐
│ [←] BƯỚC 3/4 · Verify CCCD      │
│     Selfie xác minh khuôn mặt   │
│ ━━━━━ ━━━━━ ━━━━━ ──────       │
│                                  │
│  ┌─ ✓ CCCD đã xác minh ────┐    │
│  │ Nguyễn Văn Tuấn         │    │
│  │ 001192012345            │    │
│  └─────────────────────────┘    │
│                                  │
│  Chụp selfie để so khớp khuôn   │
│  mặt với ảnh trên CCCD          │
│                                  │
│  ┌──────────────────────────┐   │
│  │                          │   │
│  │      ╭─────╮             │   │
│  │      │ 👤  │ oval frame  │   │
│  │      ╰─────╯             │   │
│  │                          │   │
│  │  ⏱ Đặt khuôn mặt vào     │   │
│  │     khung                │   │
│  └──────────────────────────┘   │
│                                  │
│  ┌─ Mẹo selfie thành công ─┐   │
│  │ ✓ Ánh sáng đủ            │   │
│  │ ✓ Tháo kính, khẩu trang  │   │
│  │ ✓ Nhìn thẳng camera      │   │
│  └──────────────────────────┘   │
│                                  │
│  [👤 Bắt đầu chụp selfie]      │
└─────────────────────────────────┘
```

**Tokens**: tương tự Screen 2, thêm:
- Success card top: bg `successBg` `#1F3A2D`, border `successBorder`, icon container bg `successBorder`, icon `successText`
- Oval frame: width 140, height 180, border 2px dashed `#4A5560`
- Live status indicator: bg `darkContainer`, dot 6×6 `warningText`, text `warningText` w700
- Tips card: bg `darkSurfaceAlt`, border `darkBorder`, check icon `successText`

**Interactions**:
- Open camera với face detection overlay
- Real-time hint: 
  - "Đặt khuôn mặt vào khung" (chưa detect)
  - "Đang phân tích..." (đang capture)
  - "✓ Đã chụp" (success)
- Auto-capture sau 2 giây khi detect face stable
- API gọi face match với CCCD đã upload trước

**API**:
- `POST /verify/selfie` (multipart)
- Response: `{ id, imageUrl, faceMatchScore, isValid }`
- Nếu `faceMatchScore < 0.85` → throw FaceMismatchError
- Block sau 3 lần fail → contact support

**Edge cases**:
- Face match score < 0.85: alert "Khuôn mặt không khớp với CCCD. Thử lại?"
- 3 lần fail liên tiếp → lock 1 giờ + email admin review thủ công
- Đeo kính/khẩu trang → AI detect cảnh báo trước khi capture

---

### Screen 4 — Chọn gói

**Vị trí**: Bước 5/7 (sau khi đã verify KYC + property info).

**Anatomy**: xem mockup, có 4 sections chính:
1. **Number of rooms summary**: card readonly, có link "Sửa →" quay lại Step 4
2. **Billing cycle toggle**: pill switcher Monthly | Yearly với badge `−20%`
3. **3 plan cards**: Starter / Professional (suggested) / Enterprise
4. **Trial banner**: card sage green + "7 ngày dùng thử miễn phí"

**Tokens cho plan card**:

```dart
// Default plan card
decoration: BoxDecoration(
  color: colors.bgSurface,        // #1E343A
  border: Border.all(
    color: colors.borderDefault,  // #2A4147
    width: 1,
  ),
  borderRadius: BorderRadius.circular(14),
)
padding: EdgeInsets.all(14)

// Suggested plan card (highlight)
decoration: BoxDecoration(
  color: colors.bgSurface,
  border: Border.all(
    color: colors.brandLight,     // #7AB5BD
    width: 2,
  ),
  borderRadius: BorderRadius.circular(14),
)

// Ribbon "PHỔ BIẾN NHẤT"
position: top -8, right 14
padding: 2px 8px
bg: colors.brandLight             // #7AB5BD
text: colors.bgCanvas             // #16252B (dark text on light bg)
fontSize: 9, w700, letterSpacing: 0.3
borderRadius: 4
```

**Plan card structure**:
- Header row: Tên plan (15px w700) + range phòng (10px muted) | Price (16px w700) + delta info (10px)
- Divider: 1px `darkDivider`
- Features list: 3-4 bullets với check icon `successText`

**Interactions**:
- Tap toggle Monthly/Yearly → recalculate price all 3 plans
- Tap plan card → select + update CTA button text "Chọn [Plan name] → Thanh toán"
- Tap "Sửa →" room count → navigate back step 4 with state preserved
- Tap CTA → push Screen 5 với selected plan

**Computed values**:
```dart
double calculatePrice(int rooms, Tier tier, BillingCycle cycle) {
  final perRoom = tier.pricePerRoom;
  final monthly = max(rooms * perRoom, tier.minCharge);
  return cycle == BillingCycle.yearly 
      ? monthly * 12 * 0.8 
      : monthly;
}

double calculateSavings(int rooms, Tier suggested) {
  final lowerTierPrice = calculatePrice(rooms, Tier.starter, BillingCycle.monthly);
  final suggestedPrice = calculatePrice(rooms, suggested, BillingCycle.monthly);
  return lowerTierPrice - suggestedPrice;
}
```

---

### Screen 5 — Thanh toán

**Vị trí**: Bước 6/7.

**Anatomy**:
```
┌─────────────────────────────────┐
│ [←] BƯỚC 6/7 · Subscription     │
│     Thanh toán                   │
│                                  │
│  ┌─ CHI TIẾT ĐƠN HÀNG ──────┐   │
│  │ Pro × 12 tháng    26.820K│   │
│  │ Giảm năm (-20%)   -5.364K│   │
│  │ VAT 10%           +2.146K│   │
│  │ ─────────────────────────│   │
│  │ Tổng           23.602.000│   │
│  │                          │   │
│  │ ✓ 7 ngày trial · Tính từ │   │
│  │   ngày được duyệt        │   │
│  └──────────────────────────┘   │
│                                  │
│  Phương thức thanh toán          │
│  ⦿ VNPay QR (selected)          │
│  ○ Chuyển khoản ngân hàng       │
│  ○ Thẻ tín dụng/ghi nợ          │
│                                  │
│  ┌─ 🔒 Hoàn tiền 14 ngày ───┐   │
│  └──────────────────────────┘   │
│                                  │
│  [🔒 Thanh toán 23.602.000đ]   │
└─────────────────────────────────┘
```

**Order summary breakdown**:
- Mỗi line: label trái + value phải (12px w500/w700)
- Discount line: value màu `successText`
- Tax line: value `textPrimary` w700
- Divider 1px `darkDivider`
- Total: label 13px w700 + value 18px w700 `jadeText`
- Trial badge: bg `successBg`, text `successText`, padding 6px 10px, radius 8

**Payment method tile**:
- Default: bg `bgSurface`, border 1px `darkBorder`, radio empty
- Selected: bg `bgSurface`, border 2px `brandLight`, radio filled `jadeMuted` với check icon `darkBg`
- Logo container: 36×28, radius 6, bg `darkBorder` (default) hoặc `darkContainer` (alt)
- Title: 12px w700 `textPrimary` (default) hoặc `textSecondary` (unselected)
- Subtitle: 10px w500 `textHint`

**14-day refund disclaimer**:
- Bg `darkSurfaceAlt`, border 1px `darkDivider`, radius 10, padding 11
- Lock icon `textTertiary` size 14
- Text 10px w500 `textSecondary`, line-height 1.5

**CTA button**:
- Bg `jadeText`, text `darkBg`, height 52, radius 10
- Icon lock + text "Thanh toán an toàn 23.602.000đ"
- Loading state: spinner thay icon, disable

**Interactions**:
- Select payment method → update CTA text với method name (optional)
- Tap CTA → call `POST /payment/init` → redirect / show QR / open card form theo method
- VNPay: show QR full-screen overlay với countdown 15 phút
- Bank transfer: show STK + nội dung chuyển khoản, có button "Tôi đã chuyển"
- Card: open Stripe-like form

**API**:
- `POST /payment/init`: body `{ planId, billingCycle, paymentMethod, taxInfo }`, response `{ sessionId, redirectUrl, qrCode? }`
- `GET /payment/:sessionId/status`: poll mỗi 3s khi đang chờ payment

---

### Screen 6 — Chờ duyệt

**Vị trí**: Sau khi payment success, trước khi admin duyệt.

**Anatomy**:
```
┌─────────────────────────────────┐
│ Hồ sơ đã gửi                     │
│                                  │
│           [⏰] icon clock        │
│           với badge ✓ gold       │
│                                  │
│      Đang chờ admin duyệt        │
│   Hồ sơ sẽ được duyệt trong     │
│        vòng 24 giờ               │
│                                  │
│  ┌─ STATUS TIMELINE ──────────┐ │
│  │ ✓ CCCD xác minh            │ │
│  │ │  14:32 hôm nay           │ │
│  │ ✓ Thanh toán đã nhận       │ │
│  │ │  Pro 1 năm · 14:35       │ │
│  │ ⏳ Admin đang xét duyệt     │ │ (current)
│  │ │  Dự kiến hoàn tất 24h    │ │
│  │ ○ Bắt đầu trial 7 ngày     │ │
│  │   Sau khi được duyệt        │ │
│  └────────────────────────────┘ │
│                                  │
│  ┌─ ✉ Thông báo qua email ───┐  │
│  │ Sẽ gửi tới tuan@email.com │  │
│  └───────────────────────────┘  │
│                                  │
│  [Liên hệ HT]  [Về trang chủ]   │
└─────────────────────────────────┘
```

**Hero icon**:
- 80×80 container, radius 24, bg `infoBg` `#1F353A`, border 1px `darkBorder`
- Clock icon 36×36, stroke `jadeMuted`
- Badge tick gold: 22×22, position bottom-right -4/-4, border 3px canvas color, bg `goldText`, icon dark

**Title**: 18px w700 `textPrimary`
**Subtitle**: 12px w500 `textSecondary`, "24 giờ" highlight `goldText` w700

**Status timeline**:
- Container card với vertical rail 1.5px `darkBorder` ở left 27px
- Mỗi step: icon 28×28 (radius 50%) + title + subtitle
  - **Done step**: bg `successBorder` (#2D4D3D), border 2px `successText`, check icon
  - **Current step**: bg `goldBg` (#383021), border 2px `goldText`, dot inner 8×8 `goldText`
  - **Pending step**: bg `darkContainer`, border 2px `#4A5560`, empty
- Title done/current: 12px w700 `textPrimary`
- Title pending: 12px w700 `textHint`
- Subtitle done: 10px w600 `successText`
- Subtitle current: 10px w600 `goldText`
- Subtitle pending: 10px w500 `textDisabled`

**Email notification**:
- Status strip pattern: bg `infoBg`, border-left 3px `jadeMuted`, radius 0/10/10/0
- Icon mail `jadeMuted` 14×14
- Title 11px w700, body 10px w500 với email highlight `jadeMuted` w700

**Actions**:
- "Liên hệ hỗ trợ" (secondary): bg `darkBorder`, text `textPrimary`
- "Về trang chủ" (secondary alt): bg `bgSurface`, border 1px `darkBorder`, text `jadeText`

**Polling**:
- Screen polling `GET /verify/status` mỗi 30s
- Status `approved` → push Screen 7, status `rejected` → push Screen 8
- Push notification từ FCM cũng trigger transition (offline support)

**Edge cases**:
- Quá 24h chưa duyệt → escalation alert "Quá thời gian dự kiến, đang ưu tiên xử lý"
- Admin reject → push Screen 8
- Network offline khi polling → silent retry, không show error
- App killed → trigger lại polling khi resume foreground

---

### Screen 7 — Đã duyệt + Trial active

**Vị trí**: Admin approved → push lên màn hình này, replace stack.

**Anatomy**:
```
┌─────────────────────────────────┐
│ ┌─ ✓ Tài khoản đã được duyệt ─┐│ banner success
│ │ Trial 7 ngày bắt đầu         ││
│ │ từ hôm nay · Đến 04/05       ││
│ └──────────────────────────────┘│
│                                  │
│  ┌─ BẮT ĐẦU TỪ ĐÂY ──────────┐ │
│  │ Đăng phòng đầu tiên        │ │
│  │ Thiết lập homestay với 8   │ │
│  │ bước · ~10 phút             │ │
│  │                              │ │
│  │ ✓ Thông tin cơ bản           │ │
│  │ ✓ Địa chỉ + Vị trí           │ │
│  │ ✓ Hình ảnh + Tiện nghi       │ │
│  │ ✓ Chính sách + Giá phòng     │ │
│  │                              │ │
│  │ [Tạo homestay đầu tiên →]   │ │
│  └──────────────────────────────┘│
│                                  │
│  ┌─ GÓI CỦA BẠN ─────────────┐  │
│  │       [TRIAL · 6N 23H]    │  │
│  │ Professional · Hàng năm   │  │
│  │ 23.602.000đ/năm · Auto    │  │
│  │ ───────────────────────── │  │
│  │ DÙNG TRIAL ĐẾN  CHARGE TỪ │  │
│  │ 04/05/2026     04/05/2026 │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**Banner success top**:
- Bg `successBg`, border-bottom 1px `successBorder`
- Icon container 36×36, radius 12, bg `successBorder`, check icon `successText`
- Title 14px w700, subtitle 11px w500 `textTertiary`

**"Bắt đầu từ đây" card**:
- Bg `bgSurface`, border 1px `darkBorder`, radius 14, padding 16
- Overline 11px w700 `textTertiary` letter-spacing 0.3
- Title 16px w700, subtitle 12px w500 line-height 1.5
- Divider 1px `darkDivider`
- Bullet list với check icon `successText`
- CTA button bg `jadeText`, text `darkBg`, w700

**Subscription card**:
- Bg `bgSurface`, border 1px `darkBorder`, radius 14, padding 14
- Trial badge top-right: bg `goldBg`, text `goldText`, 9px w700, radius 4, padding 2px 8px
  - Text format: "TRIAL · X ngày Yh" (countdown realtime)
- Plan name 16px w700
- Subtitle 11px w500
- Divider 1px `darkDivider`
- 2-column grid: trial end date | charge start date
  - Label 9px w700 `textHint` letter-spacing
  - Value 12px w700 `textPrimary`

**Realtime countdown**:
```dart
Stream<Duration> trialCountdown(DateTime trialEnd) {
  return Stream.periodic(Duration(minutes: 1), (_) {
    return trialEnd.difference(DateTime.now());
  });
}
```

Format: "X ngày Yh" hoặc "Xh Y phút" nếu < 24h.

**Interactions**:
- Tap "Tạo homestay đầu tiên" → push property creation wizard (8 steps)
- Tap subscription card → push My Subscription detail screen (Phase 3, không trong scope spec này)

**Animation**:
- Banner: slide down 400ms
- Card "Bắt đầu": fade-in + slideY 0.1, delay 200ms
- Subscription card: fade-in + slideY, delay 400ms
- Trial badge: pulse subtle (scale 1 → 1.05) loop 2s khi < 24h còn lại

---

### Screen 8 — Bị từ chối

**Vị trí**: Admin reject → push lên screen này.

**Anatomy**:
```
┌─────────────────────────────────┐
│ ┌─ ✕ Hồ sơ chưa được duyệt ──┐ │ banner rose
│ │ Cần bổ sung thông tin        │ │
│ └──────────────────────────────┘│
│                                  │
│ Lý do từ admin                   │
│ ┌──────────────────────────────┐│
│ │ "Ảnh CCCD mặt trước bị mờ,  ││
│ │  không đọc được số CCCD..."  ││
│ │                              ││
│ │ — Admin Halong24h · 16:42    ││
│ └──────────────────────────────┘│
│                                  │
│ ┌─ ⓘ Tiền của bạn an toàn ───┐ │
│ │ Thanh toán đang được tạm    │ │
│ │ giữ. Sau khi bổ sung và      │ │
│ │ được duyệt, trial sẽ bắt    │ │
│ │ đầu. Hoặc yêu cầu hoàn 100% │ │
│ └──────────────────────────────┘│
│                                  │
│ ┌─ CẦN BỔ SUNG ──────────────┐  │
│ │ ✕ CCCD mặt trước  Cần lại →│  │
│ │ ✓ CCCD mặt sau    Đã duyệt │  │
│ │ ✓ Selfie          Đã duyệt │  │
│ └────────────────────────────┘  │
│                                  │
│ [Yêu cầu hoàn tiền] [Bổ sung →] │
└─────────────────────────────────┘
```

**Banner rose top**:
- Bg `errorBg` `#3A2421`, border-bottom 1px `errorBorder`
- Icon container 36×36, radius 12, bg `errorBorder`, X icon `errorText`
- Title 14px w700, subtitle 11px w600 `errorText`

**Reason quote card**:
- Bg `bgSurface`, border 1px `darkBorder`, radius 12, padding 12
- Quote text 11px w500 `textSecondary` line-height 1.5
- Signature divider 1px `darkDivider`
- Signature 10px w500 `textHint`

**Money safety strip**:
- Status strip pattern jade variant
- Icon info `jadeMuted`
- Title "Tiền của bạn an toàn" 11px w700
- Body 10px w500 line-height 1.45

**Need to fix list**:
- Card với 3 items
- Item rejected: icon container 24×24 bg `errorBorder`, X icon `errorText` + label + status `Cần chụp lại` (errorText) + chevron right
- Item approved: icon container bg `successBorder`, check icon `successText` + label + status `Đã duyệt` (successText)
- Tap rejected item → navigate to corresponding step (Screen 2/3 với current data preserved)

**Actions**:
- "Yêu cầu hoàn tiền" (secondary): bg `darkBorder`, text `textPrimary`
  - Tap → confirm dialog "Hoàn tiền 100%? Hồ sơ sẽ bị huỷ."
- "Bổ sung ngay" (primary): bg `jadeText`, text `darkBg`
  - Tap → navigate to first rejected step

**Edge cases**:
- Multiple rejected items → list show all, tap each navigate đúng step
- Admin reject toàn bộ → flow restart from Step 1 với option giữ payment
- Refund đã process → screen update với confirmation "Đã hoàn tiền 23.602K vào VNPay"

---

## 6. Data models & state

### 6.1 Models

```dart
// lib/features/verify/data/models/verify_state.dart
@freezed
class VerifyFlowState with _$VerifyFlowState {
  const factory VerifyFlowState({
    // KYC
    CCCDUpload? cccdFront,
    CCCDUpload? cccdBack,
    SelfieUpload? selfie,
    double? faceMatchScore,
    
    // Property info (from previous flow)
    PropertyInfo? propertyInfo,
    
    // Subscription
    Plan? selectedPlan,
    @Default(BillingCycle.yearly) BillingCycle billingCycle,
    
    // Payment
    PaymentSession? paymentSession,
    PaymentStatus? paymentStatus,
    
    // Submission
    String? submissionId,
    @Default(VerifyStatus.draft) VerifyStatus status,
    String? rejectReason,
    @Default([]) List<String> rejectedItems,  // ['cccdFront', 'selfie']
    DateTime? approvedAt,
    DateTime? trialEndsAt,
    DateTime? chargeStartsAt,
  }) = _VerifyFlowState;
}

enum VerifyStatus {
  draft,                 // owner đang fill
  kycSubmitted,          // đã upload CCCD + selfie
  paymentPending,        // chưa thanh toán
  awaitingApproval,      // payment OK, chờ admin
  approved,              // admin duyệt
  rejected,              // admin reject
  refunded,              // đã refund
}

enum BillingCycle { monthly, yearly }

@freezed
class CCCDUpload with _$CCCDUpload {
  const factory CCCDUpload({
    required String id,
    required String imageUrl,
    OCRResult? ocrResult,
    required double confidence,
    required DateTime uploadedAt,
  }) = _CCCDUpload;
}

@freezed
class OCRResult with _$OCRResult {
  const factory OCRResult({
    String? cccdNumber,
    String? fullName,
    String? dob,
    String? address,
    String? gender,
    String? expiryDate,
  }) = _OCRResult;
}

@freezed
class Plan with _$Plan {
  const factory Plan({
    required String id,
    required Tier tier,
    required int pricePerRoomPerMonth,    // VND
    required int minChargePerMonth,
    int? maxRooms,
    required List<String> features,
  }) = _Plan;
  
  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
}

enum Tier { starter, professional, enterprise }

@freezed
class PaymentSession with _$PaymentSession {
  const factory PaymentSession({
    required String sessionId,
    required PaymentMethod method,
    required int totalAmount,
    String? qrCode,           // VNPay
    String? bankInfo,         // STK + nội dung chuyển
    String? redirectUrl,      // VNPay redirect
    required DateTime expiresAt,
  }) = _PaymentSession;
}

enum PaymentMethod { vnpayQR, bankTransfer, card }
enum PaymentStatus { pending, paid, failed, expired, refunded }
```

### 6.2 Controller

```dart
// lib/features/verify/controllers/verify_flow_controller.dart
@riverpod
class VerifyFlowController extends _$VerifyFlowController {
  @override
  VerifyFlowState build() {
    // Restore from local storage if exists (resume flow)
    final saved = ref.read(localStorageProvider).getDraft();
    return saved ?? const VerifyFlowState();
  }

  // Step 2: Upload CCCD front
  Future<void> uploadCCCDFront(File image) async {
    state = state.copyWith(status: VerifyStatus.draft);
    try {
      final result = await ref.read(verifyRepositoryProvider).uploadCCCDFront(image);
      state = state.copyWith(cccdFront: result);
      _saveDraft();
    } catch (e) {
      // surface error to UI
      rethrow;
    }
  }

  // Step 3: Upload selfie + face match
  Future<void> uploadSelfie(File image) async {
    final result = await ref.read(verifyRepositoryProvider).uploadSelfie(
      image,
      cccdFrontId: state.cccdFront!.id,
    );
    
    if (result.faceMatchScore < 0.85) {
      throw FaceMismatchException(score: result.faceMatchScore);
    }
    
    state = state.copyWith(
      selfie: result,
      faceMatchScore: result.faceMatchScore,
      status: VerifyStatus.kycSubmitted,
    );
    _saveDraft();
  }

  // Step 5: Select plan
  void selectPlan(Plan plan, BillingCycle cycle) {
    state = state.copyWith(selectedPlan: plan, billingCycle: cycle);
    _saveDraft();
  }

  // Step 6: Initiate payment
  Future<PaymentSession> initiatePayment(PaymentMethod method) async {
    final session = await ref.read(verifyRepositoryProvider).initiatePayment(
      planId: state.selectedPlan!.id,
      billingCycle: state.billingCycle,
      method: method,
      rooms: state.propertyInfo!.expectedRooms,
    );
    state = state.copyWith(
      paymentSession: session,
      paymentStatus: PaymentStatus.pending,
      status: VerifyStatus.paymentPending,
    );
    _saveDraft();
    return session;
  }

  // Polling payment status
  Future<void> checkPaymentStatus() async {
    if (state.paymentSession == null) return;
    final status = await ref.read(verifyRepositoryProvider)
        .checkPaymentStatus(state.paymentSession!.sessionId);
    state = state.copyWith(paymentStatus: status);
    
    if (status == PaymentStatus.paid) {
      // Auto-submit after payment confirmed
      await submitForApproval();
    }
  }

  // Submit final
  Future<void> submitForApproval() async {
    final result = await ref.read(verifyRepositoryProvider).submitForApproval();
    state = state.copyWith(
      submissionId: result.submissionId,
      status: VerifyStatus.awaitingApproval,
    );
    _saveDraft();
  }

  // Polling approval status
  Future<void> checkApprovalStatus() async {
    if (state.submissionId == null) return;
    final result = await ref.read(verifyRepositoryProvider)
        .checkApprovalStatus(state.submissionId!);
    
    state = state.copyWith(
      status: result.status,
      approvedAt: result.approvedAt,
      trialEndsAt: result.trialEndsAt,
      chargeStartsAt: result.chargeStartsAt,
      rejectReason: result.rejectReason,
      rejectedItems: result.rejectedItems ?? [],
    );
    _saveDraft();
  }

  // Resubmit after partial reject (Screen 8)
  Future<void> resubmit() async {
    // Re-upload only rejected items
    // ...
    state = state.copyWith(
      status: VerifyStatus.awaitingApproval,
      rejectReason: null,
      rejectedItems: [],
    );
  }

  // Request refund (Screen 8)
  Future<void> requestRefund() async {
    await ref.read(verifyRepositoryProvider).requestRefund(state.submissionId!);
    state = state.copyWith(status: VerifyStatus.refunded);
    ref.read(localStorageProvider).clearDraft();
  }

  void _saveDraft() {
    ref.read(localStorageProvider).saveDraft(state);
  }
}
```

### 6.3 Polling provider for approval status

```dart
@riverpod
Stream<VerifyStatus> approvalStatusStream(ApprovalStatusStreamRef ref) async* {
  while (true) {
    await Future.delayed(const Duration(seconds: 30));
    await ref.read(verifyFlowControllerProvider.notifier).checkApprovalStatus();
    yield ref.read(verifyFlowControllerProvider).status;
  }
}
```

---

## 7. API contracts

### 7.1 KYC endpoints

```
POST /verify/cccd-front
Body: multipart/form-data { image: File }
Response 200:
{
  "id": "cccd_001",
  "imageUrl": "https://cdn.../cccd_front_001.jpg",
  "ocrResult": {
    "cccdNumber": "001192012345",
    "fullName": "NGUYỄN VĂN TUẤN",
    "dob": "1992-05-12",
    "address": "...",
    "gender": "Nam",
    "expiryDate": "2027-05-12"
  },
  "confidence": 0.94,
  "uploadedAt": "2026-04-27T14:32:00Z"
}
Response 400: { "code": "OCR_LOW_CONFIDENCE", "message": "..." }

POST /verify/cccd-back
Same structure as cccd-front

POST /verify/selfie
Body: multipart/form-data { image: File, cccdFrontId: string }
Response 200:
{
  "id": "selfie_001",
  "imageUrl": "https://cdn.../selfie_001.jpg",
  "faceMatchScore": 0.92,
  "isValid": true
}
Response 400: { "code": "FACE_MISMATCH", "score": 0.65 }
```

### 7.2 Subscription endpoints

```
GET /plans
Response:
{
  "plans": [
    {
      "id": "plan_starter",
      "tier": "starter",
      "pricePerRoomPerMonth": 199000,
      "minChargePerMonth": 1999000,
      "maxRooms": 20,
      "features": ["booking", "calendar", "checkin", "basic_report"]
    },
    ...
  ]
}

POST /payment/init
Body:
{
  "planId": "plan_pro",
  "billingCycle": "yearly",
  "paymentMethod": "vnpayQR",
  "rooms": 15
}
Response:
{
  "sessionId": "pay_session_001",
  "method": "vnpayQR",
  "totalAmount": 23602000,
  "qrCode": "data:image/png;base64,...",
  "expiresAt": "2026-04-27T14:50:00Z"
}

GET /payment/:sessionId/status
Response:
{
  "status": "paid",  // pending | paid | failed | expired
  "paidAt": "2026-04-27T14:35:00Z"
}

POST /payment/webhook
(VNPay callback, server-side only, không gọi từ app)

POST /verify/submit
(Submit toàn bộ hồ sơ cho admin duyệt)
Response:
{
  "submissionId": "sub_001",
  "status": "awaitingApproval",
  "submittedAt": "2026-04-27T14:36:00Z"
}

GET /verify/submissions/:submissionId
Response:
{
  "submissionId": "sub_001",
  "status": "approved",  // awaitingApproval | approved | rejected
  "approvedAt": "2026-04-28T09:15:00Z",
  "trialEndsAt": "2026-05-05T09:15:00Z",
  "chargeStartsAt": "2026-05-05T09:15:00Z",
  "rejectReason": null,
  "rejectedItems": []
}

POST /verify/submissions/:submissionId/resubmit
(Bổ sung sau khi bị reject)
Body: { items: ['cccdFront'] }  // chỉ items bị reject

POST /verify/submissions/:submissionId/refund
(Yêu cầu hoàn tiền)
Response: { refundedAt, refundAmount }
```

### 7.3 Admin endpoints (Phase tiếp theo, không trong spec này)

```
GET /admin/approvals/queue
GET /admin/approvals/:submissionId
POST /admin/approvals/:submissionId/approve
POST /admin/approvals/:submissionId/reject  body: { reason, rejectedItems[] }
```

---

## 8. File structure

```
lib/
├── features/
│   └── verify/
│       ├── controllers/
│       │   └── verify_flow_controller.dart
│       ├── data/
│       │   ├── models/
│       │   │   ├── verify_state.dart
│       │   │   ├── cccd_upload.dart
│       │   │   ├── selfie_upload.dart
│       │   │   ├── plan.dart
│       │   │   ├── payment_session.dart
│       │   │   └── ocr_result.dart
│       │   └── repositories/
│       │       ├── verify_repository.dart           (abstract)
│       │       └── verify_repository_impl.dart      (Dio impl)
│       └── views/
│           ├── paywall_modal.dart                   (Screen 1)
│           ├── verify_intro_screen.dart             (Screen 2 entry, optional)
│           ├── cccd_capture_screen.dart             (Screen 2)
│           ├── selfie_capture_screen.dart           (Screen 3)
│           ├── select_plan_screen.dart              (Screen 4)
│           ├── payment_screen.dart                  (Screen 5)
│           ├── pending_approval_screen.dart         (Screen 6)
│           ├── trial_active_screen.dart             (Screen 7)
│           ├── rejected_screen.dart                 (Screen 8)
│           └── widgets/
│               ├── stepper_progress.dart
│               ├── camera_frame_overlay.dart
│               ├── plan_card.dart
│               ├── order_summary_card.dart
│               ├── payment_method_tile.dart
│               ├── status_timeline.dart             (cho Screen 6)
│               └── verify_skeleton.dart
└── shared/
    └── widgets/
        ├── badges/
        │   ├── premium_ribbon.dart                  (đã có)
        │   ├── hot_badge.dart                       (đã có)
        │   └── plan_badge.dart                      (NEW — "PHỔ BIẾN NHẤT")
        └── status_strip.dart                        (đã có)
```

---

## 9. Edge cases

| # | Scenario | Behavior |
|---|---|---|
| 1 | OCR confidence < 0.8 (Screen 2) | Toast warning + cho retry, max 3 lần thì cho phép nhập tay |
| 2 | Camera permission denied | Screen alternative với 2 options: cấp quyền hoặc upload ảnh sẵn |
| 3 | File ảnh > 10MB | Compress trước upload, fail thì error toast |
| 4 | Face match < 0.85 (Screen 3) | Alert "Khuôn mặt không khớp", retry; 3 lần fail → lock 1h + email admin |
| 5 | User cancel mid-flow | Save draft local, resume khi quay lại app |
| 6 | Payment timeout (15 phút VNPay) | Cho regenerate QR, max 3 lần thì verify identity lại |
| 7 | Network offline khi polling | Silent retry với exponential backoff |
| 8 | Admin chưa duyệt sau 24h | Banner escalation + button "Liên hệ urgent" |
| 9 | Admin reject một phần | Screen 8 hiện checklist, owner chỉ cần fix item bị reject |
| 10 | Admin reject toàn bộ | Screen 8 với option giữ payment hoặc refund 100% |
| 11 | App killed trong lúc chờ duyệt | Resume polling khi mở lại, push notification từ FCM |
| 12 | Trial countdown đến 1h cuối | Push notification + banner warning vàng trong app |
| 13 | Trial hết hạn chưa pay | Auto-charge từ method đã save, fail → notify owner downgrade hoặc cancel |
| 14 | Refund đã process | Screen 8 thay button "Yêu cầu hoàn tiền" thành confirmation "Đã hoàn 23.602K vào VNPay" |
| 15 | Free Owner click action lock thứ 2 (sau khi đã start verify rồi cancel) | Paywall modal hiện note "Tiếp tục từ bước X?" + button "Tiếp tục" |

---

## 10. Testing checklist

### 10.1 Unit tests

- [ ] `VerifyFlowController.uploadCCCDFront` happy path → state.cccdFront updated
- [ ] `VerifyFlowController.uploadCCCDFront` low confidence → warning state
- [ ] `VerifyFlowController.uploadSelfie` face match < 0.85 → throw FaceMismatchException
- [ ] `VerifyFlowController.selectPlan` → state.selectedPlan + billingCycle updated
- [ ] `VerifyFlowController.initiatePayment` → state.paymentSession set
- [ ] `VerifyFlowController.checkPaymentStatus` paid → auto submitForApproval
- [ ] `VerifyFlowController.submitForApproval` → state.status = awaitingApproval
- [ ] `VerifyFlowController.checkApprovalStatus` approved → state updated với trialEndsAt
- [ ] `VerifyFlowController.checkApprovalStatus` rejected → state.rejectReason + rejectedItems
- [ ] `calculatePrice` cho mỗi tier × cycle × số phòng → đúng formula
- [ ] `suggestTier` cho mỗi room count range → đúng tier
- [ ] Save/restore draft từ local storage

### 10.2 Widget tests

- [ ] `PaywallModal` renders với 4 steps preview
- [ ] `PaywallModal` tap "Bắt đầu ngay" → callback navigate
- [ ] `PaywallModal` swipe down → close
- [ ] `CCCDCaptureScreen` stepper progress 1/4 active
- [ ] `CCCDCaptureScreen` tap "Mở camera" → open camera
- [ ] `SelfieCaptureScreen` shows CCCD verified card top
- [ ] `SelectPlanScreen` toggle Monthly/Yearly → recalculate prices
- [ ] `SelectPlanScreen` Professional card highlighted khi rooms = 15
- [ ] `SelectPlanScreen` tap plan → CTA text update
- [ ] `PaymentScreen` order summary breakdown đúng calculation
- [ ] `PaymentScreen` select method → CTA enabled với amount
- [ ] `PendingApprovalScreen` status timeline 4 steps render đúng status
- [ ] `PendingApprovalScreen` countdown to 24h
- [ ] `TrialActiveScreen` countdown trial X ngày Yh
- [ ] `RejectedScreen` checklist rejected items
- [ ] `RejectedScreen` tap rejected item → navigate đúng step

### 10.3 Golden tests (visual regression)

- [ ] `paywall_modal_dark.png`
- [ ] `cccd_capture_dark.png`
- [ ] `selfie_capture_dark.png`
- [ ] `select_plan_dark.png` (3 plans visible, Pro highlighted)
- [ ] `payment_screen_dark.png` (VNPay selected)
- [ ] `pending_approval_dark.png` (timeline 3 done, 1 current)
- [ ] `trial_active_dark.png`
- [ ] `rejected_dark.png` (1 reject, 2 approved)

### 10.4 Integration tests

- [ ] Full happy path: Free Owner click "Đăng phòng" → paywall → CCCD → selfie → property → plan → pay → pending → approved → trial active
- [ ] Reject path: ... → pending → rejected → fix → resubmit → approved
- [ ] Refund path: rejected → request refund → confirmation
- [ ] Cancel mid-flow → resume from saved state

### 10.5 Manual QA checklist

- [ ] Flow chạy được trên iPhone 13/15, Pixel 8, Galaxy A53
- [ ] Camera permission flow đúng cả iOS + Android
- [ ] OCR thật (không mock) accuracy ≥ 80% với CCCD VN chuẩn
- [ ] Face match thật accuracy ≥ 90%
- [ ] VNPay QR scan được bằng app ngân hàng thật
- [ ] Payment webhook nhận đúng từ VNPay sandbox
- [ ] Push notification khi admin duyệt/reject
- [ ] Email notification khi approved
- [ ] Dark mode work tốt, không glow excessive
- [ ] Accessibility: VoiceOver/TalkBack đọc đúng order

### 10.6 Contrast verification

| Pair | Ratio | Pass |
|---|---|---|
| `textPrimary #D6DDE0` / `darkBg #16252B` | 11.2 | AAA |
| `textSecondary #A8B0B4` / `darkSurface #1E343A` | 6.8 | AAA |
| `textTertiary #8FB0B8` / `darkSurface` | 5.4 | AA |
| `jadeText #B5D4DA` / `darkBg` | 9.5 | AAA |
| `jadeMuted #7AB5BD` / `darkBg` | 6.4 | AAA |
| `darkBg #16252B` / `jadeText #B5D4DA` (button) | 9.5 | AAA |
| `goldText #C9A567` / `goldBg #383021` | 5.2 | AA |
| `successText #6FA88B` / `successBg #1F3A2D` | 4.8 | AA |
| `errorText #C97A6F` / `errorBg #3A2421` | 5.1 | AA |

---

## 11. Definition of Done

PR merge khi tất cả ✓:

- [ ] Code review approved bởi 1 senior dev
- [ ] CI pipeline pass (analyze, test, build APK + IPA)
- [ ] Unit + widget test coverage ≥ 75% cho `features/verify/`
- [ ] All 8 golden tests pass
- [ ] Manual QA pass trên 2 devices (iOS + Android)
- [ ] Screenshots dark mode 8 screens đính kèm trong PR
- [ ] Demo video flow happy path (60s)
- [ ] Demo video flow reject + resubmit (45s)
- [ ] Performance: Flutter DevTools timeline không jank > 16ms
- [ ] No new analyzer warnings
- [ ] Accessibility audit pass
- [ ] Contrast ratio verified với WebAIM checker
- [ ] Updated documentation:
  - [ ] README mention verify flow
  - [ ] CHANGELOG entry
  - [ ] API endpoint list trong `docs/api.md`

---

## 12. Migration notes

### 12.1 Breaking changes từ design system v2 cũ

Palette dark mode thay đổi đáng kể:

| v2 cũ token | v2 calm operations | Action |
|---|---|---|
| `darkBg #0A1F26` | `darkBg #16252B` | Update value |
| `darkSurface #0F2F38` | `darkSurface #1E343A` | Update value |
| `darkBorder #1B5664` | `darkBorder #2A4147` | Update value |
| `darkTextPrimary #E6F4F7` | `textPrimary #D6DDE0` | Update value, rename |
| `jadeBright #5BCEDC` | `jadeMuted #7AB5BD` | Update + rename |
| `goldBright #F4CD7A` | `goldText #C9A567` | Update + rename |
| `coralBright #F7AB94` | `coralText #C9A084` | Update + rename |
| `successDark #4ADE80` | `successText #6FA88B` | Update value |
| `warningDark #FBBF24` | `warningText #C9A567` | Update + value |
| `errorDark #F87171` | `errorText #C97A6F` | Update value |

### 12.2 Component refresh cần làm

- [ ] Bỏ glow shadow ở mọi icon container (giữ chỉ FAB + active state)
- [ ] Bỏ decorative blobs/stars trong gradient cards (manager screens)
- [ ] Status pill: chuyển từ `borderRadius: 100` sang `borderRadius: 4-6`
- [ ] Heading weight: w800 → w700 (giữ w800 chỉ cho titleLarge)
- [ ] Button primary: dùng `jadeText #B5D4DA` (light) làm bg + `darkBg` text, không phải `jadeMuted`
- [ ] Border decorative: chỉ dùng cho "popular" card và rejected card

### 12.3 Customer Home (đã làm trước) — có cần redo không?

Customer Home dark mode v1 có vibe "biển đêm" với stars + blobs + glows. **Giữ nguyên** vì:
- Customer mở app 5-10 phút để đặt phòng, không bị mỏi mắt
- Vibe thơ mộng phù hợp customer cảm xúc
- Manager cần calm, customer cần engaging — 2 use case khác

Apple cũng làm thế: App Store vibe khác Xcode vibe.

### 12.4 Workload estimate

| Task | Time |
|---|---|
| Update `app_colors.dart` calm operations | 1h |
| Update `AppColorScheme.dark()` | 1h |
| Update components shared (status strip, plan badge, etc.) | 4h |
| Build 8 screens verify flow | 4 ngày |
| Build controllers + repository | 1 ngày |
| Write tests | 1.5 ngày |
| Manual QA + polish | 1 ngày |
| **Tổng** | **~7-8 ngày** |

---

## Phụ lục — Q&A thường gặp

**Q: Nếu owner đã từng start verify rồi cancel, lần sau click "Đăng phòng" có hiện paywall không?**
A: Có, nhưng paywall sẽ detect saved draft và hiện note "Tiếp tục từ bước X?" với button "Tiếp tục" thay "Bắt đầu ngay". Logic trong `VerifyFlowController.build()`.

**Q: Sale có cần verify CCCD không?**
A: Không. Sale được Owner invite qua email + set password. Chỉ Owner verify CCCD vì Owner chịu trách nhiệm pháp lý.

**Q: Trial 7 ngày có thể skip để start charging luôn không?**
A: Không. Trial là default benefit. Owner chỉ có thể cancel trial → cancel subscription, không có option skip.

**Q: Sau khi trial hết, charge tự động hay manual?**
A: Auto-charge từ payment method đã save (VNPay token / card token). Nếu fail → notify owner trong 7 ngày, fail tiếp → cancel subscription, account về free mode.

**Q: VNPay sandbox setup thế nào?**
A: Liên hệ VNPay developer portal để có credentials sandbox. Mock layer trong `VerifyRepository` cho dev test mà không cần payment thật.

**Q: Face match dùng service nào?**
A: Recommend AWS Rekognition hoặc FPT.AI face match API (VN provider, accuracy tốt với khuôn mặt VN). Confirm với backend team.

**Q: OCR CCCD dùng service nào?**
A: FPT.AI eKYC hoặc VNPT eKYC (best for CCCD VN). Cấu hình trong backend, app chỉ gọi `POST /verify/cccd-front`.

---

**Phiên bản**: 1.0
**Ngày**: 27/04/2026
**Sprint deadline**: 7-10 ngày
**Reviewer**: Senior Dev + Designer + Backend Lead
**Companion docs**:
- `halong24h-color-system-v2.md` (color tokens)
- `halong24h-component-specs-v2.md` (components)
- `halong24h-ai-prompt-templates.md` (AI prompts cho dev)
