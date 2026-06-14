# Halong24h — Chính sách bảo mật / Privacy Policy

> **Version**: 1.3 — 2026-06-12
>
> **Áp dụng cho**: Mobile app Halong24h (iOS + Android) + dịch vụ web
> tại `halong24h.com`. App mobile là công cụ **quản lý phòng** cho chủ
> homestay, doanh nghiệp và cá nhân có phòng cho thuê (không bán gói/đăng ký
> trả phí trong app).
>
> **Đơn vị vận hành**: UPGO SOLUTIONS COMPANY LIMITED, Việt Nam.
>
> **Hành động cho team Web/BE**: Host file này tại
> `https://halong24h.com/privacy` (HTML rendered từ markdown). URL này
> phải public và load được — App Store reviewer sẽ verify.

---

## English version (paste below Vietnamese, Apple cần cả 2)

> **For non-Vietnamese users**: An English version follows after the
> Vietnamese version. This is the official policy in both languages.

---

## 1. Giới thiệu

UPGO SOLUTIONS COMPANY LIMITED ("chúng tôi", "Halong24h") tôn trọng quyền
riêng tư của bạn. Chính sách này mô tả cách chúng tôi thu thập, sử dụng,
lưu trữ và chia sẻ dữ liệu cá nhân khi bạn dùng app/web Halong24h.

Bằng cách dùng dịch vụ, bạn đồng ý với các điều khoản dưới đây.

## 2. Dữ liệu chúng tôi thu thập

### 2.1 Bạn cung cấp trực tiếp
- **Thông tin tài khoản**: tên, email, số điện thoại, mật khẩu (đã hash)
- **Avatar**: URL ảnh từ Google/Apple Sign-In hoặc bạn tự upload
- **Giới tính, ngày sinh** (tùy chọn)
- **Định danh CCCD** (chỉ với chủ homestay):
  - Ảnh CCCD mặt trước/sau
  - Ảnh selfie
  - Số CCCD trích xuất qua OCR
  - Tên, ngày sinh, địa chỉ thường trú từ CCCD
- **Thông tin booking**: tên khách, SĐT khách, số người, ngày check-in/out, ghi chú
- **Đánh giá**: nội dung review, ảnh, điểm đánh giá

### 2.2 Tự động thu thập
- **Device ID**: định danh thiết bị duy nhất (Apple `identifierForVendor`,
  Android `id`) — dùng để chặn spam đăng ký
- **Thông tin thiết bị**: model, OS version, app version, locale
- **FCM token**: để gửi push notification (chỉ device, không identify cá nhân)
- **IP address**: trong 24h cho mục đích chống spam, sau đó xoá
- **Crash logs**: thông tin lỗi app crash (qua Firebase Crashlytics) — không
  chứa nội dung user nhập

### 2.3 Từ bên thứ ba
- **Google Sign-In**: email, tên, avatar (nếu bạn login Google)
- **Apple Sign-In**: email, tên (chỉ lần đầu authorize)

### 2.4 Dữ liệu KHÔNG thu thập
- ❌ Không thu thập location/GPS của bạn
- ❌ Không thu thập danh bạ điện thoại
- ❌ Không thu thập tin nhắn SMS/email
- ❌ Không tracking quảng cáo (no IDFA)
- ❌ Không bán dữ liệu cho bên thứ ba

### 2.5 Dữ liệu khuôn mặt (selfie) — Face data

Chúng tôi thu thập **một ảnh selfie** trong bước xác minh danh tính (KYC, chỉ áp
dụng cho chủ homestay) để nhân viên đối chiếu thủ công với ảnh trên CCCD.

- **Thu thập gì**: 1 ảnh selfie. KHÔNG quay video.
- **Mục đích**: KYC chỉ phục vụ **an toàn, uy tín và trách nhiệm** — quản trị
  viên kiểm duyệt trước khi chủ phòng được đăng phòng và thêm nhân viên, nhằm
  tránh đăng tin tràn lan, giả mạo ảnh hưởng hiệu suất hệ thống. Chúng tôi cam
  kết không dùng dữ liệu KYC vào bất kỳ mục đích trái phép nào.
