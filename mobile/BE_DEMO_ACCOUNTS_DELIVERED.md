# BE Reply — Demo Accounts cho Apple/Google Review

> **Trạng thái**: ✅ DONE — verified trên production
> **Ngày**: 2026-05-10
> **Liên quan**: [BE_DEMO_ACCOUNTS_REQUEST.md](BE_DEMO_ACCOUNTS_REQUEST.md) (FE → BE original request)
> **API base**: `https://api.halong24h.com`

---

## ✅ Confirm

```
✅ Demo accounts created (production DB):

  • CUSTOMER:  apple-review-customer@halong24h.com
  • OWNER:     apple-review-owner@halong24h.com
                — KYC approved, trial 30 ngày
                — 3 properties + 5 bookings + 4 notifications
                — 1 SALE linked
  • SALE:      apple-review-sale@halong24h.com
                — linked với Owner

  Password (cùng cho 3 accounts): Halong24h@2026

Tested on https://api.halong24h.com — all login + flow working end-to-end.
```

> Data đã được **reset clean** ngay trước khi gửi spec này (chạy lại seed → bookings/notifications về state ban đầu, không có dữ liệu test rớt lại).

---

## 1. Login credentials (paste vào Apple Review form)

### Apple App Review — Demo Account section

```
Username: apple-review-customer@halong24h.com
Password: Halong24h@2026
```

> Apple yêu cầu 1 demo account chính. **CUSTOMER** là phù hợp nhất để reviewer test
> flow đặt phòng (search → book → my-bookings). Nếu reviewer muốn test full mgmt flow,
> báo họ thử **OWNER** account ở "Notes for Review":

### Apple Review — Notes for Review

```
This app supports 4 roles. To fully test:

  CUSTOMER (default):
    apple-review-customer@halong24h.com / Halong24h@2026
    → Browse properties, book a room

  OWNER (homestay manager):
    apple-review-owner@halong24h.com / Halong24h@2026
    → KYC pre-approved, trial active. View dashboard, properties, bookings.
    → Can also test "Quản lý nhân viên" flow.

  SALE (staff member):
    apple-review-sale@halong24h.com / Halong24h@2026
    → Linked to Owner above. Scoped view of Owner's data.

Apple Sign-In and Google Sign-In are also supported on the Login screen.
Test push notifications by triggering a booking confirmation in OWNER account.
```

---

## 2. Detail của từng account

### 2.1 CUSTOMER — `apple-review-customer@halong24h.com`

| Field | Value |
|---|---|
| Password | `Halong24h@2026` |
| Role | 3 (CUSTOMER) |
| Phone | `0327000001` |
| Name | Apple Reviewer Customer |
| `isActive` | true |
| `emailVerified` | true |

**Reviewer có thể**:
- Login → vào `/home` → search property
- Tap 1 trong 3 demo properties → xem detail (3-4 ảnh)
- Tap "Đặt phòng" → tạo booking customer-hold (tự động hold 24 giờ)
- Vào `/my-bookings` → thấy booking vừa tạo
- Cancel booking → status chuyển sang `CANCELLED`

### 2.2 OWNER — `apple-review-owner@halong24h.com` ⭐

| Field | Value |
|---|---|
| Password | `Halong24h@2026` |
| Role | 1 (OWNER) |
| Phone | `0327000002` |
| Name | Apple Reviewer Owner |
| `isActive` | true |
| `emailVerified` | true |
| `kycStatus` | `approved` ✅ |
| `kycBypass` | `true` (skip toàn bộ KYC flow) |
| `subscriptionStatus` | `trial` |
| `subscriptionPlanId` | `starter` |
| `subscriptionCycle` | `monthly` |
| `trialEndsAt` | **+30 ngày kể từ seed** |

