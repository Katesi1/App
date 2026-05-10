# App Store Connect — Reviewer Notes

> Paste vào field **App Review Information → Notes** ở App Store Connect khi
> submit. Mục đích: giải thích context cho Apple reviewer để pass review lần đầu.

---

## English (paste this verbatim)

```
Hello App Review Team,

Halong24h is a homestay/villa property management platform serving the
Vietnamese hospitality industry. The app has TWO distinct user types
documented below.

═══════════════════════════════════════════════════════════════════
USER TYPE 1: CUSTOMER (Travelers booking accommodation)
═══════════════════════════════════════════════════════════════════

CUSTOMERS use the app to search and book real-world stays at homestays
and villas in Halong Bay, Vietnam. Payment is for physical accommodation
services consumed offline at the property location.

Payment methods used:
- VNPay QR (Vietnam's #1 e-payment gateway, equivalent to Stripe)
- Bank transfer via VietQR (standard Vietnamese B2C payment)
- Credit/debit card (Visa, Mastercard, JCB) via VNPay

This payment model follows Apple Guideline 3.1.5(a) — "Goods and services
that will be consumed outside of the app must use payment methods other
than in-app purchase". Same model as Booking.com, Agoda, Airbnb,
Traveloka, and all other accommodation booking apps available on the
App Store.

═══════════════════════════════════════════════════════════════════
USER TYPE 2: OWNER (Vietnamese homestay business owners — B2B SaaS)
═══════════════════════════════════════════════════════════════════

OWNERS are real-world business owners who run homestays as their
profession. They subscribe to unlock business management tools:
- Property listing & calendar management
- Booking confirmation & cancellation workflows
- Revenue reports
- Multi-employee staff team (Owner + Sales staff)
- Real-world business operations dashboard

OWNERS are subject to mandatory KYC verification before subscription:
- Vietnamese national ID card (CCCD) front + back upload
- Selfie with liveness detection
- Manual admin approval (24-48 hours)
- Verifies real business identity, not anonymous consumer

Subscription payment via VNPay / bank transfer / credit card — same
methods as User Type 1. This falls under Apple Guideline 3.1.3(b/e) —
"Multiplatform Services" / "Enterprise Services" — same model as:
- Hostfully (vacation rental management)
- Lodgify (host platform)
- Smoobu (channel manager)
- Hospitable.com
- Slack workspace subscription
- Salesforce, QuickBooks

The subscription is NOT for digital content consumed in the app.
It unlocks tools used by business owners to operate their real-world
hospitality business in Vietnam. Apple In-App Purchase is not customary
for B2B SaaS in this market.

═══════════════════════════════════════════════════════════════════
TEST ACCOUNTS
═══════════════════════════════════════════════════════════════════

Customer (booking flow test):
  Email: <CUSTOMER_DEMO_EMAIL>
  Password: <CUSTOMER_DEMO_PASSWORD>
  Note: Pre-configured account, can search and book any property.

Owner (full management flow test):
  Email: <OWNER_DEMO_EMAIL>
  Password: <OWNER_DEMO_PASSWORD>
  Note: KYC pre-approved, trial subscription active, has 3 demo
        properties with sample bookings ready for review.

Sales staff (invited employee test):
  Email: <SALE_DEMO_EMAIL>
  Password: <SALE_DEMO_PASSWORD>
  Note: Already linked to owner account above.

═══════════════════════════════════════════════════════════════════
HOW TO TEST CRITICAL FLOWS
═══════════════════════════════════════════════════════════════════

1. CUSTOMER BOOKING FLOW (Customer account):
   - Open app → log in
   - "Tìm phòng" (Search rooms) → select dates → tap any property
   - "Đặt phòng" (Book) → review → "Xác nhận"
   - Booking appears in "My Bookings" with status HOLD
   - Payment is simulated in test environment (no real charge)

2. OWNER PROPERTY MANAGEMENT (Owner account):
   - Log in → "Bảng điều khiển" (Dashboard) shows KPIs
   - "Phòng" (Rooms) → tap property → edit info, prices, images
   - "Lịch" (Calendar) → see booking schedule
   - "Quản lý nhân viên" (Manage staff) → see invited staff

3. ACCOUNT DELETION (Apple Guideline 5.1.1(v) compliance):
   - Profile → "Xoá tài khoản" (Delete account)
   - Confirms with typing "XOA" + checkbox
   - Account fully deleted server-side, user logged out immediately

4. SIGN IN WITH APPLE (Apple Guideline 4.8 compliance):
   - On login screen, "Đăng nhập với Apple" button (iOS only)
   - Standard Apple Sign-In flow with hide-my-email support

═══════════════════════════════════════════════════════════════════
CONTACT
═══════════════════════════════════════════════════════════════════

If anything is unclear or you need additional context:
  Email: <SUPPORT_EMAIL>
  Phone: <SUPPORT_PHONE>
  Demo video walkthrough: <OPTIONAL_LOOM_OR_YOUTUBE_LINK>

Thank you for your review!

— Halong24h Team
   UPGO SOLUTIONS COMPANY LIMITED
   Vietnam
```