- **KHÔNG nhận diện khuôn mặt tự động (face recognition)** để xác định danh tính.
- **KHÔNG so khớp khuôn mặt tự động với CCCD** — việc đối chiếu do nhân viên
  thực hiện thủ công. App không tạo hay lưu template / faceprint / vector
  sinh trắc khuôn mặt nào.
- **KHÔNG dùng cho**: quảng cáo, hồ sơ hành vi, theo dõi, mở khoá thiết bị
  (đây KHÔNG phải Face ID).
- **Lưu trữ**: trên Cloudinary (qua kết nối bảo mật). Hệ thống không lưu trữ
  cho mục đích riêng.
- **Chia sẻ**: KHÔNG bán, KHÔNG chia sẻ cho bên thứ ba để nhận diện/đối chiếu
  khuôn mặt. Chỉ tiết lộ cho cơ quan nhà nước khi có yêu cầu hợp pháp.
- **Thời gian lưu**: giữ cho đến khi bạn xoá tài khoản. Khi xoá tài khoản, toàn
  bộ dữ liệu KYC — bao gồm ảnh khuôn mặt — sẽ bị xoá.

> *Bản dịch tiếng Anh dùng để đối chiếu với Apple App Review:* "We collect one
> selfie image during identity verification. The app does NOT perform automated
> face recognition and does NOT perform automated face matching against the
> national ID (CCCD) — comparison is done manually by staff, and no face
> template, faceprint, or biometric embedding is created or stored. The selfie
> is stored on Cloudinary over a secure connection, is never sold or shared with
> any third party for face recognition/matching, and is retained until you
> delete your account; on account deletion, all KYC data including the face
> image is deleted."

## 3. Mục đích sử dụng

| Dữ liệu | Mục đích |
|---|---|
| Tài khoản, mật khẩu | Cho phép đăng nhập, xác thực |
| Email | Gửi xác nhận, mật khẩu reset, lời mời nhân viên |
| SĐT | Xác nhận booking, liên hệ khẩn cấp khi check-in |
| Ảnh CCCD + selfie | KYC theo Nghị định 13/2023/NĐ-CP; bảo đảm an toàn, uy tín, trách nhiệm; admin kiểm duyệt trước khi chủ phòng được đăng phòng + thêm nhân viên |
| Thông tin booking | Vận hành dịch vụ đặt phòng |
| Device ID + IP | Chống spam đăng ký (3 acc/24h/device, 10/24h/IP) |
| FCM token | Gửi push notification về booking và hệ thống |
| Crash logs | Phát hiện và sửa lỗi app |
| Reviews | Hiển thị công khai cho user khác xem |

## 4. Lưu trữ dữ liệu

- **Server location**: Việt Nam (PostgreSQL hosted in VN data center)
- **Mã hoá**:
  - Mật khẩu: bcrypt hash, KHÔNG lưu plaintext
  - Token: JWT hash (refresh token), HTTPS-only transport
  - Hình ảnh (ảnh phòng, ảnh CCCD + selfie KYC): lưu trên Cloudinary qua kết nối bảo mật
- **Thời gian lưu**:
  - Tài khoản active: lưu vô thời hạn
  - Tài khoản đã xoá: soft-delete 30 ngày, sau đó hard-delete
  - Booking history: 5 năm (theo quy định kế toán)
  - KYC images (CCCD + selfie): giữ đến khi xoá tài khoản; khi xoá tài khoản sẽ bị xoá
  - Crash logs: 90 ngày
  - Device ID + IP anti-spam: 24 giờ

## 5. Chia sẻ dữ liệu

Chúng tôi KHÔNG bán dữ liệu. Chia sẻ chỉ trong các trường hợp sau:

| Bên nhận | Dữ liệu | Mục đích |
|---|---|---|
| **Google Cloud Platform** | Email, name, avatar | Google Sign-In OAuth |
| **Apple** | Email (có thể privateRelay), name | Sign In with Apple |
| **Firebase (Google)** | FCM token, device ID, crash logs | Push notification + crash reporting |
| **Cloudinary** | Ảnh phòng, ảnh CCCD + selfie (KYC) | Lưu trữ ảnh + CDN (qua kết nối bảo mật) |
| **Cơ quan nhà nước** | Toàn bộ data nếu có yêu cầu hợp pháp | Tuân thủ pháp luật VN |
| **OWNER (chủ homestay)** | Tên + SĐT + số người booking | Quản lý đặt phòng |
| **Nhân viên SALE của OWNER** | Tương tự OWNER, scope theo `ownerId` | Hỗ trợ vận hành |

## 6. Quyền của bạn

Theo Nghị định 13/2023/NĐ-CP và GDPR (cho user EU), bạn có các quyền:

- ✅ **Truy cập**: yêu cầu bản sao toàn bộ dữ liệu cá nhân của bạn
- ✅ **Sửa đổi**: chỉnh sửa thông tin profile bất kỳ lúc nào trong app
- ✅ **Xoá**: tự xoá tài khoản trong app (Profile → Xoá tài khoản) — toàn
  bộ data sẽ bị soft-delete trong 30 ngày, sau đó hard-delete
- ✅ **Hạn chế xử lý**: yêu cầu ngừng dùng data của bạn cho mục đích cụ thể
- ✅ **Phản đối tự động hóa**: yêu cầu xét duyệt thủ công thay vì AI
- ✅ **Khiếu nại**: liên hệ Cục An toàn Thông tin, Bộ Thông tin và Truyền thông

Yêu cầu các quyền trên: gửi email tới `<SUPPORT_EMAIL>` — chúng tôi phản hồi
trong 30 ngày.

## 7. Cookies & Tracking

- App mobile: KHÔNG dùng cookies (vì không phải web).
- Web `halong24h.com`: dùng cookie session để duy trì đăng nhập. KHÔNG dùng
  cookie tracking quảng cáo.

## 8. Bảo mật

- Mọi traffic qua HTTPS/TLS 1.2+
- Mật khẩu hash bcrypt cost 10
- Token JWT TTL 15 phút (access) + 7 ngày (refresh)
- Single-device session (login mới invalidate device cũ ≤15 phút)
- Refresh token rotation
- Rate limiting + anti-spam tracking
- Khi phát hiện breach: thông báo user trong 72 giờ theo Nghị định 13/2023

## 9. Trẻ em (Children's privacy)

Halong24h KHÔNG dành cho user dưới 13 tuổi. Nếu phát hiện account của trẻ
em dưới 13 tuổi, chúng tôi sẽ xoá ngay lập tức.

User dưới 18 tuổi cần có sự đồng ý của phụ huynh để booking phòng.

## 10. Thay đổi chính sách

Chúng tôi có thể cập nhật chính sách này. Khi có thay đổi quan trọng:
- Thông báo trong app + email tới user
- Hiệu lực sau 30 ngày kể từ thông báo
- User có thể xoá tài khoản nếu không đồng ý

## 11. Liên hệ

UPGO SOLUTIONS COMPANY LIMITED
Email: `<SUPPORT_EMAIL>`
SĐT: `<SUPPORT_PHONE>`
Địa chỉ: `<COMPANY_ADDRESS>`
Mã số doanh nghiệp: `<TAX_ID>`

DPO (Data Protection Officer): `<DPO_EMAIL>` (nếu có)

---

# 🇬🇧 ENGLISH VERSION

## 1. Introduction

UPGO SOLUTIONS COMPANY LIMITED ("we", "Halong24h") respects your privacy.
This policy describes how we collect, use, store, and share personal data
when you use the Halong24h app or website.

By using our services, you agree to the terms below.

## 2. Data we collect

### 2.1 Provided directly by you
- Account info: name, email, phone, password (hashed)
- Avatar from Google/Apple Sign-In or self-uploaded
- Gender, date of birth (optional)
- Vietnamese national ID (CCCD) for property owners only:
  - Front/back ID photos
  - Selfie
  - OCR-extracted ID number, name, DoB, address