**Reviewer có thể**:
- Login → dashboard load OK
- **KHÔNG** thấy banner "Hoàn tất KYC" (vì đã approved)
- Thấy banner "Trial còn ~30 ngày"
- Vào "Phòng" → 3 properties (Villa/Homestay/Hotel)
- Vào "Booking" → 5 bookings với 4 status khác nhau
- Vào "Lịch" → calendar grid với days bị block theo bookings
- Vào "Quản lý nhân viên" → 1 SALE đã accept invite
- Thử push notification: confirm 1 booking → device nhận push (nếu đã register FCM token)

### 2.3 SALE — `apple-review-sale@halong24h.com`

| Field | Value |
|---|---|
| Password | `Halong24h@2026` |
| Role | 2 (SALE) |
| Phone | `0327000003` |
| Name | Apple Reviewer Sale |
| `ownerId` | (= id của OWNER demo) |
| `isActive` | true |
| `saleMembershipStatus` | active |

**Reviewer có thể**:
- Login → dashboard scope theo OWNER
- Thấy đúng 3 properties + 5 bookings của OWNER
- **KHÔNG** thấy `/properties/new` (FE chặn)
- Nếu cố `POST /properties` → BE trả 403 (verify protection)

---

## 3. Detail 3 demo properties

| # | Code | Name | Type | View | Bedrooms | Maxg | Weekday | Weekend | Holiday |
|---|---|---|---|---|:---:|:---:|---|---|---|
| 1 | `DEMO-VILLA-01` | Villa Hạ Long View Biển | VILLA (0) | sea | 3 | 8 | 3.5tr | 4.5tr | 5.5tr |
| 2 | `DEMO-HOMESTAY-02` | Homestay Bãi Cháy Cozy | HOMESTAY (1) | city | 2 | 4 | 1.2tr | 1.5tr | 2.0tr |
| 3 | `DEMO-HOTEL-03` | Hạ Long Bay Hotel - Studio | HOTEL (2) | sea | 1 | 3 | 2.0tr | 2.5tr | 3.0tr |

Mỗi property có 3-4 ảnh từ Unsplash (CDN public, hiển thị OK trên app).

Amenities, cancellation policy, check-in/out time đều đã set theo spec.

---

## 4. Detail 5 demo bookings

| # | Property | Customer | Status | Check-in | Check-out | Deposit | Notes |
|---|---|---|:---:|---|---|---|---|
| 1 | Villa | Nguyễn Văn A (`0901111111`) | **HOLD** | +5d | +7d | — | Walk-in chờ chuyển khoản |
| 2 | Villa | Trần Thị B (`0902222222`) | **CONFIRMED** | +10d | +12d | 2tr | Đã thanh toán cọc |
| 3 | Homestay | Lê Văn C (`0903333333`) | **CONFIRMED** | +3d | +4d | 500k | — |
| 4 | Hotel | Phạm D (`0904444444`) | **COMPLETED** | -10d | -8d | 1tr | Hoàn thành tuần trước (cho phép review) |
| 5 | Villa | Hoàng E (`0905555555`) | **CANCELLED** | -5d | -3d | — | Khách đã huỷ |

`saleId` = OWNER (ai cũng nhận được). `customerId` = `null` (walk-in).

---

## 5. 4 demo notifications cho OWNER

| # | Type | Title | Read | Time |
|---|---|---|:---:|---|
| 1 | booking | Đặt phòng mới — Khách Nguyễn Văn A đặt Villa | 🔴 unread | 2 giờ trước |
| 2 | booking | Booking xác nhận — Trần Thị B | 🔴 unread | 1 ngày trước |
| 3 | system | Chào mừng — KYC duyệt, trial 30 ngày | ✅ read | 7 ngày trước |
| 4 | payment | Thanh toán thành công — 2,000,000 VND | ✅ read | 1 ngày trước |

---

## 6. Test sandbox info

| Item | Value |
|---|---|
| **API base** | `https://api.halong24h.com` |
| **Swagger UI** | `https://api.halong24h.com/index.html` |
| **Web Client ID Google** | `832659566372-25rp2ch2s7nqiho1057i1ho1g2i1ffmc.apps.googleusercontent.com` |
| **Apple Bundle ID** | `com.halongtravel.halong24h` |
| **Firebase project** | `halong24h-production` |
| **Min app version (force-update)** | `1.0.0` (cả iOS + Android) |
| **VNPay** | sandbox `https://sandbox.vnpayment.vn/paymentv2/vpcpay.html` |

