# Halong24h Mobile — Báo cáo luồng & bố cục app (để Android đồng bộ)

> Nguồn: đọc trực tiếp từ code Flutter (branch `feature/ios-setup`), ngày 2026-07-13.
> **Đã loại trừ Apple Sign-In theo yêu cầu.** Base URL: `https://api.halong24h.com`.
> Response chuẩn: `{ success, data, message }` (bọc trong `ApiResponse`). Auth qua Bearer token.

---

## 0. Tóm tắt 6 điểm Android BẮT BUỘC đồng bộ

1. **Auth chỉ trả token, KHÔNG trả user.** Sau `/auth/login|register|google|refresh` phải gọi `GET /auth/profile` để lấy user. Token nằm trong `data.accessToken` / `data.refreshToken`.
2. **Login body key hiện là `email`** (chưa phải `identifier`) — BE DTO còn `@IsEmail()`. Chuẩn hoá SĐT `+84…/84…` → `0…` phía client trước khi gửi.
3. **Khác biệt iOS/Android chỉ nằm ở 1 flag** `AppConfig.hidePaidUpgradeUI = Platform.isIOS`. Android = `false` → **hiện đầy đủ** UI plan/giá/VietQR/trial/renew. Android KHÔNG ẩn gì, dùng full luồng thanh toán.
4. **2 cổng khoá tạo phòng (theo thứ tự):** (a) OWNER phải **KYC approved**, rồi (b) phải có **bank account approved** (`hasApprovedBank`). SALE/ADMIN không bị 2 cổng này.
5. **3 role:** `ADMIN=0, OWNER=1, SALE=2`. `CUSTOMER=3` chỉ tồn tại ở backend (khách đăng ký qua website) — **không có màn/luồng khách trong app**.
6. **Header luôn gửi:** `X-Client-Type: mobile` (BE tách session slot theo client). `X-Device-Id` chỉ gửi ở `/auth/register` + `/auth/google` (anti-spam). 401 → auto-refresh; **403 tại `/auth/refresh` = phiên bị đá** (thiết bị khác cùng loại chiếm slot).

---

## PHẦN A — Bố cục điều hướng (navigation layout)

### A.1 Bottom Navigation theo role

| Role | Redirect sau login | Bottom Nav |
|---|---|---|
| **SALE** (2) | `/dashboard` | Tổng quan · Phòng · Lịch · Báo cáo |
| **OWNER** (1) | `/dashboard` | Tổng quan · Phòng · Lịch · Báo cáo · **Quản lý** |
| **ADMIN** (0) | `/dashboard` | Tổng quan · Phòng · Lịch · Báo cáo · **Quản lý** |

App là **B2B — mọi màn đều cần login**. Chưa login → mọi route redirect `/login`.

### A.2 Route guard (redirect logic — `app_router.dart:resolveRedirectPath`)

- Chưa login → `/login` (trừ splash/login/register/forgot/staff-accept).
- **SALE membership chưa active** → chỉ vào được `/dashboard`, `/profile`, `/profile/help`, `/notifications`.
- **SALE** → chặn mọi route mutate dưới `/properties/*` → `/dashboard`.
- **Non-admin** → chặn `/admin/abuse-reports`, `/admin/moderation-audit`, `/admin/kyc*`, `/admin/bank-accounts*`, `/admin/role-permissions*`, form user → `/admin`.
- **iOS only** (`hidePaidUpgradeUI`) → bounce 5 route thanh toán về `/dashboard`: `/verify/select-plan`, `/verify/payment`, `/verify/approved`, `/verify/subscription-detail`, `/verify/payment-history`. **Android không bounce.**
- **OWNER `needsKyc`** → chặn mọi route mutate dưới `/properties/*` (giữ `/properties` list). Redirect theo server status: `pending`→`/verify/pending`, `rejected`→`/verify/rejected`, còn lại→`/verify/cccd-front`.

### A.3 Danh sách đầy đủ màn hình + API mỗi màn gọi