- Booking info: guest name, phone, occupancy, check-in/out, notes
- Reviews: text, photos, ratings

### 2.2 Automatically collected
- Device ID (Apple `identifierForVendor` / Android `id`) — anti-spam
- Device metadata: model, OS version, app version, locale
- FCM token for push notifications
- IP address (24-hour retention for anti-spam)
- Crash logs via Firebase Crashlytics (no user-typed content)

### 2.3 From third parties
- Google Sign-In: email, name, avatar
- Apple Sign-In: email, name (first authorization only)

### 2.4 What we DO NOT collect
- ❌ No location/GPS tracking
- ❌ No phone contacts
- ❌ No SMS/email content
- ❌ No advertising tracking (no IDFA)
- ❌ We do not sell data to third parties

### 2.5 Face data (selfie)

We collect **one selfie image** during identity verification (KYC, for property
owners only) so staff can manually compare it with the photo on the national ID
(CCCD).

- **What is collected**: one selfie image. No video is recorded.
- **Purpose**: KYC serves only safety, trust, and accountability — an admin
  reviews it before an owner may publish rooms or add staff, preventing spam or
  fraudulent listings. We never use KYC data for any unlawful purpose.
- **No automated face recognition** is performed to identify you.
- **No automated face matching against the CCCD** — comparison is done manually
  by staff. The app creates and stores no face template, faceprint, or
  biometric embedding.
- **Never used for**: advertising, profiling, tracking, or device unlock (this
  is not Face ID).
- **Storage**: on Cloudinary over a secure connection.
- **Sharing**: never sold, never shared with any third party for face
  recognition/matching. Disclosed only to Vietnamese government authorities upon
  lawful request.
- **Retention**: kept until you delete your account; on account deletion, all
  KYC data including the face image is deleted.

## 3. Purpose of use

(Same as Vietnamese section, mapped to English)

## 4. Data retention

- Active accounts: indefinite
- Deleted accounts: 30-day soft delete, then hard delete
- Booking history: 5 years (Vietnamese accounting law)
- KYC images (CCCD + selfie): kept until account deletion, then deleted
- Crash logs: 90 days
- Anti-spam device/IP data: 24 hours

## 5. Data sharing

We DO NOT sell data. We share only with:
- Google Cloud (Sign-In, Firebase) — email, name, avatar, FCM token
- Apple — email, name (first authorization)
- Cloudinary — property images, CCCD images, selfie image (KYC) for storage and CDN over a secure connection
- Vietnamese government — full data on legal request
- Property owners — guest name, phone, occupancy
- Owner-invited sales staff — same scope as owner

## 6. Your rights (GDPR + Vietnamese Decree 13/2023)

- ✅ Access — request a copy of your data
- ✅ Rectify — edit profile anytime in-app
- ✅ Delete — Profile → Delete account in-app (30-day grace, then hard delete)
- ✅ Restrict processing — request limitation
- ✅ Object to automated decisions
- ✅ Complain to relevant authorities

Email `<SUPPORT_EMAIL>` for requests. We respond within 30 days.

## 7. Cookies

Mobile app uses no cookies. Website uses session cookies for login only;
no advertising/tracking cookies.

## 8. Security

- HTTPS/TLS 1.2+ for all traffic
- Bcrypt hashed passwords (cost 10)
- JWT tokens: 15-min access, 7-day refresh
- Single-device sessions
- Refresh token rotation
- Rate limiting + anti-spam
- Breach notification within 72 hours per Vietnamese Decree 13/2023

## 9. Children's privacy

Halong24h is not for users under 13. We delete such accounts immediately
upon discovery. Users under 18 require parental consent for bookings.

## 10. Policy changes

Material changes notified in-app + email, effective 30 days later.
Users may delete accounts if disagree.

## 11. Contact

UPGO SOLUTIONS COMPANY LIMITED
Email: `<SUPPORT_EMAIL>` · Phone: `<SUPPORT_PHONE>`
Address: `<COMPANY_ADDRESS>`
Business registration: `<TAX_ID>`
DPO: `<DPO_EMAIL>` (if applicable)
