# App Store Submission Checklist — Halong24h

> Toàn bộ việc cần làm theo thứ tự để submit App Store thành công.
>
> **Ước tính tổng**: 5-10 ngày work, 1-3 ngày Apple review.

---

## Phase 1 — Pre-submit prep (3-5 ngày)

### 1.1 Apple Developer & Bundle ID
- [x] Apple Developer Program account (UPGO SOLUTIONS, Team ID `9QD89UUC3L`)
- [x] App ID `com.halongtravel.halong24h` registered với capabilities:
  - [x] Push Notifications
  - [x] Sign In with Apple
  - [x] Associated Domains (cho universal link sau)
- [x] APNs Auth Key uploaded vào Firebase Console

### 1.2 Code & Build
- [x] All `flutter analyze` pass
- [x] `flutter test` pass (unit tests)
- [x] iOS build với Release config + signing đúng team
- [x] `RunnerRelease.entitlements` có `aps-environment=production`
- [x] `PrivacyInfo.xcprivacy` declared 8 data type + 4 Required Reasons
- [x] Sign In with Apple button hiện trên iOS login screen
- [x] Self-delete account flow working
- [x] Force-update flow integrated

### 1.3 Backend dependencies
- [x] BE deploy `/auth/apple` endpoint
- [x] BE deploy `DELETE /users/me` endpoint
- [x] BE deploy `GET /app/version` endpoint
- [x] BE deploy `/devices` endpoint cho push notification
- [x] BE deploy `/staff/*` endpoints (invite flow)
- [x] BE wire 9 push notification types
- [x] **TEST**: Tất cả endpoint live trên `https://api.halong24h.com`

### 1.4 Legal & content

**✅ Live trên GitHub Pages** (deployed 2026-05-10):

- [x] **Privacy Policy**: `https://katesi1.github.io/halong24h-legal/privacy/`
- [x] **Terms of Service**: `https://katesi1.github.io/halong24h-legal/terms/`
- [x] **Landing**: `https://katesi1.github.io/halong24h-legal/`
- [x] Email support: `halong24h.team@gmail.com`
- [x] Phone support: `0327672120` (số ĐKKD UPGO Solutions)
- [x] Repo source: https://github.com/Katesi1/halong24h-legal

### 1.5 Demo accounts (BE setup)
Apple reviewer SẼ test login. Các account này phải hoạt động đầy đủ:

- [ ] **Customer demo**:
  - Email: `apple-review-customer@halong24h.com` (hoặc tương tự)
  - Password: dễ nhớ nhưng đủ mạnh (vd `Halong24h@2026`)
  - Pre-condition: account active, có thể search + book
- [ ] **Owner demo**:
  - Email: `apple-review-owner@halong24h.com`
  - Password: `Halong24h@2026`
  - Pre-condition: KYC pre-approved, trial active, có 3 demo properties với
    images đầy đủ + 5 demo bookings (mix HOLD/CONFIRMED/COMPLETED)
- [ ] **Sale demo**:
  - Email: `apple-review-sale@halong24h.com`
  - Password: `Halong24h@2026`
  - Pre-condition: linked với Owner demo trên, isSaleMembershipActive=true

---

## Phase 2 — App Store Connect setup (1-2 ngày)