**Auth / khởi động**
| Route | Màn | API chính |
|---|---|---|
| `/splash` | Splash (chờ ≥1800ms + auth xong) | `GET /auth/profile` (verify token) |
| `/login` | Đăng nhập SĐT/email + Google | `POST /auth/login`, `POST /auth/google` |
| `/register` | Đăng ký (OWNER cố định) | `POST /auth/register` |
| `/forgot-password` | Quên MK (2 bước OTP) | `POST /auth/forgot-password`, `POST /auth/reset-password` |
| `/auth/role-picker` | Chọn role sau Google (chỉ OWNER) | `POST /auth/google` (idToken + role) |
| `/staff/accept?token=` | SALE nhận lời mời | `GET /staff/invites/verify/{token}`, `POST /staff/invites/accept` |

**Chính (bottom nav)**
| Route | Màn | API chính |
|---|---|---|
| `/dashboard` | KPI cards, banner KYC/subscription, thao tác nhanh, booking hôm nay | `GET /dashboard/stats`, `GET /auth/profile` (pull-refresh), `GET /conversations/unread-count`, `GET /notifications/unread-count` |
| `/rooms` | Danh sách phòng (cross-owner) | `GET /properties/public` |
| `/rooms/:id` | Chi tiết phòng | `GET /properties/{id}` |
| `/rooms/:id/hold` | Giữ phòng | `GET /calendar/public-grid`, `POST /bookings/hold` |
| `/calendar` | Lịch đặt phòng (grid) | `GET /calendar/grid`, `POST/DELETE /calendar/lock`, `PATCH /calendar/sold` |
| `/reports` | Báo cáo doanh thu/analytics | `GET /reports` |
| `/properties` | Quản lý cơ sở (list) | `GET /properties?includeInactive=` |

**Bookings / Front desk**
| Route | Màn | API chính |
|---|---|---|
| `/bookings` | Danh sách booking | `GET /bookings?propertyId=` |
| `/bookings/:id` | Chi tiết booking (confirm/cancel/paid/checkin, nút "Nhắn tin") | `PATCH /bookings/{id}/confirm|cancel|paid|checkin`, `PUT /bookings/{id}` |
| `/front-desk?tab=` | Lễ tân check-in/out theo ngày | `GET /bookings/calendar/{propertyId}` |

**Quản lý cơ sở (property) — OWNER/ADMIN**
| Route | Màn | API chính |
|---|---|---|
| `/properties/new` | **Tạo phòng** (form full — xem Phần D) | `POST /properties` → `POST /properties/{id}/images` |
| `/properties/:id` | Quản lý 1 phòng (hub) | `GET /properties/{id}` |
| `/properties/:id/info` | Sửa thông tin cơ bản | `PATCH /properties/{id}` |
| `/properties/:id/location` | Vị trí / bản đồ | `PATCH /properties/{id}` |
| `/properties/:id/amenities` | Tiện nghi | `PATCH /properties/{id}` |
| `/properties/:id/pricing` | Bảng giá | `PUT /properties/{id}/prices` |
| `/properties/:id/services` | Dịch vụ | `PATCH /properties/{id}` |
| `/properties/:id/rules` | Nội quy | `PATCH /properties/{id}` |
| `/properties/:id/cancellation` | Chính sách huỷ | `PATCH /properties/{id}` |
| `/properties/:id/images` | Ảnh (thêm/xoá/set cover) | `POST/DELETE /properties/{id}/images[/{imageId}]`, `PATCH …/cover` |

**Verify (KYC + subscription) — OWNER**
| Route | Màn | API chính |
|---|---|---|
| `/verify/cccd-front` · `/cccd-back` | Chụp CCCD trước/sau | `POST /kyc/upload-cccd-front|back` (multipart) |
| `/verify/selfie` | Selfie liveness | `POST /kyc/upload-selfie` |
| `/verify/select-plan` *(Android)* | Chọn gói | `GET /billing/plans` |
| `/verify/payment` *(Android)* | Thanh toán VietQR | `POST /payments/quote`, `POST /payments/initiate`, `GET /payments/{id}/status` |
| `/verify/pending` | Chờ admin duyệt (poll 8s) | `GET /kyc/submissions/{id}`, `GET /auth/profile` |
| `/verify/approved` *(Android)* | Trial active (giá + renew) | `POST /payments/renew` |
| `/verify/subscription-detail` *(Android)* | Chi tiết gói | `GET /payments/active` |
| `/verify/payment-history` *(Android)* | Lịch sử thanh toán | `GET /payments/history` |
| `/verify/rejected` | Bị từ chối (resubmit / refund) | `POST /kyc/submissions/{id}/resubmit`, `POST /payments/{id}/refund` |

