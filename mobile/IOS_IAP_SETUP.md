# iOS In-App Purchase Setup — Halong24h

Hướng dẫn 3 phần để hoàn tất tích hợp Apple IAP và submit lại App Store:

1. **App Store Connect** — bạn làm thủ công (tài khoản team)
2. **Backend** — backend team thêm endpoint receipt verification + webhook
3. **Flutter iOS** — đã code xong (xem PR)

---

## 1. App Store Connect (~30-45 phút)

### 1.1. Paid Apps Agreement + Banking + Tax

App Store Connect → **Agreements, Tax, and Banking**:

- [ ] **Paid Apps Agreement** — Active (Effective). Nếu chưa, click "Request" và điền chính thức. Subscription products sẽ KHÔNG hiển thị trong StoreKit nếu agreement chưa Active.
- [ ] **Banking Information** — điền tài khoản nhận tiền doanh thu.
- [ ] **Tax Forms** — điền W-8BEN-E (cho công ty VN không phải US tax resident).

### 1.2. Subscription Group

App Store Connect → app **Halong24h** → **Features** → **In-App Purchases** → **Subscription Groups**:

- [ ] Tạo 1 subscription group: **Halong24h Subscriptions** (Reference name: `halong24h_main`)
  - App Store Localization (VN): tên hiển thị "Đăng ký Halong24h"

### 1.3. Tạo 10 Auto-Renewable Subscription Products

Trong group ở trên, tạo từng sản phẩm với Product ID **chính xác** như dưới (frontend đã map cứng):

| Tier | Cycle | Product ID | Duration | Suggested Price Tier (VND) |
|---|---|---|---|---|
| Mini | Monthly | `com.halong24h.sub.rooms1_monthly` | 1 Month | 199.000 đ (~Tier 9) |
| Mini | Yearly | `com.halong24h.sub.rooms1_yearly` | 1 Year | 1.910.000 đ (~Tier 87) |
| Starter | Monthly | `com.halong24h.sub.rooms5_monthly` | 1 Month | 599.000 đ (~Tier 27) |
| Starter | Yearly | `com.halong24h.sub.rooms5_yearly` | 1 Year | 5.750.000 đ (~Tier 260) |
| Standard | Monthly | `com.halong24h.sub.rooms10_monthly` | 1 Month | 999.000 đ (~Tier 46) |
| Standard | Yearly | `com.halong24h.sub.rooms10_yearly` | 1 Year | 9.590.000 đ (~Tier 433) |
| Pro | Monthly | `com.halong24h.sub.rooms20_monthly` | 1 Month | 1.799.000 đ (~Tier 82) |
| Pro | Yearly | `com.halong24h.sub.rooms20_yearly` | 1 Year | 17.270.000 đ (~Tier 780) |
| Business | Monthly | `com.halong24h.sub.rooms50_monthly` | 1 Month | 3.999.000 đ (~Tier 183) |
| Business | Yearly | `com.halong24h.sub.rooms50_yearly` | 1 Year | 38.390.000 đ (~Tier 1740) |

**Enterprise tier KHÔNG có IAP** — flow Enterprise vẫn dùng "Contact sales" qua web.

Cho mỗi product:
- [ ] **Reference Name** — internal, vd "Starter Monthly"
- [ ] **Subscription Duration** — 1 Month / 1 Year
- [ ] **Pricing** — chọn tier gần nhất với VND giá hiện tại. Có thể tùy chỉnh per-country sau.
- [ ] **Localizations** (VN):
  - Display Name: "Starter (5 phòng) - Hàng tháng"
  - Description: bullet features từ catalog (xem `lib/features/verify/data/models/plan.dart#kDefaultPlans`)
- [ ] **Family Sharing** — OFF (B2B)
- [ ] **Introductory Offer** (free trial 7 ngày) — chọn "Free", duration 1 Week, eligibility "New Subscribers"
- [ ] **App Store Promotion** — OFF (không cho promote ngoài app)
- [ ] **Review Information** — screenshot màn payment + 1-2 dòng mô tả "User upgrades to manage more rooms"
- [ ] **Submit for Review** — submit cùng app build

### 1.4. Sandbox Test Accounts

App Store Connect → **Users and Access** → **Sandbox** → **Testers**:

- [ ] Tạo 2-3 sandbox tester (email phải khác Apple ID thật, kiểu `qa+sandbox1@halong24h.com`)
- [ ] Trên iPhone test: Settings → App Store → Sandbox Account → sign in bằng sandbox account
- [ ] Khi build app debug và bấm "Mua qua App Store", Apple sẽ dùng sandbox account → KHÔNG tính tiền thật

### 1.5. App Privacy + Review Notes