---

## Tiếng Việt — bản dịch tham khảo (KHÔNG paste vào App Store Connect — Apple muốn tiếng Anh)

Halong24h là nền tảng quản lý homestay/villa cho ngành du lịch Việt Nam. App
có 2 loại user:

### CUSTOMER (Khách đặt phòng)
Đặt chỗ thật ở homestay → trả VNPay/bank/card → consume offline tại property.
Theo Apple Guideline **3.1.5(a) — Real-world goods**. Giống Booking.com, Airbnb.

### OWNER (Chủ doanh nghiệp homestay — B2B SaaS)
Chủ kinh doanh thật, KYC bắt buộc, subscription để mở khoá tool quản lý
business. Theo Apple Guideline **3.1.3(b/e) — Enterprise Services**.
Giống Slack, Hostfully, Lodgify, QuickBooks.

---

## Cách điền (bạn làm)

1. Mở [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → Halong24h → trong "Prepare for Submission"
3. Cuộn xuống mục **App Review Information**
4. **Notes** field: paste toàn bộ block English ở trên
5. Replace các placeholder:
   - `<CUSTOMER_DEMO_EMAIL>` → email demo customer thật
   - `<CUSTOMER_DEMO_PASSWORD>` → password demo (KHÔNG dùng password thật của bạn)
   - `<OWNER_DEMO_EMAIL>` + `<OWNER_DEMO_PASSWORD>` → tương tự
   - `<SALE_DEMO_EMAIL>` + `<SALE_DEMO_PASSWORD>` → tương tự
   - `<SUPPORT_EMAIL>` → email support thật (vd `support@halong24h.com`)
   - `<SUPPORT_PHONE>` → số điện thoại có người nhận
   - `<OPTIONAL_LOOM_OR_YOUTUBE_LINK>` → optional, có thể bỏ
6. **Demo Account** field (separate field): paste lại Owner credentials
7. **Contact Information**: tên + email + phone

## Tips để pass review nhanh

1. **Demo account phải hoạt động đầy đủ** — Reviewer thật sự sẽ test. Nếu
   login fail, app crash, hoặc không có data demo → reject ngay.
2. **Trial subscription đã active sẵn** trên Owner account → reviewer không
   phải qua KYC + payment.
3. **Đừng để app yêu cầu permission** lúc launch (camera, location...) — chỉ
   xin khi user thực sự cần (đã ok với code hiện tại).
4. **Crash-free**: test trên simulator nhiều cấu hình trước khi submit.
5. **Privacy Policy + ToS URL**: phải public và load được. Reviewer click sẽ
   verify.

## Nếu bị reject

| Reason | Action |
|---|---|
| Guideline 3.1.1 (must use IAP) | Reply Resolution Center: cite Guideline 3.1.5(a) cho customer + 3.1.3(b/e) cho B2B owner. List comparable apps đã được approve (Booking.com, Hostfully). Đợi reviewer hỏi thêm hoặc escalate App Review Board. |
| Guideline 5.1.1 (privacy) | Verify Privacy Policy URL load. Verify in-app account deletion working. |
| Guideline 4.8 (Sign In with Apple required) | Verify Apple button hiện trên iOS. Pass test. |
| Guideline 2.1 (App completeness) | Verify demo account login working. Add demo data nếu thiếu. |
| Guideline 5.1.1(v) (account deletion) | Verify "Xoá tài khoản" flow end-to-end. |

## Pass rate thực tế

- Lần 1: 70-80% pass nếu Reviewer Notes + demo account đầy đủ
- Lần 2 sau reject: 90%+ pass nếu reply chuyên nghiệp với precedent
- Trung bình 1-3 days mỗi round review