**Chat / Thông báo**
| Route | Màn | API chính |
|---|---|---|
| `/conversations` | Inbox hội thoại | `GET /conversations`, `GET /conversations/unread-count` |
| `/conversations/by-booking/:bookingId` | Resolver (tạo/lấy hội thoại booking) | `POST /conversations {type:booking, bookingId}` |
| `/conversations/:id` | Thread realtime | `GET /conversations/:id/messages`, `POST …/messages`, `PATCH …/read` + Socket.IO `/chat` |
| `/notifications` · `/:id` | Danh sách + chi tiết thông báo | `GET /notifications`, `PATCH /notifications/:id/read`, `PATCH /notifications/read-all` |

**Profile (13 màn con)**
| Route | Màn | API chính |
|---|---|---|
| `/profile` | Tài khoản (hub) | — |
| `/profile/edit` | Sửa thông tin cá nhân | `PATCH /users/{id}` |
| `/profile/change-password` | Đổi MK | `POST /auth/change-password` |
| `/profile/bank-account` | **Tài khoản nhận tiền** (chờ admin duyệt) | `GET/PUT /users/me/bank` |
| `/profile/notifications` | Cài đặt thông báo | `GET/PUT /users/me/notification-preferences` |
| `/profile/help` · `/tickets` · `/tickets/:id` | Hỗ trợ / ticket | `GET/POST /support/tickets`, `POST /support/tickets/:id/reply` |
| `/profile/feedback` | Góp ý / báo lỗi | `POST /feedback`, `POST /uploads` |
| `/profile/consent` | Đồng ý GDPR/PDPA | `GET/PUT /users/me/consents` |
| `/profile/data-request` | Yêu cầu dữ liệu | `POST /users/me/data-export` |
| `/profile/delete-account` | Xoá tài khoản | `GET /users/me/deletion-status`, `POST /users/me/restore` |
| `/profile/privacy` · `/terms` | Chính sách (tĩnh) | — |
| `/update-required` | Bắt buộc cập nhật | `GET /app/version` |

**Admin (ADMIN-only)**
| Route | Màn | API chính |
|---|---|---|
| `/admin` | Hub admin | — |
| `/admin/users` · `/new` · `/:id/edit` | Quản lý user | `GET /users`, `POST/PATCH /users[/{id}]` |
| `/admin/kyc` · `/:id` | Hàng đợi duyệt KYC | `GET /admin/kyc/queue`, `POST /admin/kyc/submissions/{id}/approve|reject` |
| `/admin/bank-accounts` · `/:id` | Duyệt tài khoản nhận tiền | `GET /admin/bank-accounts`, `POST /admin/users/{userId}/bank/approve|reject` |
| `/admin/role-permissions` · `/:userId` | Phân quyền SALE | `GET/PUT /permissions/{userId}` |
| `/admin/abuse-reports` | Báo cáo vi phạm | `GET /admin/disputes`, `GET /admin/disputes/count-active` |
| `/admin/moderation-audit` | Nhật ký kiểm duyệt | `GET /admin/audit-log` |
| `/admin/owner-calendar` | Lịch tổng của owner | `GET /calendar/grid` |
| `/admin/rooms` | Quản lý phòng (dùng lại màn property) | `GET /properties` |

---

## PHẦN B — Chi tiết các luồng nghiệp vụ

### B.1 Authentication

**Login SĐT/email** — `POST /auth/login` body `{ email, password }` → nhận token → `GET /auth/profile`.
Chuẩn hoá SĐT client: bỏ khoảng trắng; nếu không chứa `@`: `+84…`→`0…`, `84xxxxxxxxx` (len≥11)→`0…`.

**Google** — `GoogleSignIn.signIn()` → `idToken` → `POST /auth/google {idToken, role?}` (+ header `X-Device-Id`).
- Nếu `data.isNewUser == true` → trả `googleProfile` → push `/auth/role-picker` → gọi lại `/auth/google` kèm `role=1` (OWNER).
- Ngược lại → có token → `GET /auth/profile`.
- `serverClientId = 492063080427-…apps.googleusercontent.com`, scopes `[email, profile]`.