App Store Connect → app **Halong24h** → **App Privacy**:

- [ ] **Data Collected**: thêm "Purchase History" → Linked to user (cho phép tracking subscription)
- [ ] **Subscription Terms / EULA** — bắt buộc cho auto-renewable subscriptions. Phải có link tới Terms + Privacy Policy với điều khoản subscription chuẩn Apple (auto-renewal, cancellation, refund). Có thể dùng template trong [Apple's standard EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/).

**App Review Notes** (mục Submission cho version 1.0.1):

```
ABOUT THIS APP

Halong24h is a B2B SaaS for homestay/villa owners in Vietnam.
Owners can register an account, then subscribe to a plan that
matches their property size (1-50 rooms).

SUBSCRIPTION DETAILS

- All subscriptions are sold via Apple In-App Purchase (StoreKit).
- 10 auto-renewable subscriptions across 5 tiers × 2 cycles
  (monthly / yearly).
- 7-day free trial as introductory offer for new subscribers.
- Subscriptions can be managed and cancelled in Settings >
  Apple ID > Subscriptions.
- "Restore Purchases" button is on the Payment screen and on
  Settings > Subscription Detail.

TEST ACCOUNT

Email: apple-review-owner@halong24h.com
Password: Halong24h@2026

Note: reviewer should sign in with the sandbox tester provided
via TestFlight invitation to test the purchase flow without
charging a real card.

NO EXTERNAL PAYMENT

This iOS build does NOT offer VNPay, bank transfer, or any
non-IAP payment method. Those methods are Android-only.
```

---

## 2. Backend (~1-2 ngày cho backend team)

### 2.1. Endpoint: `POST /payments/apple/verify`

Đã được khai báo trong `lib/core/constants/api_constants.dart#paymentAppleVerify`.

**Request:**

```json
{
  "productId": "com.halong24h.sub.rooms5_monthly",
  "purchaseId": "1000000123456789",
  "receiptData": "<base64-encoded receipt blob>"
}
```

**Backend phải:**

1. Gọi Apple `verifyReceipt`:
   - Production URL: `https://buy.itunes.apple.com/verifyReceipt`
   - Sandbox URL: `https://sandbox.itunes.apple.com/verifyReceipt`
   - Always try Production first; nếu trả status `21007` → retry với Sandbox URL.
   - Body: `{ "receipt-data": "<base64>", "password": "<shared secret từ ASC>", "exclude-old-transactions": true }`
2. Verify:
   - `receipt.bundle_id == "com.halong24h.app"` (hoặc bundle ID thật)
   - Latest receipt info có `product_id == request.productId`
   - `expires_date_ms > now()` (subscription còn hạn) HOẶC nằm trong grace period
3. Idempotency:
   - Index `original_transaction_id` UNIQUE — request lặp lại không tạo subscription mới
4. Cập nhật user:
   - `subscriptionPlanId` ← derive từ `product_id` map ngược
   - `subscriptionStatus` ← `trial` / `active` / `past_due` (theo `is_in_trial_period` + `expires_date_ms`)
   - `trialEndsAt` / `currentPeriodEndsAt` ← `expires_date_ms`
5. Trả về:

```json
{
  "success": true,
  "data": {
    "status": "approved",
    "expiresAt": "2026-06-30T00:00:00Z",
    "originalTransactionId": "1000000123456789"
  }
}
```

### 2.2. App Store Server Notifications V2 (webhook)

Đăng ký webhook URL trong App Store Connect → **App Information** → **App Store Server Notifications**:

- URL: `https://api.halong24h.com/webhooks/apple/notifications`
- Version: V2 (JWT signed payload)

Backend phải xử lý notification types:

| Type | Action |
|---|---|
| `SUBSCRIBED` | Kích hoạt subscription |
| `DID_RENEW` | Cập nhật `currentPeriodEndsAt` |
| `DID_FAIL_TO_RENEW` | `subscriptionStatus = past_due` (Apple sẽ retry 60 ngày) |
| `EXPIRED` | `subscriptionStatus = expired`, khoá tính năng |
| `GRACE_PERIOD_EXPIRED` | Apple đã ngừng retry — chuyển `expired` |
| `REFUND` | Hủy subscription, tag user `was_refunded = true` |
| `DID_CHANGE_RENEWAL_STATUS` | User bật/tắt auto-renew từ Settings |
| `PRICE_INCREASE` | User đã consent / chưa — gắn flag |

Validate JWS signature bằng Apple root CA — KHÔNG tin payload nếu signature invalid.

### 2.3. Shared Secret

App Store Connect → app → **App-Specific Shared Secret** → Generate. Lưu vào backend env var `APPLE_IAP_SHARED_SECRET`. Cần thiết cho `verifyReceipt` call.

---

## 3. Flutter iOS (đã xong trong PR này)

### 3.1. Files mới / thay đổi

```
lib/core/utils/app_store_compliance.dart           # usesAppleIAP flag + Apple URL
lib/features/verify/data/services/iap_service.dart # IAPService + provider
lib/features/verify/data/models/plan.dart          # AppleProductIds map
lib/features/verify/data/repositories/
  verify_repository.dart                            # verifyAppleReceipt method
  verify_repository_impl.dart                       # impl gọi /payments/apple/verify
lib/features/verify/controllers/
  verify_flow_controller.dart                       # queryAppleProducts / buyApple /
                                                    # restore / listenAppleStoreKit
lib/features/verify/views/
  payment_screen.dart                               # iOS branch: Apple IAP only
  subscription_detail_screen.dart                   # iOS: Apple mgmt + Restore
pubspec.yaml                                        # + in_app_purchase ^3.2.0
```

### 3.2. Acceptance checks trước khi build IPA

```bash
flutter pub get
flutter analyze   # phải clean
flutter build ios --release --no-codesign  # smoke
```

### 3.3. Cấu hình iOS native

Xcode → **Runner** target → **Signing & Capabilities**:

- [ ] Add capability **In-App Purchase**
- [ ] Bundle ID phải khớp với ASC app + product ID prefix `com.halong24h.sub.*`

Nếu Bundle ID khác `com.halong24h`, sửa `_prefix` trong `lib/features/verify/data/models/plan.dart#AppleProductIds` cho khớp.

---

## 4. Test trước khi submit

Yêu cầu: build trên thiết bị thật (simulator KHÔNG run được StoreKit production flow — chỉ run được StoreKit Configuration File trong Xcode).

### Tùy chọn A — Sandbox testing (production-like)

1. Build IPA bằng release config (TestFlight hoặc Ad Hoc)
2. Cài lên iPhone test
3. Settings → App Store → Sandbox Account → sign in bằng sandbox tester từ ASC
4. Mở app → đăng ký account OWNER → đi tới payment screen
5. Tap "Mua qua App Store" → Apple modal hiện → confirm purchase
6. Verify:
   - Backend nhận `/payments/apple/verify` call thành công
   - User được navigate sang `/verify/pending`
   - `user.subscriptionStatus = 'trial'` (do introductory offer 7-day free)
7. Test Restore:
   - Uninstall app → cài lại
   - Login → tới Subscription Detail → tap "Khôi phục đăng ký đã mua"
   - Verify subscription state được restore

### Tùy chọn B — StoreKit Configuration File (offline, fast)

Cho local dev trên simulator:

1. Xcode → File → New → File → StoreKit Configuration File → name `halong24h.storekit`
2. Add 10 products khớp Product IDs ở section 1.3
3. Edit scheme → Run → Options → StoreKit Configuration → chọn `halong24h.storekit`
4. `flutter run -d ios-simulator` → purchase chạy local, không cần backend verify (backend sẽ reject receipt sandbox khi chưa hook vào sandbox URL — đây là expected)

---

## 5. Common Apple Review pitfalls

| Pitfall | Fix |
|---|---|
| App mentions "external payment" / "halong24h.com to subscribe" | Đã ẩn — verify text trên các màn payment + subscription detail |
| "Restore Purchases" không reachable từ purchase screen | Đã có nút "Khôi phục đăng ký đã mua" trên payment_screen + subscription_detail_screen |
| Price hiển thị mismatch (VND khác Apple tier) | iOS UI chỉ show `productDetails.price` (từ Apple), không show VND fixed price |
| EULA mention auto-renew không đúng template | Dùng [Apple standard EULA](https://www.apple.com/legal/internet-services/itunes/dev/stdeula/) hoặc clone + customize |
| Sandbox flow chưa test | BẮT BUỘC test bằng sandbox tester trước khi submit |
| Backend chưa verify receipt → app crash sau purchase | Test `/payments/apple/verify` với mock receipt trước; nếu chưa ready, app sẽ show error sau Apple sheet đóng (user bị charge nhưng app không kích hoạt) |

---

## 6. Câu hỏi sau khi submit

- Apple review thường mất 24-48h cho subscription apps lần đầu
- Nếu reject lần nữa với 3.1.1 → có thể do EULA missing → fix EULA + resubmit
- Nếu reject với 3.1.2 → subscription metadata chưa đầy đủ → bổ sung Localization
- Nếu reject với 2.1 → metadata + screenshot phải match thực tế trong app

Liên hệ Apple Developer Support qua App Store Connect message nếu cần escalate.