### 2.1 Tạo App Listing
- [ ] [App Store Connect](https://appstoreconnect.apple.com) → My Apps → +
- [ ] Bundle ID: `com.halongtravel.halong24h`
- [ ] Name: `Halong24h`
- [ ] Primary Language: Vietnamese (Vietnam) hoặc English (Vietnam)
- [ ] SKU: `halong24h-ios-v1` (nội bộ)

### 2.2 App Information tab
- [ ] **Subtitle** (30 chars): "Đặt phòng homestay & quản lý"
- [ ] **Category**:
  - Primary: **Travel**
  - Secondary: **Business** (cho Owner side)
- [ ] **Content Rights**: tick "Does not contain third-party content"
- [ ] **Age Rating**: 4+ (or 12+ nếu có user-generated content review)

### 2.3 Pricing & Availability
- [ ] Price: **Free**
- [ ] Availability: Việt Nam first, có thể add country sau
- [ ] **In-App Purchases**: KHÔNG có (vì dùng VNPay)

### 2.4 App Privacy
- [ ] Privacy Policy URL: `https://katesi1.github.io/halong24h-legal/privacy/`
- [ ] Khai báo data collected (khớp `PrivacyInfo.xcprivacy`):
  - Contact Info: Email, Name, Phone (linked, not tracking)
  - Identifiers: User ID, Device ID (linked, not tracking)
  - Photos: User Content (CCCD + property images, linked)
  - Diagnostics: Crash Data (not linked, not tracking)
- [ ] "Data Used to Track You": **No**

### 2.5 Version Information
- [ ] **Version Number**: 1.0.0 (hoặc match pubspec.yaml)
- [ ] **What's New**: "Phiên bản đầu tiên — Đặt phòng homestay & quản lý kinh doanh"
- [ ] **Promotional Text** (170 chars): tagline marketing
- [ ] **Description** (4000 chars):
  ```
  Halong24h — Nền tảng quản lý & đặt phòng homestay tại Hạ Long.

  CHO KHÁCH DU LỊCH:
  • Tìm homestay/villa tại Hạ Long với view biển, view thành phố
  • Đặt phòng tức thời với VNPay, chuyển khoản, thẻ tín dụng
  • Xem lịch trống, giá theo ngày
  • Đánh giá sau check-in
  • Quản lý booking trong app

  CHO CHỦ HOMESTAY:
  • Đăng phòng, quản lý lịch booking
  • Báo cáo doanh thu chi tiết
  • Mời nhân viên hỗ trợ qua email
  • Xác minh CCCD bảo mật
  • Subscription trial 7 ngày miễn phí

  Hỗ trợ thanh toán:
  • VNPay (quét QR)
  • Chuyển khoản ngân hàng
  • Visa, Mastercard, JCB

  Liên hệ: support@halong24h.com
  ```
- [ ] **Keywords** (100 chars, comma-separated):
  ```
  homestay,halong,booking,đặt phòng,villa,du lịch,quản lý,hạ long
  ```
- [ ] **Support URL**: `https://katesi1.github.io/halong24h-legal/` (hoặc `mailto:halong24h.team@gmail.com`)
- [ ] **Marketing URL** (optional): `https://halong24h.com`
- [ ] **Copyright**: `© 2026 UPGO SOLUTIONS COMPANY LIMITED`

### 2.6 Screenshots
Required sizes (iOS 17+):
- [ ] **6.7"** (iPhone 15 Pro Max) — 1290x2796
- [ ] **6.5"** (iPhone 14 Plus) — 1284x2778
- [ ] **iPad 12.9"** (optional nếu support iPad) — 2048x2732

Recommended 5-8 screenshots showcasing:
1. Login screen (clean, hero shot)
2. Customer home — search homestays
3. Property detail — gallery + book
4. Booking confirmation — clear CTA
5. Owner dashboard — KPI + quick actions
6. Property management screen
7. Calendar view
8. Profile / settings

⚠️ **KHÔNG** show subscription paywall trong screenshot (giảm risk reviewer
focus vào subscription).

### 2.7 App Review Information
- [ ] **Sign-in required**: Yes
- [ ] **Demo Account**:
  - Email: `apple-review-owner@halong24h.com`
  - Password: `Halong24h@2026`
- [ ] **Notes**: paste toàn bộ từ [APPSTORE_REVIEWER_NOTES.md](APPSTORE_REVIEWER_NOTES.md)
- [ ] **Contact Information**:
  - First name, last name, phone, email người giữ liên lạc với Apple

### 2.8 Build upload
- [ ] Open `ios/Runner.xcworkspace` trong Xcode
- [ ] Select target: **Any iOS Device (arm64)**
- [ ] Update version + build number trong `pubspec.yaml` nếu cần
- [ ] Product → Archive
- [ ] Wait ~5-10 phút build complete
- [ ] Trong Organizer window: bấm "Distribute App"
- [ ] Chọn **App Store Connect** → Upload
- [ ] Đợi processing (15-30 phút)
- [ ] Trong App Store Connect → Build → select build vừa upload

### 2.9 Submit for Review
- [ ] Verify tất cả field đã fill
- [ ] **Submit for Review**
- [ ] Choose: "Manually release this version" (recommend) hoặc "Automatic"

---

## Phase 3 — Apple Review (1-7 ngày)

### 3.1 Trong khi đợi review
- [ ] Monitor email từ Apple (`developer-noreply@apple.com`)
- [ ] Không thay đổi backend production trong lúc review
- [ ] Demo accounts phải vẫn hoạt động

### 3.2 Nếu pass review
- [ ] Email thông báo "Ready for Sale"
- [ ] Manually release: App Store Connect → Pricing → Release
- [ ] App live trên App Store sau 2-24 giờ

### 3.3 Nếu bị reject
| Reject reason | Action |
|---|---|
| **Guideline 3.1.1** (must use IAP) | Reply Resolution Center với cite Guideline 3.1.5(a) cho customer + 3.1.3(b/e) cho owner B2B. List comparable apps. Provide Vietnamese B2B SaaS context. |
| **Guideline 5.1.1** (privacy) | Verify Privacy Policy URL load. Re-test in-app delete account. |
| **Guideline 4.8** (Sign In with Apple) | Verify button hiện trên iOS login. Test pass. |
| **Guideline 2.1** (App completeness) | Demo account login fail? Fix data, re-submit. |
| **Guideline 5.1.1(v)** (account deletion) | Verify "Xoá tài khoản" flow end-to-end. |
| **Guideline 2.5.6** (HTML5/wrapper) | KHÔNG áp dụng — Flutter native build. |

Resolution Center reply template:
```
Hello Apple Review Team,

Thank you for your feedback. We respectfully request reconsideration.

[CITE GUIDELINE]

[EXPLAIN WHY APPLIES]

[LIST COMPARABLE APPS]

[ATTACH SCREENSHOT IF NEEDED]

We are committed to compliance with App Store guidelines and look
forward to your further review.

Best regards,
Halong24h Team
```

### 3.4 Escalation (lần reject thứ 2-3)
- [App Review Board appeal](https://developer.apple.com/contact/app-store/?topic=expedite)
- Provide thêm bằng chứng: video demo, list precedent apps

---

## Phase 4 — Post-launch (ongoing)

- [ ] Monitor Crashlytics dashboard daily
- [ ] Monitor App Store reviews + reply
- [ ] Track FCM delivery rate
- [ ] Update version mỗi 2-4 tuần (Apple recommends fresh updates)
- [ ] Iterate dựa trên user feedback

---

## Quick reference

| Tài liệu | Mục đích |
|---|---|
| [APPSTORE_REVIEWER_NOTES.md](APPSTORE_REVIEWER_NOTES.md) | Paste vào App Review Information → Notes |
| [legal/PRIVACY_POLICY.md](legal/PRIVACY_POLICY.md) | Web team host tại `/privacy` |
| [legal/TERMS_OF_SERVICE.md](legal/TERMS_OF_SERVICE.md) | Web team host tại `/terms` |
| [API.md](API.md) | BE reference |
| [APP_SPEC.md](APP_SPEC.md) | App spec for BE |
| [CLAUDE.md](CLAUDE.md) | Project rules |

---

## Estimated timeline

```
Day 1-2:  Web team host Privacy Policy + Terms
Day 3:    BE setup demo accounts + verify endpoints live
Day 4:    Bạn test toàn flow trên iPhone thật
Day 5:    Bạn upload screenshots + fill App Store Connect
Day 6:    Archive + upload build qua Xcode
Day 7:    Submit for Review
Day 8-10: Apple Review (1-3 days typical)
Day 11:   Pass review → release → app LIVE 🎉

Total: ~11 days realistic, có thể nhanh hơn nếu Apple review ngay.
```

---

## Sau khi app LIVE

1. **Update Firebase Console** → APNs key `Sandbox & Production` đã đúng (đã làm)
2. **Update App Store URL** vào BE `/app/version` → `storeUrl.ios`
3. **Notify users** qua web/social media
4. **Plan next version** — bug fixes + new features

→ Chúc may mắn! 🚀