**Register (OWNER)** — `POST /auth/register {name, email, password, role:1, phone?}` (+ `X-Device-Id`).
⚠️ **Sau register KHÔNG auto-login**: app xoá token vừa nhận, hiện "Tạo tài khoản thành công. Vui lòng đăng nhập." → về `/login` (buộc user nhập lại MK để xác minh).

**Refresh token (interceptor 401):**
- `POST /auth/refresh {refreshToken}` — **không gửi** access token cũ. Đọc `data.accessToken` (+ `data.refreshToken` nếu có rotation).
- Queue request khi đang refresh, replay sau khi có token mới.
- `refreshToken == null` hoặc refresh fail → clear storage + broadcast force-logout → về `/login`.
- **403 tại `/auth/refresh`** = session bị đá (thiết bị cùng loại chiếm slot) → message "Tài khoản đã đăng nhập ở thiết bị khác".

**Logout** — best-effort: `GoogleSignIn.signOut()` → `POST /auth/logout` (Bearer) → `DELETE /devices/:token` (unregister FCM, gọi TRƯỚC khi clear) → `SecureStorage.clear()`.

**Storage** — `FlutterSecureStorage` (Android: `encryptedSharedPreferences: true`). Keys: `access_token`, `refresh_token`, `user_data`, + `saved_email`/`saved_password` (remember-me, không xoá khi logout auto).

### B.2 KYC + Subscription (feature `verify`)

**State machine** (`VerifyStatus` — 7 giá trị camelCase):
```
draft → kycSubmitted → paymentPending → awaitingApproval → approved
                                                          ↘ rejected → refunded
```
> "trial / active" KHÔNG thuộc `VerifyStatus` — nó là `UserModel.subscriptionStatus` (`none|trial|active|past_due|cancelled|expired`). KYC (identity) và purchase (subscription) là 2 luồng TÁCH RỜI.

**Upload** — multipart/form-data, field `image` (+ optional `ocrResult` là JSON OCR on-device bằng ML Kit/QR; BE chỉ lưu ảnh Cloudinary + JSON, không tự OCR). Selfie kèm field `cccdFrontId`. Timeout 60s. **Không auto-reject theo faceMatchScore — admin quyết định.**

**Thanh toán VietQR (Android):**
1. `POST /payments/quote {planId, cycle, rooms}` → `PaymentQuote {totalAmount, breakdown}`. **BE là source of truth cho số tiền — FE không tự tính.**
2. `POST /payments/initiate {planId, cycle, method, rooms, totalAmount}` → `PaymentSession {sessionId, bankInfo{…, vietQrPayload, bankBin}, qrCode/qrImageBase64, expiresAt}`. `method` = `bank_transfer` (BE cũng nhận `vnpay_qr`/`card` cho record cũ). BE validate `totalAmount` ±1%, sai → 400 `amountMismatch`.
3. Poll `GET /payments/{sessionId}/status` back-off 3s→10s→30s→60s. `paid` → auto `submit KYC` + `refreshProfile()`.
- Khác: `GET /payments/active` (resume phiên 409 paymentPending), `POST /payments/renew`, `GET /payments/history`, `POST /payments/{id}/refund|cancel`.

**Gate:** `user.kycStatus` (`none|pending|approved|rejected`), `needsKyc = isOwner && !isKycVerified` (`isKycVerified = kycBypass || isKycApproved`). BE 403 `payment.kycNotApproved` chặn mua gói khi chưa duyệt.

**Auto-refresh profile** (bắt admin vừa approve) — 4 cơ chế gọi `refreshProfile()` = `GET /auth/profile`:
1. App resume (`didChangeAppLifecycleState`).
2. Pull-to-refresh dashboard.
3. Poll `/verify/pending` mỗi 8s (`GET /kyc/submissions/{id}`).
4. FCM push `subscription_*` / `bank_*` / `kyc_*`.

### B.3 Booking

Status: `0=HOLD, 1=CONFIRMED, 2=CANCELLED, 3=COMPLETED, 4=NO_SHOW`.