---

## 7. cURL test nhanh trước submit (FE / QA chạy)

```bash
# 1. CUSTOMER login
curl -X POST https://api.halong24h.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"apple-review-customer@halong24h.com","password":"Halong24h@2026"}'

# 2. OWNER login → lấy accessToken → kiểm tra 3 properties
TOKEN=$(curl -s -X POST https://api.halong24h.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"apple-review-owner@halong24h.com","password":"Halong24h@2026"}' \
  | sed 's/.*"accessToken":"\([^"]*\)".*/\1/')

curl https://api.halong24h.com/properties -H "Authorization: Bearer $TOKEN"
# → 3 row

curl https://api.halong24h.com/bookings -H "Authorization: Bearer $TOKEN"
# → 5 row

curl https://api.halong24h.com/staff -H "Authorization: Bearer $TOKEN"
# → 1 row (SALE)

# 3. SALE login → verify scope đúng
TOKEN=$(curl -s -X POST https://api.halong24h.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"apple-review-sale@halong24h.com","password":"Halong24h@2026"}' \
  | sed 's/.*"accessToken":"\([^"]*\)".*/\1/')

curl https://api.halong24h.com/properties -H "Authorization: Bearer $TOKEN"
# → 3 row giống OWNER (auto-scope by ownerId)

curl -X POST https://api.halong24h.com/properties \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
# → 403 Forbidden (đúng — SALE không được tạo property)
```

---

## 8. Cleanup sau khi qua review

⚠️ **KHÔNG xoá ngay sau submit** — Apple/Google có thể yêu cầu re-test sau update. Giữ ít nhất **30 ngày** sau khi app live.

Sau 30 ngày, BE chạy:
```sql
-- Soft-disable (recommended)
UPDATE users SET "isActive" = false WHERE email LIKE 'apple-review-%@halong24h.com';
```

Hoặc nếu muốn re-seed (reset về clean state):
```bash
npx ts-node -r tsconfig-paths/register prisma/seed-demo-accounts.ts
```
Script idempotent — chạy nhiều lần OK, sẽ reset bookings/notifications về clean state.

---

## 9. Force-update version đề xuất khi submit

Khi chuẩn bị submit lên store, BE update version qua endpoint admin:

```bash
ADMIN_TOKEN=$(curl -s -X POST https://api.halong24h.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"<admin>@halong24h.com","password":"<admin-pwd>"}' \
  | sed 's/.*"accessToken":"\([^"]*\)".*/\1/')

curl -X POST https://api.halong24h.com/admin/app-version \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "ios",
    "latestVersion": "1.0.0",
    "minSupportedVersion": "1.0.0",
    "releaseNotes": "Phiên bản đầu tiên — đặt homestay Hạ Long",
    "storeUrl": "https://apps.apple.com/app/halong24h/id<APP_ID>"
  }'

curl -X POST https://api.halong24h.com/admin/app-version \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "android",
    "latestVersion": "1.0.0",
    "minSupportedVersion": "1.0.0",
    "releaseNotes": "Phiên bản đầu tiên",
    "storeUrl": "https://play.google.com/store/apps/details?id=com.halongtravel.halong24h"
  }'
```

→ Sau khi version mới (1.1.0+) ra, update `latestVersion` để FE hiện soft-update dialog. Update `minSupportedVersion` để force-update nếu cần.

---

## 10. Liên hệ

Nếu reviewer report fail / data thiếu / login error → ping BE để check log + re-seed nếu cần.
Có thay đổi schema/business rule sau ngày này, BE sẽ update file [API.md](API.md).

**Sẵn sàng cho Bước 2: Test trên iPhone thật + submit lên App Store / Play Store.**
