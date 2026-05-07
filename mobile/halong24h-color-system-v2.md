# Halong24h — Color System v2.0 Migration Report

> Báo cáo refactor color palette từ v1 (Generic Ocean) → v2 (Jade Bay).
> Phạm vi: **chỉ color + dark/light theme**, không động đến typography/spacing/animation (giữ nguyên brief v1).
> Mục tiêu: dev đọc xong refactor được trong 1-2 ngày.
>
> Ngày: 27/04/2026
> Phiên bản: 2.0 (kế thừa design brief v1.0)
> Áp dụng cho: Flutter 3.x, Material 3, Riverpod 2.6+

---

## Mục lục

1. [Tổng quan thay đổi](#1-tổng-quan-thay-đổi)
2. [Diagnosis vấn đề palette v1](#2-diagnosis--vấn-đề-palette-v1)
3. [Palette v2 — Jade Bay](#3-palette-v2--jade-bay)
4. [Component color map (Light + Dark)](#4-component-color-map)
5. [Migration mapping v1 → v2](#5-migration-mapping-v1--v2)
6. [Flutter implementation](#6-flutter-implementation)
7. [Migration checklist](#7-migration-checklist)
8. [QA checklist trước merge](#8-qa-checklist-trước-merge)

---

## 1. Tổng quan thay đổi

### 1.1 Có gì đổi

| Loại | Số token đổi | Action |
|---|---|---|
| Brand primary (Ocean → Jade) | 5 token | Đổi hex value, giữ tên semantic |
| Brand secondary (Gold) | 1 token chính | Đổi hex value |
| **Accent mới (Coral)** | 5 token | **Thêm mới** |
| **Neutral warm (Limestone)** | 2 token | **Thêm mới (option)** |
| Dark scheme | 9 token | Đổi sang Deep Jade base |
| Semantic | 4 token | Tinh chỉnh cho rõ contrast |
| Status (booking, room) | 4 token | Tinh chỉnh dark variant |

### 1.2 Có gì KHÔNG đổi

- Slate scale cho text (giữ nguyên `#0F172A` → `#94A3B8`)
- Typography (Nunito, weight scale, size)
- Spacing scale (`AppSpacing`)
- Border radius scale (`AppRadius`)
- Animation tokens
- Component pattern mặc định (3.1 → 3.18 trong brief v1)

### 1.3 Workload estimate

| Task | Time |
|---|---|
| Update `app_colors.dart` (theo template phần 6) | 2 giờ |
| Update `app_theme.dart` (light + dark ThemeData) | 2-3 giờ |
| Audit hardcoded `Color(0xFF...)` trong code → thay bằng token | 4-6 giờ |
| Visual QA toàn app light + dark | 2-3 giờ |
| **Tổng** | **~1.5 ngày dev** |

---

## 2. Diagnosis — vấn đề palette v1

### 2.1 Ocean primary `#0A4F6E` quá "corporate"

HSL analysis: hue 199°, saturation 84%, lightness 24%.

- Hue 199° là **blue-cyan corporate** (Booking.com `#003580`, IBM `#0F62FE`), không phải Hạ Long
- Nước biển Hạ Long thực tế thiên về **jade-teal** (hue ~188-192°) vì khoáng đá vôi tạo tone xanh ngọc
- Saturation 84% quá rực — mệt mắt khi nhìn lâu trên screen lớn

→ **Đề xuất**: shift sang `#0F5A6B` (hue 188°, sat 75%, light 24%). Vẫn deep & trusted, nhưng có tone "Hạ Long" rõ ràng.

### 2.2 Gold `#C9A84C` bị "đục"

HSL: hue 44°, sat 53%, light 54%. Saturation quá thấp → ra màu vàng nâu olive, giống "vintage brass" hơn là "premium hospitality gold".

So sánh với industry leaders:
- Hilton gold: `#D4AF37` (sat 60%)
- Marriott gold: `#E5C77F` (sat 67%)
- Four Seasons: `#C09F65` (sat 35% nhưng có warm pink undertone)

→ **Đề xuất**: `#E5B547` (hue 43°, sat 76%, light 59%). Sáng, luminous, không bị "công sở bao da".

### 2.3 Thiếu warm accent

Toàn palette v1 là cool tone (ocean blue + slate grey + gold lạnh). Thiếu **emotional warmth** — đặc trưng quan trọng của hospitality app:

- Airbnb: coral `#FF5A5F` làm app cảm giác "đón tiếp"
- Marriott: deep red làm CTA nổi
- Halong24h hiện tại: 100% cool → cảm giác "ngân hàng" hơn "khách sạn nghỉ dưỡng"

→ **Đề xuất**: thêm **Sunrise Coral** `#F2856B` làm accent thứ 3. Dùng cho:
- Badge "Hot", "Mới", "Phổ biến"
- Heart icon (wishlist)
- Notification urgent
- Empty state illustration accent
- KHÔNG dùng làm primary CTA (giữ jade cho action chính)

### 2.4 Dark scheme v1 lệch khỏi brand

Dark scheme hiện tại là **slate-base** (`#1A2232` → `#364D65`), trong khi light là **jade-base**. Hai theme không đồng nhất visual identity. Khi user chuyển dark mode, app cảm giác như "ứng dụng khác".

→ **Đề xuất**: dark scheme dùng **deep jade base** (`#0A1F26` → `#1B5664`), giữ cảm giác "Hạ Long về đêm" — vẫn là biển, chỉ tối hơn.

---

## 3. Palette v2 — Jade Bay

### 3.1 Brand colors (không đổi giữa light/dark — đây là token brand identity)

#### Jade (Primary)

| Token | Hex | HSL | Khi dùng |
|---|---|---|---|
| `jade50` | `#E6F4F5` | 188°, 26%, 93% | Subtle bg, hover state |
| `jade100` | `#C9E5E8` | 188°, 30%, 85% | Pill bg, chip bg light |
| `jade200` | `#A6D2D8` | 187°, 32%, 75% | Disabled state, divider colored |
| `jade300` | `#5BA8B5` | 188°, 33%, 53% | **Light variant on dark mode**, accent |
| `jade500` | `#0F5A6B` | 188°, 75%, 24% | **MAIN brand color** |
| `jade700` | `#0A3F4B` | 191°, 76%, 17% | Dark variant, text on light |
| `jade900` | `#052830` | 195°, 78%, 11% | Deepest, dark mode bg |

#### Gold (Secondary — Premium accent)

| Token | Hex | HSL | Khi dùng |
|---|---|---|---|
| `gold50` | `#FEF9E8` | 49°, 92%, 95% | Subtle bg, badge bg |
| `gold100` | `#FCEFC4` | 47°, 88%, 88% | Card highlight |
| `gold300` | `#F4CD7A` | 41°, 85%, 72% | **Light variant on dark mode** |
| `gold500` | `#E5B547` | 43°, 76%, 59% | **MAIN accent** |
| `gold700` | `#A8821F` | 44°, 68%, 39% | Dark variant, text |
| `gold900` | `#5C4500` | 45°, 100%, 18% | Deepest |

#### Coral (Accent — NEW)

| Token | Hex | HSL | Khi dùng |
|---|---|---|---|
| `coral50` | `#FFEFE8` | 17°, 100%, 95% | Subtle bg |
| `coral100` | `#FED4C4` | 17°, 96%, 88% | Pill bg |
| `coral300` | `#F7AB94` | 13°, 86%, 78% | **Light variant on dark mode** |
| `coral500` | `#F2856B` | 11°, 83%, 68% | **MAIN warm accent** |
| `coral700` | `#B85A3F` | 13°, 49%, 49% | Dark variant, text |
| `coral900` | `#6B2B17` | 15°, 64%, 25% | Deepest |

### 3.2 Neutral & Background

#### Slate (text & UI structure — giữ nguyên từ v1)

| Token | Hex | Khi dùng |
|---|---|---|
| `slate50` | `#F8FAFC` | Default scaffold bg light |
| `slate100` | `#F1F5F9` | Surface variant, hover |
| `slate200` | `#E2E8F0` | **Border default** |
| `slate300` | `#CBD5E1` | Divider strong, disabled |
| `slate400` | `#94A3B8` | Slate text (deemphasized) |
| `slate500` | `#64748B` | **Muted text** |
| `slate600` | `#475569` | Body text strong |
| `slate700` | `#334155` | **Ink — heading** |
| `slate800` | `#1E293B` | Ink darker |
| `slate900` | `#0F172A` | **Navy — strongest text** |

#### Limestone (warm bg option — NEW)

Khi muốn screen có cảm giác "ấm cúng" hơn (Property Detail customer, Welcome screen), dùng limestone thay slate50:

| Token | Hex | Khi dùng |
|---|---|---|
| `limestone50` | `#FAF7F0` | Warm scaffold (alternative bg) |
| `limestone100` | `#F5EFE3` | Warm surface variant |

#### Dark mode neutral (Deep Jade base — REPLACE v1)

| Token v1 (cũ) | Hex v1 | Token v2 (mới) | Hex v2 | Note |
|---|---|---|---|---|
| `darkBackground` | `#1A2232` | `darkBg` | `#0A1F26` | Sâu hơn, tone jade |
| `darkSurface` | `#212C3F` | `darkSurface` | `#0F2F38` | Deep teal |
| `darkContainer` | `#283448` | `darkContainer` | `#143E48` | Input/elevated bg |
| `darkElevated` | `#2F3E54` | `darkElevated` | `#1A4D58` | Modal/dialog |
| `darkBorder` | `#364D65` | `darkBorder` | `#1B5664` | Border default |
| `darkDivider` | `#2A3A4F` | `darkDivider` | `#143E48` | Divider subtle |
| `darkHint` | `#8FA8BC` | `darkHint` | `#8FB8C2` | Hint text |
| `darkSubtext` | `#7090AA` | `darkSubtext` | `#6F9AA5` | Secondary text |
| `darkTextPrimary` | `#E6F0F8` | `darkTextPrimary` | `#E6F4F7` | Primary text |

#### Bright accents on dark (REPLACE)

| Token v1 | Hex v1 | Token v2 | Hex v2 |
|---|---|---|---|
| `oceanBright` | `#48C9F0` | `jadeBright` | `#5BCEDC` |
| `goldBright` | `#D4AE5C` | `goldBright` | `#F4CD7A` |
| `tealBright` | `#26D9C8` | (xoá, không dùng) | — |
| (mới) | — | `coralBright` | `#F7AB94` |

### 3.3 Text colors

| Token | Light | Dark | Khi dùng |
|---|---|---|---|
| `text.primary` | `#0F172A` (slate900) | `#E6F4F7` (darkTextPrimary) | Heading, label chính |
| `text.secondary` | `#475569` (slate600) | `#B5C9D0` | Body text |
| `text.tertiary` | `#64748B` (slate500) | `#8FB8C2` (darkHint) | Muted, meta |
| `text.disabled` | `#94A3B8` (slate400) | `#6F9AA5` (darkSubtext) | Disabled |
| `text.brand` | `#0F5A6B` (jade500) | `#5BCEDC` (jadeBright) | AppBar title, link |
| `text.brandAccent` | `#A8821F` (gold700) | `#F4CD7A` (goldBright) | Premium label |
| `text.brandWarm` | `#B85A3F` (coral700) | `#F7AB94` (coralBright) | Hot/urgent label |
| `text.onPrimary` | `#FFFFFF` | `#052830` (jade900) | Text trên nền jade500 |
| `text.onSecondary` | `#FFFFFF` | `#5C4500` (gold900) | Text trên nền gold500 |
| `text.onCoral` | `#FFFFFF` | `#6B2B17` (coral900) | Text trên nền coral500 |

> **Lưu ý dark mode**: text trên nền brand color (`onPrimary`, `onSecondary`) dùng màu **đậm của ramp** thay vì trắng. Lý do: khi dark mode, brand color (jade300, gold300, coral300) đã sáng → text đen tương phản tốt hơn trắng.

### 3.4 Border colors

| Token | Light | Dark | Khi dùng |
|---|---|---|---|
| `border.subtle` | `#F1F5F9` (slate100) | `#143E48` (darkDivider) | Item separator trong card |
| `border.default` | `#E2E8F0` (slate200) | `#1B5664` (darkBorder) | Border card, input |
| `border.strong` | `#CBD5E1` (slate300) | `#2A6F80` | Button outlined |
| `border.brand` | `#0F5A6B` (jade500) | `#5BCEDC` (jadeBright) | Focus state, button outlined primary |
| `border.gold` | `#E5B547` (gold500) | `#F4CD7A` (goldBright) | Premium card outlined |
| `border.coral` | `#F2856B` (coral500) | `#F7AB94` (coralBright) | Hot/featured card outlined |
| `border.dashed` | `#CBD5E1` (slate300) | `#3A6F80` | Empty cell, scan area |

### 3.5 Semantic colors (REFINED — cleaner contrast)

#### Success (Emerald)

| | Light | Dark |
|---|---|---|
| `main` | `#16A34A` | `#4ADE80` |
| `bg` | `#DCFCE7` | `rgba(74,222,128, 0.16)` |
| `border` | `rgba(22,163,74, 0.25)` | `rgba(74,222,128, 0.35)` |

> v1 dùng `#22C55E` — quá rực ở light mode. v2 chuyển sang `#16A34A` (deeper emerald), readable hơn.

#### Warning (Amber)

| | Light | Dark |
|---|---|---|
| `main` | `#EAB308` | `#FBBF24` |
| `bg` | `#FEF9C3` | `rgba(251,191,36, 0.16)` |
| `border` | `rgba(234,179,8, 0.25)` | `rgba(251,191,36, 0.35)` |

> v1 dùng `#F59E0B` (orange-amber). v2 dùng `#EAB308` (cleaner yellow-amber) — phân biệt rõ hơn với coral và gold.

#### Error (Coral red)

| | Light | Dark |
|---|---|---|
| `main` | `#DC2626` | `#F87171` |
| `bg` | `#FEE2E2` | `rgba(248,113,113, 0.16)` |
| `border` | `rgba(220,38,38, 0.25)` | `rgba(248,113,113, 0.35)` |

#### Info (Jade — same as primary)

| | Light | Dark |
|---|---|---|
| `main` | `#0F5A6B` (jade500) | `#5BCEDC` (jadeBright) |
| `bg` | `#E6F4F5` (jade50) | `rgba(91,206,220, 0.16)` |
| `border` | `rgba(15,90,107, 0.25)` | `rgba(91,206,220, 0.35)` |

### 3.6 Status colors

#### Booking status (5 trạng thái)

| Status | Light main | Light bg | Dark main | Dark bg |
|---|---|---|---|---|
| `hold` (Đang giữ) | `#F59E0B` | `#FEF3C7` | `#FBBF24` | `rgba(251,191,36, 0.16)` |
| `confirmed` (Đã xác nhận) | `#22C55E` | `#DCFCE7` | `#4ADE80` | `rgba(74,222,128, 0.16)` |
| `cancelled` (Đã huỷ) | `#EF4444` | `#FEE2E2` | `#F87171` | `rgba(248,113,113, 0.16)` |
| `completed` (Đã hoàn tất) | `#7B1FA2` | `#F3E8FF` | `#C084FC` | `rgba(192,132,252, 0.16)` |
| `pending` (Chờ xác nhận) | `#0F5A6B` | `#E6F4F5` | `#5BCEDC` | `rgba(91,206,220, 0.16)` |

> **Pill pattern**: bg = light bg, text = main color, font-weight 700-800, radius full. Không dùng border.

#### Room status (4 trạng thái calendar grid)

| Status | Light bg | Light dot | Dark bg | Dark dot |
|---|---|---|---|---|
| `vacant` (Còn trống) | `#DCFCE7` | `#16A34A` | `rgba(74,222,128, 0.18)` | `#4ADE80` |
| `booked` (Đã đặt) | `#FEF3C7` | `#F59E0B` | `rgba(251,191,36, 0.18)` | `#FBBF24` |
| `occupied` (Đang ở) | `#E6F4F5` | `#0F5A6B` | `rgba(91,206,220, 0.18)` | `#5BCEDC` |
| `maintenance` (Bảo trì) | `#F1F5F9` | `#94A3B8` | `rgba(148,163,184, 0.18)` | `#94A3B8` (+ slash pattern) |

### 3.7 Gradient & special

#### Hero gradient (header card, splash)

| | Light | Dark |
|---|---|---|
| `gradient.brandHero` | `linear-gradient(135deg, #0F5A6B 0%, #1B7E94 100%)` | `linear-gradient(135deg, #0A1F26 0%, #1B5664 100%)` |
| `gradient.brandHeroDeep` | `linear-gradient(135deg, #052830 0%, #0F5A6B 50%, #1B7E94 100%)` | giữ nguyên |
| `gradient.premium` | `linear-gradient(135deg, #E5B547 0%, #F4CD7A 100%)` | giữ nguyên |
| `gradient.warm` | `linear-gradient(135deg, #F2856B 0%, #F7AB94 100%)` | giữ nguyên |
| `gradient.subtle` | `linear-gradient(180deg, #E6F4F5 0%, transparent 100%)` | `linear-gradient(180deg, rgba(91,206,220, 0.12) 0%, transparent 100%)` |

#### Decorative blobs (đặt absolute trong gradient cards)

| Token | Value (light + dark giống nhau) |
|---|---|
| `blob.white` | `rgba(255,255,255, 0.06)` |
| `blob.gold` | `rgba(229,181,71, 0.16)` |
| `blob.coral` | `rgba(242,133,107, 0.14)` |

#### Overlay

| Token | Light | Dark |
|---|---|---|
| `overlay.scrim` | `rgba(15,23,42, 0.50)` | `rgba(0,0,0, 0.65)` |
| `overlay.imageGradient` | `linear-gradient(180deg, transparent 0%, rgba(0,0,0,0.40) 100%)` | giữ nguyên |
| `overlay.skeletonShimmer` | `linear-gradient(90deg, #E2E8F0 0%, #F1F5F9 50%, #E2E8F0 100%)` | `linear-gradient(90deg, #143E48 0%, #1A4D58 50%, #143E48 100%)` |

---

## 4. Component color map

> Mỗi component có table light + dark với hex chính xác. Đây là phần dev tra cứu khi refactor.

### 4.1 Status bar

| | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` (match AppBar) | `#0A1F26` (darkBg) |
| Foreground (giờ, icon) | `#0F172A` (slate900) | `#E6F4F7` |
| **Trong screen có hero gradient** | `#0F5A6B` (jade500) | `#0A1F26` |
| **Foreground khi immersive** | `#FFFFFF` | `#FFFFFF` |

### 4.2 AppBar

#### AppBar mặc định (Manager Dashboard, Settings, Profile)

| Element | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#0F2F38` (darkSurface) |
| Title text | `#0F5A6B` (jade500) | `#5BCEDC` (jadeBright) |
| Title font | Nunito w700, size 20 | giữ nguyên |
| Icon button bg | `rgba(15,90,107, 0.08)` | `rgba(91,206,220, 0.15)` |
| Icon color | `#0F5A6B` | `#5BCEDC` |
| Border bottom (1px khi scroll) | `#E2E8F0` (slate200) | `#1B5664` (darkBorder) |
| User avatar bg | `#0F5A6B` | `#5BCEDC` |
| User avatar text | `#FFFFFF` | `#052830` |
| Notification dot | `#F2856B` (coral500) | `#F7AB94` |

#### AppBar gradient (Customer Home, Manager Dashboard, Greeting Header)

| Element | Light | Dark |
|---|---|---|
| Background | gradient `#0F5A6B → #1B7E94` | gradient `#0A1F26 → #1B5664` |
| Greeting text | `rgba(255,255,255, 0.85)` | giữ nguyên |
| Name text | `#FFFFFF` w800 size 22 | giữ nguyên |
| Notification icon button bg | `rgba(255,255,255, 0.18)` | giữ nguyên |
| Badge dot (unread) | `#F2856B` (coral) | giữ nguyên |
| User avatar bg | `#FFFFFF` | `#FFFFFF` |
| User avatar text | `#0F5A6B` | `#0F5A6B` |
| Bottom corners radius | `28px` | giữ nguyên |

### 4.3 Bottom Navigation

| Element | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#0F2F38` (darkSurface) |
| Top corner radius | `24px` | giữ nguyên |
| Top shadow | `0 -4px 18px rgba(15,23,42, 0.04)` | `0 -4px 18px rgba(0,0,0, 0.4)` |
| Active tab bg pill | `rgba(15,90,107, 0.12)` | `rgba(91,206,220, 0.18)` |
| Active icon color | `#0F5A6B` | `#5BCEDC` |
| Active text | `#0F5A6B` w700 | `#5BCEDC` |
| Inactive icon | `#64748B` (slate500) | `#8FB8C2` |
| Inactive text | `#64748B` w500 | `#8FB8C2` |
| Center FAB bg | gradient `#1B7E94 → #0F5A6B` | gradient `#1B7E94 → #0F5A6B` (giữ nguyên — gradient nổi cả 2 mode) |
| Center FAB icon | `#FFFFFF` | `#FFFFFF` |
| Center FAB shadow | `0 6px 16px rgba(15,90,107, 0.40)` | `0 6px 16px rgba(0,0,0, 0.50)` |
| Center FAB ring border | `4px #FFFFFF` | `4px #0F2F38` |

### 4.4 Cards

#### Card mặc định (info container, list item)

| Element | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#0F2F38` (darkSurface) |
| Border (1px) | `#E2E8F0` | `transparent` (rely on elevation) |
| Border alt (khi cần outline rõ) | `#E2E8F0` | `#1B5664` |
| Radius | `16px` (lg) | giữ nguyên |
| Padding | `16px` (md) | giữ nguyên |
| Shadow | `none` (border thay shadow) | `0 2px 8px rgba(0,0,0, 0.20)` |
| Title (size 14-16, w800) | `#0F172A` (slate900) | `#E6F4F7` |
| Subtitle (size 11-12, w600) | `#64748B` (slate500) | `#8FB8C2` |
| Item separator | `#F1F5F9` (slate100) | `#143E48` |
| Action link | `#0F5A6B` | `#5BCEDC` |

#### Card hero gradient (greeting, dashboard hero)

| Element | Light | Dark |
|---|---|---|
| Background | `linear-gradient(135deg, #0F5A6B 0%, #1B7E94 100%)` | `linear-gradient(135deg, #0A1F26 0%, #1B5664 100%)` |
| Radius | `20-24px` (xl) | giữ nguyên |
| Shadow | `0 6px 18px rgba(15,90,107, 0.22)` | `0 6px 18px rgba(0,0,0, 0.40)` |
| Decorative blob (white) | `rgba(255,255,255, 0.06)` | `rgba(255,255,255, 0.04)` |
| Decorative blob (gold accent) | `rgba(229,181,71, 0.16)` | `rgba(229,181,71, 0.12)` |
| Label text | `rgba(255,255,255, 0.85)` | giữ nguyên |
| Big number/title | `#FFFFFF` | giữ nguyên |
| Delta chip bg | `rgba(229,181,71, 0.95)` | giữ nguyên |
| Delta chip text | `#FFFFFF` | giữ nguyên |

#### Card Room/Property (signature component)

| Element | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#0F2F38` |
| Border (1px) | `#E2E8F0` | `transparent` |
| Radius | `24px` (xl) | giữ nguyên |
| Shadow | `0 6px 20px rgba(15,23,42, 0.06)` | `0 4px 18px rgba(0,0,0, 0.30)` |
| Image overlay gradient (bottom) | `linear-gradient(180deg, transparent, rgba(0,0,0,0.40))` | giữ nguyên |
| Status pill "Hoạt động" bg | `rgba(0,0,0, 0.55)` | giữ nguyên |
| Status pill text | `#FFFFFF` | giữ nguyên |
| Status pill dot active | `#22C55E` | `#4ADE80` |
| Image count badge bg | `rgba(0,0,0, 0.55)` | giữ nguyên |
| Price pill bg | `#0F5A6B` (jade500) | `#0F5A6B` |
| Price pill text | `#FFFFFF` w800 | giữ nguyên |
| Room name (size 17, w800) | `#0F172A` | `#E6F4F7` |
| Code chip border | `#0F5A6B` | `#5BCEDC` |
| Code chip text | `#0F5A6B` | `#5BCEDC` |
| Location icon | `#0F5A6B` | `#5BCEDC` |
| Location text | `#475569` (slate600) | `#B5C9D0` |
| Info chip icon container bg | `rgba(15,90,107, 0.08)` | `rgba(91,206,220, 0.18)` |
| Info chip icon | `#0F5A6B` | `#5BCEDC` |
| Info chip text | `#475569` | `#B5C9D0` |
| **Premium ribbon** (NEW) | bg gradient gold, text dark slate | giữ nguyên |
| **Hot badge** (NEW) | bg `#F2856B` (coral500), text white | bg `#F7AB94`, text `#6B2B17` |

#### Card alert (Cần xử lý ngay, warning)

| Element | Light | Dark |
|---|---|---|
| Background | `linear-gradient(135deg, rgba(234,179,8,0.10), rgba(234,179,8,0.04))` | `linear-gradient(135deg, rgba(251,191,36,0.18), rgba(251,191,36,0.06))` |
| Border (1px) | `rgba(234,179,8, 0.25)` | `rgba(251,191,36, 0.40)` |
| Icon container bg | `#EAB308` | `#FBBF24` |
| Icon container shadow | `0 4px 10px rgba(234,179,8, 0.30)` | `0 4px 10px rgba(251,191,36, 0.45)` |
| Title text | `#0F172A` | `#E6F4F7` |
| Body text | `#475569` | `#B5C9D0` |

#### Card AI insight (signature element — gold)

| Element | Light | Dark |
|---|---|---|
| Background | `linear-gradient(135deg, rgba(229,181,71,0.12), rgba(244,205,122,0.04))` | `linear-gradient(135deg, rgba(229,181,71,0.20), rgba(244,205,122,0.08))` |
| Border (1px) | `rgba(229,181,71, 0.30)` | `rgba(229,181,71, 0.45)` |
| Radius | `16px` | giữ nguyên |
| Icon container bg | `#E5B547` | `#E5B547` |
| Icon container shadow | `0 4px 10px rgba(229,181,71, 0.30)` | `0 4px 10px rgba(229,181,71, 0.50)` |
| Overline (GỢI Ý TỪ AI) | `#A8821F` (gold700) | `#F4CD7A` (goldBright) |
| Body text | `#0F172A` | `#E6F4F7` |
| Primary button bg | `#E5B547` | `#E5B547` |
| Primary button text | `#FFFFFF` | `#5C4500` |

#### Card premium accent (Top property, VIP listing — NEW)

| Element | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#0F2F38` |
| Border (2px) | `#E5B547` (gold500) | `#F4CD7A` (goldBright) |
| Shadow | `0 6px 20px rgba(229,181,71, 0.18)` | `0 6px 20px rgba(229,181,71, 0.30)` |
| Floating ribbon bg | gradient `#E5B547 → #F4CD7A` | giữ nguyên |
| Floating ribbon text | `#FFFFFF` | `#5C4500` |
| Floating ribbon position | `top: -8px, left: 14px, padding: 2px 8px, radius: 100px` | giữ nguyên |

#### Card hot/featured (warm coral accent — NEW)

| Element | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#0F2F38` |
| Border (2px) | `#F2856B` (coral500) | `#F7AB94` (coralBright) |
| Shadow | `0 6px 18px rgba(242,133,107, 0.18)` | `0 6px 18px rgba(242,133,107, 0.30)` |
| Floating badge bg | `#F2856B` | `#F7AB94` |
| Floating badge text | `#FFFFFF` | `#6B2B17` |

### 4.5 Buttons

#### FilledButton primary (Đặt ngay, Tạo mới, Save)

| Element | Light | Dark |
|---|---|---|
| Background | `#0F5A6B` (jade500) | `#5BCEDC` (jadeBright) |
| Background gradient (variant) | `linear-gradient(135deg, #0F5A6B, #1B7E94)` | `linear-gradient(135deg, #5BCEDC, #2A9DAD)` |
| Text color | `#FFFFFF` | `#052830` (jade900) |
| Shadow | `0 4px 14px rgba(15,90,107, 0.30)` | `0 4px 14px rgba(91,206,220, 0.30)` |
| Min height | `52px` | giữ nguyên |
| Radius | `12px` (md) | giữ nguyên |
| Font | Nunito, size 13-14, w600-700 | giữ nguyên |
| Disabled bg | `rgba(15,90,107, 0.30)` | `rgba(91,206,220, 0.30)` |
| Pressed | darken 8% | lighten 8% |

#### FilledButton premium (Booking VIP, Upgrade — gold)

| Element | Light | Dark |
|---|---|---|
| Background | `linear-gradient(135deg, #E5B547, #F4CD7A)` | giữ nguyên |
| Text color | `#FFFFFF` | `#5C4500` |
| Shadow | `0 4px 14px rgba(229,181,71, 0.35)` | `0 4px 14px rgba(229,181,71, 0.45)` |

#### FilledButton warm (Yêu thích, Share, secondary CTA — coral)

| Element | Light | Dark |
|---|---|---|
| Background | `#F2856B` | `#F7AB94` |
| Text color | `#FFFFFF` | `#6B2B17` |
| Shadow | `0 4px 14px rgba(242,133,107, 0.30)` | `0 4px 14px rgba(242,133,107, 0.40)` |

#### OutlinedButton (Cancel, Quay lại, secondary)

| Element | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#0F2F38` |
| Border (1.5px) | `#0F5A6B` | `#5BCEDC` |
| Text | `#0F5A6B` | `#5BCEDC` |
| Min height | `52px` | giữ nguyên |
| Radius | `12px` | giữ nguyên |

#### TextButton (Xem tất cả →, Chi tiết)

| Element | Light | Dark |
|---|---|---|
| Background | `transparent` | `transparent` |
| Text | `#0F5A6B` w600 | `#5BCEDC` |
| Pressed bg | `rgba(15,90,107, 0.08)` | `rgba(91,206,220, 0.15)` |

#### FAB (Center bottom nav)

xem section 4.3.

### 4.6 Input field

| Element | Light | Dark |
|---|---|---|
| Background filled | `#FFFFFF` | `#143E48` (darkContainer) |
| Border default (1px) | `#E2E8F0` | `#1B5664` |
| Border focus (2px) | `#0F5A6B` | `#5BCEDC` |
| Border error (1.5px) | `#DC2626` | `#F87171` |
| Text input | `#0F172A` | `#E6F4F7` |
| Hint text | `#64748B` (muted) | `#8FB8C2` (darkHint) |
| Label floating | `#475569`, focus: `#0F5A6B` | `#B5C9D0`, focus: `#5BCEDC` |
| Radius | `12px` (md) | giữ nguyên |
| Padding | `14px H × 14px V` | giữ nguyên |
| Helper text | `#64748B` | `#8FB8C2` |
| Error text | `#DC2626` | `#F87171` |

### 4.7 Search bar (rounded full pill)

| Element | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#143E48` |
| Border (1px) | `#E2E8F0` | `transparent` |
| Shadow (khi nổi trên gradient) | `0 4px 16px rgba(15,23,42, 0.08)` | `0 4px 16px rgba(0,0,0, 0.30)` |
| Radius | `100px` (full pill) | giữ nguyên |
| Padding | `10-12px × 14-16px` | giữ nguyên |
| Search icon | `#0F5A6B` | `#5BCEDC` |
| Hint text | `#64748B` | `#8FB8C2` |
| Suffix icon container bg | `rgba(15,90,107, 0.10)` | `rgba(91,206,220, 0.20)` |
| Suffix icon | `#0F5A6B` | `#5BCEDC` |

### 4.8 Chips

#### Filter / Choice chip

| Element | Light | Dark |
|---|---|---|
| Selected bg | `#0F5A6B` | `#5BCEDC` |
| Selected text | `#FFFFFF` w700 | `#052830` w700 |
| Unselected bg | `#FFFFFF` | `#0F2F38` |
| Unselected border (1px) | `#CBD5E1` (slate300) | `#1B5664` |
| Unselected text | `#0F172A` w500 | `#E6F4F7` w500 |
| Radius | `100px` (full pill) | giữ nguyên |
| Padding | `5-6px × 11-12px` | giữ nguyên |

#### Status pill (booking, room status)

xem section 3.6.

#### Tag pill mềm (CRM, Booking detail)

| Element | Light | Dark |
|---|---|---|
| Bg | `rgba({color}, 0.10-0.14)` | `rgba({color}, 0.20-0.25)` |
| Text | `{color 700}` | `{color 200/300}` |
| Border | none | none |
| Radius | `100px` | giữ nguyên |
| Padding | `2-3px × 7-8px` | giữ nguyên |
| Font | size 9-10, w800 | giữ nguyên |

### 4.9 Calendar grid (`CalendarGridWidget`)

| Element | Light | Dark |
|---|---|---|
| Grid container bg | `#FFFFFF` | `#0F2F38` |
| Grid border outer | `1px solid #E2E8F0` | `1px solid #1B5664` |
| Grid radius | `16px` | giữ nguyên |
| Header row bg | `#F8FAFC` (slate50) | `#143E48` |
| Cell border | `1px solid #F1F5F9` | `1px solid #143E48` |
| Today cell ring | `2px #0F5A6B` | `2px #5BCEDC` |
| Selected cell border | `2px #0F5A6B` | `2px #5BCEDC` |
| Weekday text | `#64748B` | `#8FB8C2` |
| Weekend text | `#1976D2` (blueWeekday) | `#60A5FA` |
| Holiday text | `#E65100` (orangeHoliday) | `#FB923C` |
| Empty cell hover | `rgba(15,90,107, 0.04)` | `rgba(91,206,220, 0.08)` |

#### Calendar cell states (4 trạng thái)

| State | Light bg | Light dot | Dark bg | Dark dot |
|---|---|---|---|---|
| Vacant | `#DCFCE7` | `#16A34A` | `rgba(74,222,128, 0.18)` | `#4ADE80` |
| Booked/Hold | `#FEF3C7` | `#F59E0B` | `rgba(251,191,36, 0.18)` | `#FBBF24` |
| Occupied | `#E6F4F5` | `#0F5A6B` | `rgba(91,206,220, 0.18)` | `#5BCEDC` |
| Maintenance | `#F1F5F9` + slash pattern | `#94A3B8` | `rgba(148,163,184, 0.18)` + slash | `#94A3B8` |

#### Slash pattern (maintenance)

```
Light: repeating-linear-gradient(45deg, rgba(148,163,184,0.08) 0 6px, rgba(148,163,184,0.16) 6px 12px)
Dark:  repeating-linear-gradient(45deg, rgba(148,163,184,0.10) 0 6px, rgba(148,163,184,0.22) 6px 12px)
```

### 4.10 Date picker tile / Guest counter

#### DatePickerTile

| Element | Light | Dark |
|---|---|---|
| Background | `#FFFFFF` | `#143E48` |
| Border (1px) | `#E2E8F0` | `#1B5664` |
| Radius | `12px` | giữ nguyên |
| Leading icon | `#0F5A6B` | `#5BCEDC` |
| Label | `#64748B` | `#8FB8C2` |
| Date value | `#0F172A` w700 | `#E6F4F7` |
| Trailing chevron | `#94A3B8` | `#8FB8C2` |
| Selected ring (range mode) | `2px #0F5A6B` | `2px #5BCEDC` |

#### GuestCounter

| Element | Light | Dark |
|---|---|---|
| Button minus/plus circle bg | `rgba(15,90,107, 0.12)` | `rgba(91,206,220, 0.18)` |
| Button icon | `#0F5A6B` | `#5BCEDC` |
| Button disabled bg | `rgba(15,90,107, 0.04)` | `rgba(91,206,220, 0.06)` |
| Button disabled icon | `#94A3B8` | `#6F9AA5` |
| Count text | `#0F172A` w800 size 18 | `#E6F4F7` |

### 4.11 Bottom sheet / Dialog / Modal

| Element | Light | Dark |
|---|---|---|
| Bottom sheet bg | `#FFFFFF` | `#1A4D58` (darkElevated) |
| Bottom sheet handle | `#CBD5E1` | `#2A6F80` |
| Top corner radius | `24px` | giữ nguyên |
| Dialog bg | `#FFFFFF` | `#1A4D58` |
| Dialog radius | `16px` | giữ nguyên |
| Dialog shadow | `0 8px 24px rgba(15,23,42, 0.12)` | `0 8px 24px rgba(0,0,0, 0.50)` |
| Backdrop scrim | `rgba(15,23,42, 0.50)` | `rgba(0,0,0, 0.65)` |

### 4.12 SnackBar (`AppSnackBar`)

| Variant | Light bg | Dark bg | Text |
|---|---|---|---|
| Success | `#16A34A` | `#22C55E` | `#FFFFFF` |
| Error | `#DC2626` | `#EF4444` | `#FFFFFF` |
| Info | `#0F5A6B` | `#1B7E94` | `#FFFFFF` |
| Warning | `#EAB308` | `#F59E0B` | `#FFFFFF` |

Floating, radius `12px`, margin `16px`, icon left + text w600 white.

### 4.13 Skeleton loading

| Element | Light | Dark |
|---|---|---|
| Shimmer base color | `#E2E8F0` (slate200) | `#143E48` |
| Shimmer highlight color | `#F1F5F9` (slate100) | `#1A4D58` |
| Skeleton block radius | matches actual component (8-16px) | giữ nguyên |
| Animation duration | `1500ms` linear infinite | giữ nguyên |

### 4.14 Empty / Error state

#### Empty state

| Element | Light | Dark |
|---|---|---|
| Icon circle bg | `rgba(15,90,107, 0.08)` | `rgba(91,206,220, 0.15)` |
| Icon color | `#0F5A6B` | `#5BCEDC` |
| Title (size 16, w700) | `#0F172A` | `#E6F4F7` |
| Subtext | `rgba(15,23,42, 0.50)` | `rgba(230,244,247, 0.55)` |

#### Error state

| Element | Light | Dark |
|---|---|---|
| Icon circle bg | `rgba(220,38,38, 0.08)` | `rgba(248,113,113, 0.18)` |
| Icon color | `#DC2626` | `#F87171` |
| Title | `#0F172A` | `#E6F4F7` |
| Retry button bg | `#DC2626` | `#F87171` |
| Retry button text | `#FFFFFF` | `#6B0F0F` |

### 4.15 Divider

| Element | Light | Dark |
|---|---|---|
| Solid divider | `#E2E8F0` | `#1B5664` |
| Dashed divider | `1px dashed #CBD5E1` | `1px dashed #2A6F80` |
| In-card item separator | `#F1F5F9` | `#143E48` |

### 4.16 Rating stars

| Element | Light | Dark |
|---|---|---|
| Star filled | `#E5B547` (gold500) | `#F4CD7A` (goldBright) |
| Star empty | `#CBD5E1` (slate300) | `#2A6F80` |
| Rating text | `#0F172A` w800 | `#E6F4F7` |

---

## 5. Migration mapping v1 → v2

### 5.1 Brand tokens

| v1 Name | v1 Hex | v2 Name | v2 Hex | Action |
|---|---|---|---|---|
| `ocean` | `#0A4F6E` | `jade500` | `#0F5A6B` | Đổi giá trị, đổi tên |
| `oceanMid` | `#0D6E96` | `jade300` | `#5BA8B5` | Đổi giá trị (sáng hơn, tone jade) |
| `oceanDeep` | `#062D42` | `jade900` | `#052830` | Đổi giá trị nhẹ |
| `oceanLight` | `#E8F4FA` | `jade50` | `#E6F4F5` | Đổi giá trị nhẹ |
| `oceanPale` | `#F0F8FC` | (xoá) | — | Không cần thiết, dùng `jade50` thay |
| `gold` | `#C9A84C` | `gold500` | `#E5B547` | Đổi giá trị (sáng hơn) |
| `goldLight` | `#FDF6E3` | `gold50` | `#FEF9E8` | Đổi giá trị nhẹ |
| `teal` | `#00B4D8` | (xoá) | — | Trùng vai trò với jade300, không cần |
| `tealLight` | `#CAF0F8` | (xoá) | — | |
| (mới) | — | `coral500` | `#F2856B` | **Thêm mới** |
| (mới) | — | `coral50` | `#FFEFE8` | **Thêm mới** |

### 5.2 Dark mode tokens

| v1 Name | v1 Hex | v2 Name | v2 Hex | Action |
|---|---|---|---|---|
| `darkBackground` | `#1A2232` | `darkBg` | `#0A1F26` | Đổi giá trị (deep jade) |
| `darkSurface` | `#212C3F` | `darkSurface` | `#0F2F38` | Đổi giá trị |
| `darkContainer` | `#283448` | `darkContainer` | `#143E48` | Đổi giá trị |
| `darkElevated` | `#2F3E54` | `darkElevated` | `#1A4D58` | Đổi giá trị |
| `darkBorder` | `#364D65` | `darkBorder` | `#1B5664` | Đổi giá trị |
| `darkDivider` | `#2A3A4F` | `darkDivider` | `#143E48` | Đổi giá trị |
| `darkHint` | `#8FA8BC` | `darkHint` | `#8FB8C2` | Đổi giá trị nhẹ |
| `darkSubtext` | `#7090AA` | `darkSubtext` | `#6F9AA5` | Đổi giá trị nhẹ |
| `darkTextPrimary` | `#E6F0F8` | `darkTextPrimary` | `#E6F4F7` | Đổi giá trị nhẹ |
| `oceanBright` | `#48C9F0` | `jadeBright` | `#5BCEDC` | Rename + đổi giá trị |
| `tealBright` | `#26D9C8` | (xoá) | — | Không cần |
| `goldBright` | `#D4AE5C` | `goldBright` | `#F4CD7A` | Đổi giá trị (sáng hơn) |
| (mới) | — | `coralBright` | `#F7AB94` | **Thêm mới** |

### 5.3 Aliases backward compat

Để migration không break, giai đoạn chuyển tiếp giữ alias deprecated 1-2 sprint:

```dart
// app_colors.dart
@Deprecated('Use jade500 instead. Will be removed in v2.1')
static const ocean = jade500;

@Deprecated('Use jade300 instead. Will be removed in v2.1')
static const oceanMid = jade300;

@Deprecated('Use coral500 instead, or jade300 if you meant the cyan accent')
static const teal = jade300;
```

Sau 2 sprint, search `@Deprecated` → xoá hết alias.

---

## 6. Flutter implementation

### 6.1 `lib/core/theme/app_colors.dart`

```dart
import 'package:flutter/material.dart';

/// Halong24h color tokens v2.0 — Jade Bay palette
/// Tham chiếu báo cáo: docs/halong24h-color-system-v2.md
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════════
  // BRAND — Jade (primary, không đổi giữa light/dark)
  // ═══════════════════════════════════════════════════════════════
  static const jade50  = Color(0xFFE6F4F5);
  static const jade100 = Color(0xFFC9E5E8);
  static const jade200 = Color(0xFFA6D2D8);
  static const jade300 = Color(0xFF5BA8B5);
  static const jade500 = Color(0xFF0F5A6B); // MAIN
  static const jade700 = Color(0xFF0A3F4B);
  static const jade900 = Color(0xFF052830);

  // ═══════════════════════════════════════════════════════════════
  // BRAND — Gold (secondary, premium accent)
  // ═══════════════════════════════════════════════════════════════
  static const gold50  = Color(0xFFFEF9E8);
  static const gold100 = Color(0xFFFCEFC4);
  static const gold300 = Color(0xFFF4CD7A);
  static const gold500 = Color(0xFFE5B547); // MAIN
  static const gold700 = Color(0xFFA8821F);
  static const gold900 = Color(0xFF5C4500);

  // ═══════════════════════════════════════════════════════════════
  // BRAND — Coral (NEW warm accent)
  // ═══════════════════════════════════════════════════════════════
  static const coral50  = Color(0xFFFFEFE8);
  static const coral100 = Color(0xFFFED4C4);
  static const coral300 = Color(0xFFF7AB94);
  static const coral500 = Color(0xFFF2856B); // MAIN
  static const coral700 = Color(0xFFB85A3F);
  static const coral900 = Color(0xFF6B2B17);

  // ═══════════════════════════════════════════════════════════════
  // NEUTRAL — Slate scale (text, structure)
  // ═══════════════════════════════════════════════════════════════
  static const slate50  = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0); // border default
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B); // muted
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155); // ink
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A); // navy strongest

  // Limestone (warm bg option)
  static const limestone50  = Color(0xFFFAF7F0);
  static const limestone100 = Color(0xFFF5EFE3);

  // ═══════════════════════════════════════════════════════════════
  // DARK MODE — Deep Jade base
  // ═══════════════════════════════════════════════════════════════
  static const darkBg          = Color(0xFF0A1F26);
  static const darkSurface     = Color(0xFF0F2F38);
  static const darkContainer   = Color(0xFF143E48);
  static const darkElevated    = Color(0xFF1A4D58);
  static const darkBorder      = Color(0xFF1B5664);
  static const darkDivider     = Color(0xFF143E48);
  static const darkHint        = Color(0xFF8FB8C2);
  static const darkSubtext     = Color(0xFF6F9AA5);
  static const darkTextPrimary = Color(0xFFE6F4F7);
  static const darkTextSecondary = Color(0xFFB5C9D0);

  // Bright accents on dark
  static const jadeBright  = Color(0xFF5BCEDC);
  static const goldBright  = Color(0xFFF4CD7A);
  static const coralBright = Color(0xFFF7AB94);

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC
  // ═══════════════════════════════════════════════════════════════
  // Light
  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFEAB308);
  static const warningBg = Color(0xFFFEF9C3);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEE2E2);
  static const info = jade500;

  // Dark variants
  static const successDark = Color(0xFF4ADE80);
  static const warningDark = Color(0xFFFBBF24);
  static const errorDark = Color(0xFFF87171);
  static const infoDark = jadeBright;

  // ═══════════════════════════════════════════════════════════════
  // STATUS — Booking
  // ═══════════════════════════════════════════════════════════════
  static const statusHold = Color(0xFFF59E0B);
  static const statusConfirmed = Color(0xFF22C55E);
  static const statusCancelled = Color(0xFFEF4444);
  static const statusCompleted = Color(0xFF7B1FA2);

  // Dark variants
  static const statusHoldDark = Color(0xFFFBBF24);
  static const statusConfirmedDark = Color(0xFF4ADE80);
  static const statusCancelledDark = Color(0xFFF87171);
  static const statusCompletedDark = Color(0xFFC084FC);

  // ═══════════════════════════════════════════════════════════════
  // BACKWARD COMPAT (deprecated, sẽ xoá ở v2.1)
  // ═══════════════════════════════════════════════════════════════
  @Deprecated('Use jade500 instead. Will be removed in v2.1')
  static const ocean = jade500;
  @Deprecated('Use jade300 instead. Will be removed in v2.1')
  static const oceanMid = jade300;
  @Deprecated('Use jade900 instead.')
  static const oceanDeep = jade900;
  @Deprecated('Use jade50 instead.')
  static const oceanLight = jade50;
  @Deprecated('Use gold500 instead.')
  static const gold = gold500;
  @Deprecated('Removed. Use jade300 if you need cyan accent.')
  static const teal = jade300;
  @Deprecated('Use jadeBright instead.')
  static const oceanBright = jadeBright;
}
```

### 6.2 `lib/core/theme/app_color_scheme.dart`

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Mapping color cụ thể cho từng theme.
/// Truy cập trong widget: context.colors.bgSurface
class AppColorScheme {
  // Backgrounds
  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSurfaceContainer;
  final Color bgSurfaceElevated;
  final Color bgWarm; // limestone option

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textBrand;
  final Color textBrandAccent;
  final Color textBrandWarm;
  final Color textOnPrimary;
  final Color textOnSecondary;
  final Color textOnCoral;

  // Borders
  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderBrand;
  final Color borderGold;
  final Color borderCoral;

  // Brand
  final Color brand;          // jade primary cho theme này
  final Color brandLight;     // accent on theme
  final Color brandSecondary; // gold cho theme
  final Color brandWarm;      // coral cho theme

  // Semantic
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color error;
  final Color errorBg;
  final Color info;

  const AppColorScheme.light()
      : bgCanvas = AppColors.slate50,
        bgSurface = const Color(0xFFFFFFFF),
        bgSurfaceContainer = AppColors.slate100,
        bgSurfaceElevated = const Color(0xFFFFFFFF),
        bgWarm = AppColors.limestone50,
        textPrimary = AppColors.slate900,
        textSecondary = AppColors.slate600,
        textTertiary = AppColors.slate500,
        textDisabled = AppColors.slate400,
        textBrand = AppColors.jade500,
        textBrandAccent = AppColors.gold700,
        textBrandWarm = AppColors.coral700,
        textOnPrimary = const Color(0xFFFFFFFF),
        textOnSecondary = const Color(0xFFFFFFFF),
        textOnCoral = const Color(0xFFFFFFFF),
        borderSubtle = AppColors.slate100,
        borderDefault = AppColors.slate200,
        borderStrong = AppColors.slate300,
        borderBrand = AppColors.jade500,
        borderGold = AppColors.gold500,
        borderCoral = AppColors.coral500,
        brand = AppColors.jade500,
        brandLight = AppColors.jade300,
        brandSecondary = AppColors.gold500,
        brandWarm = AppColors.coral500,
        success = AppColors.success,
        successBg = AppColors.successBg,
        warning = AppColors.warning,
        warningBg = AppColors.warningBg,
        error = AppColors.error,
        errorBg = AppColors.errorBg,
        info = AppColors.jade500;

  const AppColorScheme.dark()
      : bgCanvas = AppColors.darkBg,
        bgSurface = AppColors.darkSurface,
        bgSurfaceContainer = AppColors.darkContainer,
        bgSurfaceElevated = AppColors.darkElevated,
        bgWarm = AppColors.darkSurface,
        textPrimary = AppColors.darkTextPrimary,
        textSecondary = AppColors.darkTextSecondary,
        textTertiary = AppColors.darkHint,
        textDisabled = AppColors.darkSubtext,
        textBrand = AppColors.jadeBright,
        textBrandAccent = AppColors.goldBright,
        textBrandWarm = AppColors.coralBright,
        textOnPrimary = AppColors.jade900,
        textOnSecondary = AppColors.gold900,
        textOnCoral = AppColors.coral900,
        borderSubtle = AppColors.darkDivider,
        borderDefault = AppColors.darkBorder,
        borderStrong = const Color(0xFF2A6F80),
        borderBrand = AppColors.jadeBright,
        borderGold = AppColors.goldBright,
        borderCoral = AppColors.coralBright,
        brand = AppColors.jadeBright,
        brandLight = AppColors.jade300,
        brandSecondary = AppColors.goldBright,
        brandWarm = AppColors.coralBright,
        success = AppColors.successDark,
        successBg = const Color(0x294ADE80), // 16% alpha
        warning = AppColors.warningDark,
        warningBg = const Color(0x29FBBF24),
        error = AppColors.errorDark,
        errorBg = const Color(0x29F87171),
        info = AppColors.jadeBright;
}

/// ThemeExtension để truy cập color scheme trong widget tree.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppColorScheme colors;
  const AppThemeExtension({required this.colors});

  @override
  AppThemeExtension copyWith({AppColorScheme? colors}) =>
      AppThemeExtension(colors: colors ?? this.colors);

  @override
  AppThemeExtension lerp(covariant AppThemeExtension? other, double t) =>
      other == null ? this : (t < 0.5 ? this : other);
}

/// Extension cho BuildContext để gọi `context.colors.bgSurface`
extension AppThemeContext on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppThemeExtension>()!.colors;
}
```

### 6.3 `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_color_scheme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const scheme = AppColorScheme.light();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scheme.bgCanvas,

      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.jade500,
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: AppColors.jade50,
        onPrimaryContainer: AppColors.jade900,
        secondary: AppColors.gold500,
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: AppColors.gold50,
        onSecondaryContainer: AppColors.gold900,
        tertiary: AppColors.coral500,
        onTertiary: const Color(0xFFFFFFFF),
        tertiaryContainer: AppColors.coral50,
        onTertiaryContainer: AppColors.coral900,
        error: AppColors.error,
        onError: const Color(0xFFFFFFFF),
        errorContainer: AppColors.errorBg,
        onErrorContainer: const Color(0xFF7F1D1D),
        surface: scheme.bgSurface,
        onSurface: scheme.textPrimary,
        surfaceContainerHighest: scheme.bgSurfaceContainer,
        onSurfaceVariant: scheme.textSecondary,
        outline: scheme.borderDefault,
        outlineVariant: scheme.borderSubtle,
      ),

      textTheme: _textTheme(scheme.textPrimary),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.bgSurface,
        foregroundColor: scheme.textBrand,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.textBrand,
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.borderDefault, width: 1),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.jade500,
          foregroundColor: const Color(0xFFFFFFFF),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.jade500,
          side: const BorderSide(color: AppColors.jade500, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.borderDefault, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.borderDefault, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.jade500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: scheme.textTertiary),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.bgSurface,
        selectedItemColor: AppColors.jade500,
        unselectedItemColor: scheme.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.borderDefault,
        thickness: 1,
        space: 1,
      ),

      extensions: const [AppThemeExtension(colors: scheme)],
    );
  }

  static ThemeData dark() {
    const scheme = AppColorScheme.dark();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scheme.bgCanvas,

      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.jadeBright,
        onPrimary: AppColors.jade900,
        primaryContainer: AppColors.jade700,
        onPrimaryContainer: AppColors.jade50,
        secondary: AppColors.goldBright,
        onSecondary: AppColors.gold900,
        secondaryContainer: AppColors.gold700,
        onSecondaryContainer: AppColors.gold50,
        tertiary: AppColors.coralBright,
        onTertiary: AppColors.coral900,
        tertiaryContainer: AppColors.coral700,
        onTertiaryContainer: AppColors.coral50,
        error: AppColors.errorDark,
        onError: const Color(0xFF7F1D1D),
        errorContainer: const Color(0xFF7F1D1D),
        onErrorContainer: AppColors.errorBg,
        surface: scheme.bgSurface,
        onSurface: scheme.textPrimary,
        surfaceContainerHighest: scheme.bgSurfaceContainer,
        onSurfaceVariant: scheme.textSecondary,
        outline: scheme.borderDefault,
        outlineVariant: scheme.borderSubtle,
      ),

      textTheme: _textTheme(scheme.textPrimary),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.bgSurface,
        foregroundColor: scheme.textBrand,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.textBrand,
        ),
      ),

      cardTheme: CardThemeData(
        color: scheme.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.borderDefault, width: 1),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.jadeBright,
          foregroundColor: AppColors.jade900,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),

      // ... các theme khác tương tự light(), thay tham chiếu sang scheme dark

      extensions: const [AppThemeExtension(colors: scheme)],
    );
  }

  static TextTheme _textTheme(Color baseColor) {
    return GoogleFonts.nunitoTextTheme().apply(
      bodyColor: baseColor,
      displayColor: baseColor,
    );
  }
}
```

### 6.4 Cách dùng trong widget

```dart
class RoomCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Truy cập color scheme đã setup
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        children: [
          Text(
            'Phòng View Vịnh',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          Text(
            'Sea Pearl Halong',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
          // Pricing pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.brand, // jade500 light, jadeBright dark
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '1.500.000đ',
              style: TextStyle(
                color: colors.textOnPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 6.5 Apply theme trong `main.dart`

```dart
class HalongApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Halong24h',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode, // ThemeMode.system / .light / .dark
      routerConfig: ref.watch(routerProvider),
    );
  }
}
```

---

## 7. Migration checklist

### P0 — Token + theme infrastructure (1 ngày)

- [ ] Tạo file `lib/core/theme/app_colors.dart` theo template 6.1
- [ ] Tạo file `lib/core/theme/app_color_scheme.dart` theo template 6.2
- [ ] Update `lib/core/theme/app_theme.dart` theo template 6.3 (light + dark)
- [ ] Apply trong `main.dart` (template 6.5)
- [ ] Smoke test: chạy app, toggle theme → không crash, màu đổi đúng

### P1 — Audit hardcoded colors (4-6 giờ)

- [ ] `grep -r "Color(0xFF" lib/` → list tất cả hardcoded
- [ ] Mỗi vị trí thay bằng `context.colors.x` hoặc `AppColors.x`
- [ ] **Tránh** dùng `Theme.of(context).colorScheme.primary` cho mọi thứ — chỉ dùng cho component Material core (Button, AppBar). Custom widget → dùng `context.colors`
- [ ] Audit `Container.decoration` có `color:` → đổi sang token
- [ ] Audit `Text.style` có `color:` → đổi sang token
- [ ] Audit `Border` và `BoxShadow` → đổi sang token

### P2 — Component refactor (1 ngày)

- [ ] AppBar: dùng `appBarTheme` mặc định, custom screen có gradient header riêng (như Greeting Header)
- [ ] BottomNavigation custom (`AppScaffold`): update FAB gradient + active pill
- [ ] Card mặc định: radius `16`, border `borderDefault`
- [ ] Room/Property Card: hero shadow `0 6px 20px rgba(15,23,42, 0.06)` light / `0 4px 18px rgba(0,0,0, 0.30)` dark
- [ ] Calendar grid 4 cell state (vacant/booked/occupied/maintenance) — verify cả light + dark
- [ ] Date picker tile, Guest counter — update icon container bg
- [ ] Empty state, Error state — update icon circle bg
- [ ] Skeleton — update shimmer colors

### P3 — Visual QA (2-3 giờ)

Mở từng screen sau ở **CẢ light + dark**, screenshot lưu trong PR:

- [ ] Splash screen
- [ ] Login / Register / Forgot password
- [ ] Customer Home (greeting gradient)
- [ ] Search Room
- [ ] Room Detail (manager + customer)
- [ ] My Bookings (customer)
- [ ] Booking Detail
- [ ] Manager Dashboard
- [ ] Reports (charts!)
- [ ] Owner Calendar
- [ ] Booking List (status filter)
- [ ] Hold Room form
- [ ] Property Management
- [ ] Property Add wizard (8 steps)
- [ ] Notifications
- [ ] Profile + sub screens

### P4 — Documentation update

- [ ] Update file `design-brief.md` v1.0 → v2.0 với palette mới
- [ ] Update README.md mention design system v2
- [ ] Storybook/Widgetbook (nếu có) — refresh demos

---

## 8. QA checklist trước merge

### 8.1 Contrast ratio (WCAG AA tối thiểu 4.5:1 cho text)

Verify với [WebAIM contrast checker](https://webaim.org/resources/contrastchecker/):

- [ ] `slate900` trên `bgSurface` light = 16.0 ✓
- [ ] `darkTextPrimary` trên `darkBg` = 14.2 ✓
- [ ] `jade500` text trên `jade50` = 7.8 ✓ (link, badge)
- [ ] `jadeBright` text trên `darkBg` = 8.2 ✓
- [ ] `gold500` không dùng làm text trên trắng (chỉ 2.4 — fail) → text gold luôn dùng `gold700` `#A8821F` (4.7 ✓)
- [ ] White text trên `coral500` = 3.6 (chỉ pass cho large text 18+ size). Pill nhỏ thì dùng `coral900` text trên `coral50` bg

### 8.2 Brand consistency

- [ ] Mọi screen có element brand đều dùng jade primary (không mix với teal/cyan ngẫu nhiên)
- [ ] Gold chỉ dùng cho premium/highlight (Property top, Rating star, Premium badge) — KHÔNG dùng làm CTA chính
- [ ] Coral chỉ dùng cho warm/hot accent (Wishlist, "Phổ biến", urgent notification) — KHÔNG dùng làm primary
- [ ] Limestone bg chỉ áp 1-2 screen "ấm cúng" (Customer Home, Welcome) — không tràn lan

### 8.3 Dark mode visual

- [ ] Toggle dark mode trên từng screen → mọi text vẫn đọc rõ
- [ ] Border vẫn nhìn được (không bị mất hút trong nền dark)
- [ ] Image, icon contrast đủ
- [ ] Loading skeleton shimmer rõ trên nền dark (không bị lẫn)
- [ ] Calendar 4 state phân biệt được trên dark
- [ ] Status badge (booking/room) đọc được không khó

### 8.4 Smoke test thiết bị thật

- [ ] iOS device thật (iPhone, không simulator) — test scrolled appbar elevation, status bar
- [ ] Android device thật — test ripple, bottom nav curve
- [ ] OLED screen (dark mode) — verify `darkBg` không bị "bleed black"
- [ ] LCD screen — verify dark mode không quá xanh

### 8.5 Accessibility

- [ ] System dark mode toggle hoạt động (Settings → Display)
- [ ] Tăng font size system → layout không vỡ
- [ ] VoiceOver (iOS) / TalkBack (Android) đọc đúng tên màu/state

---

## Phụ lục — Cheat sheet cho dev khi code

### Tra cứu nhanh: muốn màu X dùng token nào?

| Tôi muốn... | Light token | Dark token |
|---|---|---|
| Background trang chính | `bgCanvas` | `bgCanvas` |
| Background card | `bgSurface` | `bgSurface` |
| Background card nổi (modal, hero) | `bgSurfaceElevated` | `bgSurfaceElevated` |
| Background warm cosy | `bgWarm` (limestone) | `bgSurface` |
| Text title heading | `textPrimary` | `textPrimary` |
| Text body | `textSecondary` | `textSecondary` |
| Text meta nhỏ | `textTertiary` | `textTertiary` |
| Text brand (link, AppBar title) | `textBrand` | `textBrand` |
| Text trên button primary | `textOnPrimary` | `textOnPrimary` |
| Border card mặc định | `borderDefault` | `borderDefault` |
| Border focus input | `borderBrand` | `borderBrand` |
| Color CTA chính (Đặt ngay) | `brand` | `brand` |
| Color CTA premium (VIP) | `brandSecondary` (gold) | `brandSecondary` |
| Color CTA warm (Yêu thích) | `brandWarm` (coral) | `brandWarm` |
| Status xanh thành công | `success` | `success` |
| Status đỏ lỗi | `error` | `error` |
| Booking pill "Đã xác nhận" | `AppColors.statusConfirmed` + bg `successBg` | `statusConfirmedDark` |

### Anti-patterns cần tránh

❌ Hardcode hex trong widget code:
```dart
Container(color: Color(0xFF0F5A6B)) // KHÔNG
```

✓ Dùng token:
```dart
Container(color: context.colors.brand) // ✓
```

❌ Dùng `Colors.green`, `Colors.red` từ Flutter:
```dart
Icon(Icons.check, color: Colors.green) // KHÔNG — màu lệch khỏi brand
```

✓ Dùng semantic token:
```dart
Icon(Icons.check, color: context.colors.success) // ✓
```

❌ Mix nhiều shade primary trong cùng 1 screen:
```dart
// Screen có jade500 + jade300 + ocean variant cũ → loạn
```

✓ Stick với 1 shade chính + 1 accent:
```dart
// Brand: jade500 → gold500 accent → slate text
```

❌ Dùng `Theme.of(context).primaryColor` cho custom widget — không support dark mode tự động trong custom paint:

✓ Dùng `context.colors.brand` — auto-aware light/dark.

---

**Phiên bản**: 2.0
**Cập nhật cuối**: 27/04/2026
**Kế thừa từ**: design-brief.md v1.0
**Áp dụng cho**: Flutter 3.x, Material 3, google_fonts (Nunito), riverpod 2.6+
**File này thay thế**: section 2.1 (Color Palette) trong design-brief.md v1.0