| Bước | API | Ghi chú |
|---|---|---|
| Hold | `POST /bookings/hold {propertyId, checkinDate, checkoutDate, customerPhone*, customerName?, depositAmount?, notes?}` | Giữ 30 phút. Client rate-limit 1 phòng/1 phút/tài khoản. Check xung đột ngày qua `GET /calendar/public-grid` trước |
| Confirm | `PATCH /bookings/{id}/confirm` | HOLD→CONFIRMED |
| Mark paid | `PATCH /bookings/{id}/paid {amount?}` | Ghi cọc; HOLD → BE tự CONFIRMED |
| Check-in | `PATCH /bookings/{id}/checkin {amount?}` | Yêu cầu CONFIRMED → thu nốt → COMPLETED |
| Cancel | `PATCH /bookings/{id}/cancel` | Track `cancelledByRole` |
| Update | `PUT /bookings/{id}` | |

### B.4 Calendar

Day status: `available, hold, booked, locked` (BE `confirmed`→`booked`).
- `GET /calendar/public-grid?startDate&endDate&propertyId?&type?` — **no auth** (check xung đột khi hold).
- `GET /calendar/grid` — Bearer; OWNER/SALE chỉ phòng của mình, ADMIN toàn bộ (BE scope theo token).
- `POST /calendar/lock {propertyId, date, status}` (`0=LOCKED,1=HOLD,2=BOOKED`), `DELETE /calendar/lock {propertyId, date}`, `PATCH /calendar/sold {propertyId, date}`.
- `type`: `0=VILLA, 1=HOMESTAY, 2=HOTEL`. Grid tự refresh 60s foreground, cache 5 phút.

### B.5 Property / Room CRUD

> **"phòng" (room) = "property"** — cùng resource `/properties`. `RoomModel` & `HomestayModel` chỉ là 2 cách map.

| Chức năng | API |
|---|---|
| List (owner-scoped) | `GET /properties?propertyId?&includeInactive?` |
| List public (cross-owner) | `GET /properties/public` |
| Detail | `GET /properties/{id}` |
| Create | `POST /properties` (xem Phần D) |
| Update | `PATCH /properties/{id}` |
| Delete | `DELETE /properties/{id}` |
| Ảnh | `POST /properties/{id}/images` (multipart, field `images`, timeout 60s), `DELETE …/{imageId}`, `PATCH …/{imageId}/cover` |
| Giá | `PUT /properties/{id}/prices` (upsert) |
| Share link (không kèm giá) | `GET /properties/share/{id}` |

### B.6 Staff invite (OWNER mời SALE qua email)

| Bước | API |
|---|---|
| Tạo lời mời | `POST /staff/invites {email}` → `{invite, inviteLink, shortCode}` |
| List / huỷ | `GET /staff/invites?status=`, `DELETE /staff/invites/{id}` |
| Verify token (public) | `GET /staff/invites/verify/{token}` |
| Accept (Google) | `POST /staff/invites/accept {token, method:'google', idToken}` |
| Accept (password) | `POST /staff/invites/accept {token, method:'password', name, password, phone?}` |
| List / xoá staff | `GET /staff?isActive=`, `DELETE /staff/{userId}` |

⚠️ Accept **chỉ trả token, không trả user** (giống login) → điều hướng SALE sang `/login`.

### B.7 Bank account (tài khoản nhận tiền của OWNER)

- `GET /users/me/bank` → `BankStatusResult`. `PUT /users/me/bank` (gửi/sửa) → status = `pending`.
- Admin: `GET /admin/bank-accounts`, `POST /admin/users/{userId}/bank/approve|reject`.
- `user.bankStatus`: `none|pending|approved|rejected`. `hasApprovedBank = bankStatus == 'approved'`.
- **Bắt buộc để tạo phòng** (gate client `ensureBankForPropertyCreate`): OWNER đã KYC nhưng `!hasApprovedBank` → chặn, hiện dialog. Đây là tài khoản để BE sinh VietQR cho **khách trả cọc qua website** — tách biệt hoàn toàn với thanh toán subscription.

### B.8 Chat realtime (Socket.IO)

