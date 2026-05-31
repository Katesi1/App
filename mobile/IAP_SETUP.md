# Apple In-App Purchase — Setup Guide

Cài đặt để app iOS qua được Apple Review (Guideline 3.1.1). Bao gồm 2 phần
**ngoài codebase Flutter** mà bạn phải làm: App Store Connect và Backend.

---

## 1. App Store Connect — Tạo subscription products

Truy cập [App Store Connect](https://appstoreconnect.apple.com) → **Apps** →
chọn Halong24h → **In-App Purchases** → **Manage**.

### 1.1. Bank / Tax / Agreement

Vào **Business** → **Agreements, Tax, and Banking**. **Bắt buộc**:

- **Paid Apps Agreement** — sign, đợi Apple approve (1-3 ngày)
- **Bank Account** cho chuyển doanh thu (VND OK)
- **Tax Forms** (W-8BEN cho cá nhân/công ty Việt Nam)

Nếu thiếu bước này, Apple sẽ KHÔNG trả tiền — IAP vẫn chạy được nhưng doanh
thu giữ lại.

### 1.2. Subscription Group

Tạo 1 group duy nhất:

- **Reference Name**: `Halong24h Subscriptions`
- **Subscription Group Display Name** (hiển thị cho user): `Halong24h`

### 1.3. 10 Subscription Products

Bên trong group, tạo 10 auto-renewable subscriptions (5 tier × 2 cycle).
Product ID phải khớp **tuyệt đối** với
[lib/features/verify/data/models/plan.dart](lib/features/verify/data/models/plan.dart#L204)
(`AppleProductIds`):

| Reference Name      | Product ID                       | Duration |
|---------------------|----------------------------------|----------|
| Mini Monthly        | `com.halong24h.sub.rooms1_monthly`  | 1 month  |
| Mini Yearly         | `com.halong24h.sub.rooms1_yearly`   | 1 year   |
| Starter Monthly     | `com.halong24h.sub.rooms5_monthly`  | 1 month  |
| Starter Yearly      | `com.halong24h.sub.rooms5_yearly`   | 1 year   |
| Standard Monthly    | `com.halong24h.sub.rooms10_monthly` | 1 month  |
| Standard Yearly     | `com.halong24h.sub.rooms10_yearly`  | 1 year   |
| Pro Monthly         | `com.halong24h.sub.rooms20_monthly` | 1 month  |
| Pro Yearly          | `com.halong24h.sub.rooms20_yearly`  | 1 year   |
| Business Monthly    | `com.halong24h.sub.rooms50_monthly` | 1 month  |
| Business Yearly     | `com.halong24h.sub.rooms50_yearly`  | 1 year   |

Enterprise tier **không** có IAP — bán qua hợp đồng riêng.

Cho mỗi product:

- **Pricing**: chọn tier gần nhất với giá VND trong
  [plan.dart](lib/features/verify/data/models/plan.dart). Yearly = monthly ×
  12 × 0.80 (đã giảm 20%).
- **Family Sharing**: OFF
- **Localization** (Vietnamese + English) — bắt buộc cho App Review:
  - Display Name: ví dụ `Halong24h Starter`
  - Description: ngắn gọn, không markup
- **Introductory Offer** (tuỳ chọn): `7 days free trial`
- **Review Information**: screenshot màn payment + ghi chú test account

### 1.4. Submit for review

Mỗi product có "Ready to Submit" → submit cùng với binary IPA. **KHÔNG** submit
binary trước khi product status = "Ready to Submit" — Apple sẽ reject 3.1.1.

---

## 2. Backend — Apple receipt verification

App Flutter gọi `POST /payments/apple/verify` với body:

```json
{
  "productId": "com.halong24h.sub.rooms10_monthly",
  "purchaseId": "1000000847291847",
  "receiptData": "<base64-encoded receipt>"
}
```

Backend phải:

### 2.1. Verify receipt với Apple

Hai cách:

- **App Store Server API v2** (khuyến nghị, modern):
  - Endpoint: `GET https://api.storekit.itunes.apple.com/inApps/v1/transactions/{transactionId}`
  - Auth: JWT signed bằng StoreKit key (tạo trong ASC → Users and Access → Keys → In-App Purchase)

- **Legacy verifyReceipt** (deprecated nhưng vẫn chạy):
  - Production: `POST https://buy.itunes.apple.com/verifyReceipt`
  - Sandbox fallback: `POST https://sandbox.itunes.apple.com/verifyReceipt`
  - Apple yêu cầu **luôn thử production trước**, nếu status=21007 mới thử sandbox

### 2.2. Validate

- `bundle_id` khớp với app (`com.halong24h.mobile` hoặc tương tự)
- `product_id` khớp với client claim (chống tampering)
- `expires_date_ms` > now (subscription chưa expire)
- `original_transaction_id` chưa được map cho user khác (chống chia sẻ
  receipt)

### 2.3. Persist + Response

- Lưu `original_transaction_id` + `expires_date` vào `user.subscription`
- Set `user.kycStatus = 'approved'`, `subscriptionStatus = 'trial'` (hoặc
  `active` nếu skip trial)
- Response:

```json
{
  "data": {
    "status": "approved",
    "expiresAt": "2026-07-30T00:00:00Z",
    "originalTransactionId": "1000000847291847"
  }
}
```

### 2.4. Apple Server-to-Server Notifications V2

Đăng ký webhook URL trong ASC → App Information → App Store Server
Notifications → Production Server URL.

Apple gửi event khi:
- `DID_RENEW` — auto-renewal thành công → extend `expires_date`
- `DID_FAIL_TO_RENEW` — thẻ bị từ chối → set `subscriptionStatus = past_due`
- `CANCEL` / `REFUND` — user huỷ / Apple refund → set `cancelled`
- `EXPIRED` — hết hạn không renew → set `expired`

Endpoint verify JWT trong body (Apple ký bằng cert riêng) trước khi update DB.

### 2.5. Idempotency

Backend phải idempotent — Apple resend receipt nhiều lần (Server-to-Server +
client retry). Dùng `original_transaction_id` làm unique key.

---

## 3. Test trên thiết bị thật (sandbox)

### 3.1. Tạo Sandbox tester

ASC → Users and Access → Sandbox Testers → +

- Email: dùng email chưa có Apple ID (`testqa+halong@yourdomain.com`)
- Region: Vietnam

### 3.2. Sign in trên iPhone

Settings → Developer → Sandbox Account → sign in với sandbox tester.

⚠️ **KHÔNG** sign in vào Settings → Apple ID — sẽ làm hỏng Apple ID thật.

### 3.3. Run app + buy

```sh
flutter run --release
```

Vào màn `/verify/payment` → tap "Mua qua App Store" → Apple sheet hiện → tap
**Subscribe** → nhập sandbox password. Sandbox subscription "renew" mỗi 5
phút thay vì 1 tháng để test renewal logic nhanh.

### 3.4. Kiểm tra

- Check Xcode console: log `PurchaseStatus.purchased` xuất hiện
- Check backend log: `/payments/apple/verify` được gọi
- Check DB: `user.subscriptionStatus` = `trial` hoặc `active`
- Test "Restore Purchases" — gỡ app, cài lại, login, tap Restore → subscription
  tự kích hoạt lại

---

## 4. Submit App Store Review

### 4.1. Review notes

Trong ASC → App Review Information → Notes, ghi:

```
This app uses Apple In-App Purchase for all auto-renewable subscriptions
on iOS (Guideline 3.1.1). Subscription products are configured in App
Store Connect — see "In-App Purchases" tab.

TEST ACCOUNT:
- Email: apple-review-owner@halong24h.com
- Password: Halong24h@2026
- Role: Owner (KYC pre-approved)

PAYMENT FLOW:
1. Login → tap "Tạo phòng" on dashboard
2. Paywall modal opens → tap "Bắt đầu ngay"
3. Capture CCCD front/back/selfie (use dummy images attached)
4. Select plan "Starter Monthly" (or any)
5. Tap "Mua qua App Store" → Apple IAP sheet appears

The non-IAP payment methods (VNPay, bank transfer) are only shown on the
Android build — see `usesAppleIAP` gate in lib/core/utils/app_store_compliance.dart.
```

### 4.2. Attachment

Đính kèm 2 file CCCD test (Mặt trước + Mặt sau) trong Notes → Attachment.
Apple reviewer dùng các ảnh này nếu skip KYC step.

### 4.3. Build version

Mỗi lần submit fix mới — bump build number trong `pubspec.yaml`:

```yaml
version: 1.0.1+9   # 8 → 9
```

---

## 5. Checklist trước khi submit

- [ ] Paid Apps Agreement signed + tax form completed
- [ ] 10 subscription products tạo + status "Ready to Submit"
- [ ] Backend `/payments/apple/verify` endpoint deployed + test passed
- [ ] Backend Server-to-Server Notifications URL registered trong ASC
- [ ] Sandbox tester tạo + test purchase thành công trên thiết bị thật
- [ ] Restore Purchases test pass
- [ ] App Review notes có test account + payment flow guide
- [ ] Build number bumped (`pubspec.yaml`)
- [ ] No mention of external payment methods on iOS (VNPay, bank transfer, Pays2)
- [ ] iOS build verify gate `usesAppleIAP` đang hoạt động (search hardcode `false`)