**Namespace `/chat`**, URL = `baseUrl + /chat`, transports `['websocket']`, `auth:{token}`, `query:{lang:'vi'}`, reconnect delay 1000ms. Connect sau login, disconnect khi logout.

Server→Client: `connect/disconnect`, `message:new`, `message:ack`, `message:edit`, `message:delete`, `read:update`, `typing`, `presence`, `error`.
Client→Server: `message:send {conversationId, content, attachments?}`, `read {conversationId}`, `typing:start/stop {conversationId}`.

- **Token-refresh reconnect:** khi `error.code == 'tokenExpired'` → gọi REST `GET /conversations/unread-count` (để Dio interceptor refresh 401) → set `socket.auth.token` mới → reconnect.
- **Gửi tin đi qua REST** (`POST /conversations/:id/messages`), KHÔNG qua socket. Optimistic message `id: local_<micros>`, `sendStatus: sending`; REST response là source of truth (dedup với `message:new` đến trước).
- REST: `GET /conversations?role=&page=&limit=30`, `GET /conversations/:id`, `GET /conversations/:id/messages?cursor=&limit=` (cursor, oldest-first), `PATCH /conversations/:id/read`, `PATCH /conversations/messages/:messageId` (edit), `DELETE …` (xoá). Cửa sổ edit/delete 15 phút (client + BE).
- Vào chat: booking → `/conversations/by-booking/:bookingId` (resolver idempotent) · dashboard icon · admin menu · inbox tile.

### B.9 Push notification (FCM)

- **Register:** `POST /devices {fcmToken, platform:'android', deviceModel?, osVersion?, appVersion?, locale:'vi'}` (BE upsert theo token). Unregister logout: `DELETE /devices/:token`.
- **Permission KHÔNG xin lúc khởi động** — chỉ xin SAU login (`registerForUser` → `requestPermission`). `onTokenRefresh` → re-POST `/devices`. Resume → `ensureRegistered()` retry nếu token null.
- Foreground: build banner từ `notification.title/body` hoặc data; suppress nếu đang xem đúng conversation. Background: chỉ build local notification cho data-only push (có `notification` block thì OS tự hiện).
- **Deeplink** (`resolveNotificationRoute`, `pushType` từ `data.type`|`data.pushType`, id từ `data.targetId`):

| pushType | route |
|---|---|
| `chat_message` | `/conversations/<id>` |
| `kyc_approved` | `/dashboard` |
| `kyc_rejected` | `/verify/rejected` |
| `bank_approved` / `bank_rejected` | `/profile/bank-account` |
| `payment_succeeded` | `/dashboard` |
| `staff_removed` | `/login` |
| `trial_granted` / `trial_revoked` / `subscription*` | `/verify/subscription-detail` |
| `booking_*` (created/confirmed/paid/cancelled/deposit_proof/checkin_reminder/completed) | `/bookings/<id>` |
| `property_*` / `calendar_*` | `/properties/<id>` |
| admin-only / unmapped | `/notifications` (fallback) |

Side-effect foreground (im lặng): `subscription*`→refreshProfile; `chat_message`→refresh chat unread; `bank_*`→refreshProfile + invalidate bank; type khác→invalidate bell badge. Guard open-redirect: chỉ relative path, whitelist prefix; `/admin` **không** whitelist.
- 2 badge tách biệt: chat (`GET /conversations/unread-count`) và notification (`GET /notifications/unread-count`).

---

## PHẦN D — Tạo phòng: các trường & thành phần bắt buộc

Màn `/properties/new` (`PropertyAddScreen`) → `POST /properties`. Form 1 trang (ListView, section-based), submit gom toàn bộ vào 1 payload.

### D.1 Trường BẮT BUỘC (validate chặn submit)

| Field UI | Key payload | Ràng buộc |
|---|---|---|
| **Mã căn** `*` | `code` | Không rỗng, ≤ 20 ký tự (vd `C3-06`) |
| **Giá ngày thường (T2-T5)** `*` | `weekdayPrice` | Bắt buộc, **> 0** (có guard riêng vì ListView lazy build có thể bỏ qua validate) |

> Chỉ 2 field trên chặn submit. `name` (Tên hiển thị) KHÔNG bắt buộc — nếu rỗng, app tự sinh `"<type> <code>"`.

### D.2 Payload đầy đủ gửi lên `POST /properties`

```jsonc
{
  "name": "<Tên hiển thị, hoặc '<type> <code>' nếu rỗng>",  // luôn gửi
  "description": "<optional>",
  "type": 0,              // 0=Villa, 1=Homestay, 2=Khách sạn — luôn gửi
  "code": "C3-06",        // BẮT BUỘC
  "bedrooms": 2,          // luôn gửi (Studio=0..10+, bottom sheet cho ≥10)
  "bathrooms": 1,         // luôn gửi (1..10+)
  "standardGuests": 4,    // mặc định bedrooms*2 nếu bỏ trống
  "standardChildren": 0,  // mặc định 0
  "maxGuests": 4,         // mặc định bedrooms*2 nếu bỏ trống
  "amenities": ["wifi", "pool", ...],   // luôn gửi (mảng string, có thể rỗng)
  "cancellationPolicy": 0,              // 0=Linh hoạt,1=Vừa phải,2=Nghiêm ngặt — luôn gửi
  "view": "sea",          // optional: null | "sea" | "city"
  "address": "<optional>",
  "rules": "<Nội quy>\n\n--- LƯU Ý ---\n<Lưu ý bán phòng>",  // optional, ghép rules+notes
  "latitude": 20.9,       // optional (chỉ khi chọn vị trí trên map)
  "longitude": 107.0,     // optional
  "mapLink": "https://…", // optional
  "weekdayPrice": 1500000,   // BẮT BUỘC > 0
  "weekendPrice": 2000000,   // optional, nếu nhập phải > 0
  "holidayPrice": 2500000,   // optional, nếu nhập phải > 0
  "adultSurcharge": 200000,  // optional (phụ thu người lớn >11 tuổi)
  "childSurcharge": 100000   // optional (phụ thu trẻ em 7-11 tuổi)
}
```

Giá parse client: bỏ `.` và `,` (định dạng VND) → double.

### D.3 Sau khi tạo

- `POST /properties` trả `propertyId`.
- Nếu có ảnh đã chọn → `POST /properties/{id}/images` (multipart field `images`). Lỗi ảnh không rollback phòng (báo snackbar).
- BE 403 `subscription.featureLocked` → sheet platform-aware (Android: điều hướng chọn gói; iOS: liên hệ hỗ trợ, không có chữ thanh toán).

### D.4 2 cổng khoá TRƯỚC khi mở được form tạo phòng

Ở `PropertyManagementScreen`, nút "Tạo phòng" chỉ mở `/properties/new` khi qua thứ tự:
1. **KYC identity approved** (OWNER `needsKyc` → route guard đẩy sang `/verify/*`).
2. **`ensureBankForPropertyCreate`** = OWNER đã KYC + `hasApprovedBank`; nếu không → dialog "cần tài khoản nhận tiền đã duyệt".

SALE/ADMIN không qua 2 cổng này (SALE bị chặn tạo property hoàn toàn).

---

## PHẦN E — Checklist đồng bộ nhanh cho Android

- [ ] Auth: token-only + gọi `GET /auth/profile`; login body key `email`; refresh không gửi access cũ; 403 refresh = kicked.
- [ ] Header `X-Client-Type: mobile` mọi request; `X-Device-Id` ở register/google.
- [ ] `hidePaidUpgradeUI = false` trên Android → hiện đủ luồng plan/VietQR/trial/renew/refund.
- [ ] 2 cổng tạo phòng: KYC approved → bank approved.
- [ ] Tạo phòng: bắt buộc `code` + `weekdayPrice > 0`; payload theo D.2.
- [ ] Booking status int 0-4; hold giữ 30 phút; `/paid` tự confirm.
- [ ] Calendar public-grid no-auth; management grid Bearer; status int lock/hold/booked.
- [ ] Chat: Socket.IO `/chat`, gửi tin qua REST + optimistic; token-expired reconnect.
- [ ] FCM: xin permission sau login; deeplink map theo bảng B.9; 2 badge tách biệt.
- [ ] Staff accept trả token-only → về login.
- [ ] Không có role/luồng CUSTOMER trong app.
```
