# Halong24h — Tài liệu dự án (Gọi vốn đầu tư)

> **Phiên bản**: 1.1 · **Ngày**: 07/06/2026  
> **Sản phẩm**: Halong24h — Nền tảng quản lý & phân phối phòng lưu trú Hạ Long  
> **Platform**: App mobile Flutter (Android + iOS) · Website · Backend REST API  
> **Mô hình**: B2B SaaS (chủ nhà) + Marketplace có cam kết (khách lưu trú)

---

## Mục lục

1. [Tóm tắt điều hành](#1-tóm-tắt-điều-hành)
2. [Thị trường Hạ Long & Vấn đề cần giải quyết](#2-thị-trường-hạ-long--vấn-đề-cần-giải-quyết)
3. [Tầm nhìn Halong24h — Hệ sinh thái 2 phía](#3-tầm-nhìn-halong24h--hệ-sinh-thái-2-phía)
4. [Cam kết Halong24h cho khách lưu trú](#4-cam-kết-halong24h-cho-khách-lưu-trú)
5. [Lợi ích cho chủ nhà khi tham gia](#5-lợi-ích-cho-chủ-nhà-khi-tham-gia)
6. [Sản phẩm & Chức năng app (phía chủ nhà)](#6-sản-phẩm--chức-năng-app-phía-chủ-nhà)
7. [Cách sử dụng & Vận hành hàng ngày](#7-cách-sử-dụng--vận-hành-hàng-ngày)
8. [App hoạt động như thế nào?](#8-app-hoạt-động-như-thế-nào)
9. [Các gói subscription — Chi tiết đầy đủ](#9-các-gói-subscription--chi-tiết-đầy-đủ)
10. [Mô hình kinh doanh & Nguồn thu](#10-mô-hình-kinh-doanh--nguồn-thu)
11. [Luồng onboarding chủ mới (KYC + Trial)](#11-luồng-onboarding-chủ-mới-kyc--trial)
12. [Công nghệ & Trạng thái phát triển](#12-công-nghệ--trạng-thái-phát-triển)
13. [Lộ trình mở rộng](#13-lộ-trình-mở-rộng)
14. [Chỉ số theo dõi (KPI gợi ý cho nhà đầu tư)](#14-chỉ-số-theo-dõi-kpi-gợi-ý-cho-nhà-đầu-tư)

---

## 1. Tóm tắt điều hành

**Halong24h** xây dựng **hệ sinh thái lưu trú tin cậy tại Hạ Long** — kết nối trực tiếp **chủ nhà đã xác minh** với **khách lưu trú**, thay thế mô hình sale tự do rời rạc, thiếu minh bạch trên Facebook, TikTok, Zalo và các kênh OTA không ổn định.

**Hai trụ cột sản phẩm:**

| Trụ cột | Đối tượng | Giá trị |
|---|---|---|
| **App quản lý (PMS)** | Chủ nhà, nhân viên sale, admin | Quản lý phòng, lịch, booking, doanh thu — realtime trên mobile |
| **Nền tảng Halong24h** | Khách lưu trú | Đặt phòng qua kênh chính thức, được **cam kết có phòng**, **giá tốt nhất thị trường**, phòng **sạch — đa dạng — view biển/phố** |

**Tại sao khác biệt:**

| | Halong24h | Sale tự do (FB/TikTok/Zalo) | OTA (Agoda, Booking.com) |
|---|---|---|---|
| Chủ nhà quản lý trực tiếp | ✅ App PMS riêng | ❌ Excel, sổ, chat rời | ❌ Phụ thuộc kênh, commission cao |
| Khách yên tâm đặt phòng | ✅ Cam kết Halong24h | ❌ Lừa đảo, ảnh ảo phổ biến | ⚠️ Ngày cao điểm/lễ/CN hay bị từ chối |
| Giá minh bạch | ✅ Giá tốt nhất thị trường | ❌ Chênh lệch, không chuẩn | ⚠️ Giá markup, không phải lúc nào cũng rẻ |
| Xác minh chủ nhà | ✅ KYC CCCD + admin duyệt | ❌ Không kiểm soát | ⚠️ Chỉ verify qua OTA |
| Phòng đa dạng | ✅ View biển, view phố, homestay… | ⚠️ Rời rạc, khó so sánh | ⚠️ Inventory không đồng bộ |

**Thị trường mục tiêu:** Hạ Long — nơi du lịch bùng nổ nhưng hạ tầng quản lý phòng và niềm tin đặt phòng còn yếu.

---

## 2. Thị trường Hạ Long & Vấn đề cần giải quyết

### 2.1 Thực trạng thị trường Hạ Long

Hạ Long có hàng nghìn homestay, villa, khách sạn mini — nhưng **không có một hệ thống thống nhất** đưa phòng đến tay khách hàng một cách tin cậy.

**Cách khách tìm phòng hiện nay:**

```
Facebook · TikTok · Website cá nhân · Zalo · Agoda · Booking.com · Sale tự do giới thiệu
```

Mỗi kênh hoạt động **độc lập**, không đồng bộ lịch phòng, không có cơ chế bảo vệ khách.

### 2.2 Nỗi đau của khách lưu trú

| Vấn đề | Hậu quả |
|---|---|
| **Lừa đảo, ảnh ảo** | Chuyển cọc qua Zalo/FB → đến nơi không có phòng, phòng khác ảnh |
| **Giá không minh bạch** | Cùng một phòng, mỗi sale báo một giá — không biết đâu là giá thật |
| **OTA ngày cao điểm** | Đặt Agoda/Booking dịp lễ, cuối tuần → **chủ thường không xác nhận** vì ưu tiên khách direct hoặc overbooking |
| **Không có bên bảo vệ** | Khi tranh chấp, khách tự xử lý — không có đơn vị đứng ra cam kết |
| **Thiếu lựa chọn chuẩn hoá** | View biển, view phố, gia đình, cao cấp… — khó so sánh, khó tin |

### 2.3 Nỗi đau của chủ nhà

| Vấn đề | Hậu quả |
|---|---|
| **Sale tự do, không hệ thống** | Lead rải rác FB/TikTok/Zalo — mất booking, trùng phòng, không báo cáo |
| **Quản lý thủ công** | Sổ tay, Google Sheet — không biết phòng nào trống ngày nào |
| **Phụ thuộc OTA** | Commission 15–25%, khách OTA hay bị từ chối → mất uy tín kênh |
| **Không có thương hiệu tin cậy** | Chủ tốt nhưng khách không biết — thua sale/OTA có marketing mạnh |
| **Khó chứng minh chất lượng** | Phòng sạch, view đẹp nhưng không có nền tảng xác minh & review chuẩn |

### 2.4 Giải pháp Halong24h

Halong24h **không chỉ là app quản lý** — là **nền tảng kết nối 2 chiều**:

```
Chủ nhà (OWNER)                    Khách lưu trú
      │                                    │
      │  App PMS: quản lý phòng, lịch,     │  Kênh Halong24h: website, app khách,
      │  booking, nhân viên, báo cáo       │  Zalo OA, social → đặt phòng tin cậy
      │                                    │
      └────────── Halong24h Platform ──────┘
                    │
         KYC xác minh · Lịch realtime · Cam kết có phòng
         · Giá tốt nhất · Phòng sạch · Đa dạng view
```

---

## 3. Tầm nhìn Halong24h — Hệ sinh thái 2 phía

### 3.1 Phía chủ nhà — App quản lý (đang vận hành)

App mobile Flutter dành cho **OWNER, SALE, ADMIN**:

- Quản lý cơ sở & phòng trực tiếp — không qua trung gian
- Nhận thông tin khách (tên, SĐT, ngày, cọc) **tập trung một chỗ**
- Lịch phòng realtime — tránh trùng, tránh overbooking
- Mời nhân viên sale vào hệ thống thay vì sale tự do ngoài luồng

> **Trạng thái:** App B2B **đã build và đang triển khai** (v1.1.4).

### 3.2 Phía khách lưu trú — Kênh Halong24h (đang mở rộng)

Khách đặt phòng qua **kênh chính thức Halong24h** (website, app khách, Zalo, social có gắn link nền tảng):

- Chỉ hiển thị **chủ đã KYC**, phòng **active** trên hệ thống
- **Cam kết Halong24h** bảo vệ quyền lợi khách (xem mục 4)
- Lead từ FB/TikTok/Zalo **dẫn về nền tảng** thay vì chat riêng lẻ

> **Trạng thái:** Luồng nhận booking phía chủ **đã có** (hold/confirm trên app). Kênh đặt phòng trực tiếp cho khách (B2C app/website) **đang trong lộ trình** — app mobile hiện tại tập trung phía vận hành chủ nhà.

### 3.3 Ai dùng gì?

| Vai trò | Công cụ | Việc chính |
|---|---|---|
| **OWNER** (Chủ nhà) | App Halong24h | Quản lý phòng, giá, nhân viên; nhận booking từ kênh Halong24h & sale |
| **SALE** (Nhân viên) | App Halong24h | Giữ/xác nhận phòng cho khách — thay thế sale tự do |
| **ADMIN** | App Halong24h | Duyệt KYC, kiểm soát chất lượng, moderation |
| **Khách lưu trú** | Website / App khách Halong24h *(roadmap)* | Tìm & đặt phòng với cam kết Halong24h |

---

## 4. Cam kết Halong24h cho khách lưu trú

Đây là **lời hứa thương hiệu** — điều khiến khách chọn Halong24h thay vì sale lẻ trên FB/TikTok/Zalo hay OTA không ổn định.

### 4.1 Bốn cam kết cốt lõi

| # | Cam kết | Ý nghĩa với khách |
|---|---|---|
| 1 | **Có phòng — được vào ở** | Đặt qua Halong24h = phòng được giữ trên hệ thống realtime. Không còn cảnh chuyển cọc rồi đến nơi hết phòng |
| 2 | **Giá tốt nhất thị trường** | Giá niêm yết trên nền tảng = giá cam kết. Không markup ẩn như nhiều sale trung gian. Chủ set giá trực tiếp |
| 3 | **Phòng sạch, đúng mô tả** | Chủ phải KYC + upload ảnh thật. Halong24h xử lý khiếu nại, hoàn tiền nếu phòng không đúng cam kết |
| 4 | **Đa dạng lựa chọn** | View biển, view phố, view núi, homestay gia đình, villa cao cấp… — tất cả trên một nền tảng, dễ so sánh |

### 4.2 Cơ chế thực thi cam kết

```
Chủ đăng ký → KYC (CCCD + selfie) → Admin duyệt
    ↓
Phòng đăng lên nền tảng với ảnh, giá, tiện nghi chuẩn hoá
    ↓
Khách đặt → Booking HOLD trên lịch realtime (không overbooking)
    ↓
Chủ/SALE xác nhận trong SLA → CONFIRMED
    ↓
Check-in: khách vào phòng đúng mô tả
    ↓
Sau ở: Review → Halong24h hiển thị công khai, xử lý vi phạm
```

**Khi có sự cố:**

- Khách báo qua Halong24h → Admin điều tra
- Chủ vi phạm (phòng ảo, từ chối không lý do, bẩn…) → cảnh cáo / tạm khóa / loại khỏi nền tảng
- Khách được **hoàn cọc / đổi phòng tương đương** theo chính sách Halong24h

### 4.3 So sánh với OTA ngày cao điểm

| | Halong24h | OTA (Agoda, Booking) |
|---|---|---|
| Lịch phòng | Realtime từ app chủ — 1 nguồn sự thật | Đồng bộ chậm, hay overbooking |
| Ngày lễ / cuối tuần | Cam kết xác nhận nếu còn trống trên lịch | Hay bị chủ từ chối vì ưu tiên khách direct |
| Giá | Chủ set trực tiếp — giá tốt nhất thị trường | Markup + commission → giá cao hơn |
| Bảo vệ khách | Halong24h đứng ra cam kết | Phụ thuộc chính sách OTA, xử lý chậm |

---

## 5. Lợi ích cho chủ nhà khi tham gia

### 5.1 Tiện ích trực tiếp — Quản lý & vận hành

| Tiện ích | Mô tả |
|---|---|
| **Quản lý phòng tập trung** | Tất cả phòng, giá, ảnh, tiện nghi trên một app — không cần Excel/Zalo |
| **Lịch realtime** | Biết chính xác phòng nào trống/đã đặt/đang ở — hết trùng phòng |
| **Nhận booking tập trung** | Mọi lead (Halong24h, sale nội bộ, walk-in) ghi vào cùng hệ thống |
| **Dashboard KPI** | Doanh thu hôm nay/tháng, occupancy, booking — ra quyết định nhanh |
| **Quản lý nhân viên sale** | Mời sale vào app thay vì sale tự do — kiểm soát được ai bán gì |
| **Báo cáo doanh thu** | Biểu đồ xu hướng, phân tích theo kỳ — không cần tự tính |
| **Thông báo push** | Booking mới, thanh toán, check-in sắp tới — không bỏ lỡ |

### 5.2 Tiện ích kinh doanh — Tiếp cận khách & thương hiệu

| Tiện ích | Mô tả |
|---|---|
| **Huy hiệu "Chủ đã xác minh"** | KYC CCCD + admin duyệt → khách tin tưởng hơn sale lẻ |
| **Listing trên Halong24h** | Phòng xuất hiện trên kênh chính thức — tiếp cận khách đang tìm Hạ Long |
| **Không phụ thuộc OTA** | Nhận booking direct qua nền tảng — commission thấp hơn Agoda/Booking |
| **Review công khai** | Khách review sau khi ở → xây uy tín lâu dài, phòng sạch được ghi nhận |
| **Giá do chủ quyết định** | Set giá trực tiếp — cam kết giá tốt nhất thị trường thu hút khách |
| **Phân loại phòng rõ ràng** | View biển, view phố, sức chứa, tiện nghi — khách dễ chọn, chủ dễ bán |

### 5.3 Tiện ích bảo vệ — Giảm rủi ro

| Tiện ích | Mô tả |
|---|---|
| **Chống lừa đảo ngược** | Chủ uy tín được phân biệt với sale ảo — KYC bảo vệ cả 2 phía |
| **Chính sách huỷ rõ ràng** | Cài đặt trên app — khách biết trước, tranh chấp giảm |
| **Hỗ trợ tranh chấp** | Halong24h đứng ra xử lý khiếu nại thay vì chủ tự đối phó |
| **Không bị overbooking OTA** | Lịch 1 nguồn — từ chối booking OTA ngày cao điểm giảm mạnh |

### 5.4 Lợi ích theo quy mô

| Quy mô | Lợi ích nổi bật nhất |
|---|---|
| **1 phòng (Mini)** | Thay sổ/Zalo, có listing Halong24h, nhận lead chính thức |
| **5–10 phòng (Starter/Standard)** | Quản lý team sale, pricing linh hoạt, báo cáo chuyên nghiệp |
| **20–50 phòng (Pro/Business)** | Multi-property, đồng bộ OTA, API tích hợp website riêng |
| **Chuỗi lớn (Enterprise)** | Không giới hạn phòng, SLA 24/7, onboarding riêng |

---

## 6. Sản phẩm & Chức năng app (phía chủ nhà)

| Hạng mục | Giá trị |
|---|---|
| **App quản lý** | Flutter Android + iOS · v1.1.4 |
| **Backend** | `https://api.halong24h.com` |
| **Người dùng app** | OWNER · SALE · ADMIN |
| **Vai trò app** | Công cụ vận hành + nhận booking từ kênh Halong24h |

### 6.1 OWNER — Chủ homestay

| Module | Chức năng |
|---|---|
| **Dashboard** | KPI: tổng phòng, phòng trống/đang ở, booking tháng, doanh thu hôm nay/tháng, check-out hôm nay |
| **Quản lý cơ sở** | Tạo/sửa homestay: thông tin, ảnh, tiện nghi, giá, dịch vụ, quy định, vị trí, chính sách huỷ |
| **Phòng** | Danh sách phòng active, chi tiết phòng, upload ảnh, cài giá |
| **Lịch** | Lưới lịch tuần/tháng — trạng thái từng phòng theo ngày |
| **Booking** | Danh sách booking, chi tiết, giữ phòng (hold), xác nhận, huỷ |
| **Check-in / Check-out** | Danh sách khách sắp check-in/check-out trong 14 ngày tới |
| **Báo cáo** | Doanh thu theo kỳ, biểu đồ xu hướng, phân bổ trạng thái booking, đánh giá cơ sở |
| **Nhân viên** | Mời SALE qua email, quản lý danh sách nhân viên |
| **KYC + Subscription** | Xác minh CCCD + selfie → chọn gói → thanh toán → trial 7 ngày |
| **Hồ sơ** | Thông tin cá nhân, đổi mật khẩu, thông báo, hỗ trợ, chính sách |
| **Đánh giá** | Xem review khách, trả lời review |

### 6.2 SALE — Nhân viên

| Module | Chức năng |
|---|---|
| **Dashboard** | KPI phạm vi được gán |
| **Phòng & Lịch** | Xem phòng/lịch thuộc owner gán |
| **Booking** | **Giữ phòng** cho khách (tên, SĐT, cọc, ghi chú) → **Xác nhận** sau khi khách chốt |
| **Check-in / Check-out** | Theo dõi khách sắp đến/trả phòng |
| **Báo cáo** | Xem báo cáo trong phạm vi quyền |

**Giới hạn SALE:**

- Không tạo cơ sở mới (`/properties/new` bị chặn)
- Phải được OWNER mời và membership **active** mới truy cập đầy đủ
- Membership `invited/suspended/unassigned`: chỉ dashboard + profile + thông báo

### 6.3 ADMIN — Quản trị hệ thống

| Module | Chức năng |
|---|---|
| **Hub quản lý** | Tổng quan user, cơ sở, booking, badge KYC/báo cáo vi phạm |
| **Duyệt KYC** | Queue 4 tab: chờ duyệt / đã duyệt / từ chối / tất cả — xem CCCD, OCR, face match |
| **Quản lý user** | CRUD user, phân role |
| **Trial** | Cấp/gia hạn/thu hồi trial cho OWNER |
| **Lịch owner** | Xem lịch toàn hệ thống |
| **Moderation** | Báo cáo vi phạm, audit log (một phần đang chờ BE) |
| **Phân quyền** | Cấu hình permission theo role |

### 6.4 Tính năng chung

- **Đăng nhập**: Email/mật khẩu, Google Sign-In, Apple Sign-In (iOS)
- **Dark mode** + giao diện Material Design 3, font Be Vietnam Pro
- **Push notification** (Firebase) — booking, thanh toán subscription
- **Thông báo in-app** — booking, payment (không hiển thị system log cho OWNER/SALE)

---

## 7. Cách sử dụng & Vận hành hàng ngày

### 7.1 Onboarding chủ mới

```
Đăng ký (OWNER) → Đăng nhập → Dashboard
    ↓
Banner "Xác minh danh tính" (nếu chưa KYC)
    ↓
Chụp CCCD mặt trước/sau + Selfie liveness
    ↓
Chọn gói subscription (Monthly/Yearly)
    ↓
Thanh toán (chuyển khoản VietQR) → Chờ admin duyệt KYC
    ↓
Admin duyệt → Trial 7 ngày bắt đầu
    ↓
Tạo cơ sở → Thêm phòng → Bắt đầu vận hành
```

### 7.2 Vận hành booking (luồng core)

Đây là **workflow hàng ngày** — khách có thể đến từ **kênh Halong24h**, sale nội bộ, Zalo/FB (ghi vào app), hoặc walk-in:

```
① Khách tìm phòng qua Halong24h / gọi sale / Zalo / walk-in
        ↓
② Lead vào hệ thống → SALE/OWNER mở app → tab "Lịch" hoặc "Phòng"
        ↓
③ Chọn phòng + ngày check-in/check-out còn trống (lịch realtime)
        ↓
④ "Giữ phòng" (Hold) — tên khách, SĐT, cọc, ghi chú
   → Booking status = HOLD (~30 phút để chốt)
        ↓
⑤ Khách chuyển cọc (qua Halong24h hoặc ngoài app)
        ↓
⑥ SALE/OWNER "Xác nhận" → CONFIRMED — Halong24h cam kết có phòng
        ↓
⑦ Check-in → Check-out → Review công khai
        ↓
⑧ Dashboard + Báo cáo cập nhật doanh thu/KPI
```

### 7.3 Mời nhân viên SALE

```
OWNER → Quản lý → Nhân viên → Tạo lời mời (email)
    ↓
Nhân viên nhận email → mở link → /staff/accept
    ↓
Đăng ký / đăng nhập → Gắn với OWNER → Bắt đầu giữ booking
```

### 7.4 Navigation chính (Bottom bar)

| Tab | Route | Mô tả |
|---|---|---|
| Tổng quan | `/dashboard` | KPI, booking hôm nay, banner KYC/subscription |
| Phòng | `/rooms` | Danh sách phòng active |
| Lịch | `/calendar` | Lưới lịch tuần/tháng |
| Báo cáo | `/reports` | Doanh thu, biểu đồ |
| Quản lý | `/admin` hoặc `/properties` | ADMIN hub / Quản lý cơ sở (OWNER) |

---

## 8. App hoạt động như thế nào?

### 8.1 Kiến trúc kỹ thuật

```
┌─────────────────────────────────────────┐
│         App Mobile (Flutter)            │
│  UI → Controller (Riverpod) → Repo      │
└──────────────────┬──────────────────────┘
                   │ HTTPS + Bearer Token
                   ▼
┌─────────────────────────────────────────┐
│         Backend REST API                │
│  Auth · Properties · Bookings · Billing │
│  KYC · Notifications · Reports        │
└──────────────────┬──────────────────────┘
                   │
         ┌─────────┴─────────┐
         ▼                   ▼
   PostgreSQL            VNPay / Bank
   (dữ liệu)            (thanh toán)
```

### 8.2 Luồng xác thực

1. User đăng nhập → nhận `accessToken` + `refreshToken`
2. Token lưu **Secure Storage** (mã hoá trên thiết bị)
3. Mọi API request tự gắn Bearer token
4. Token hết hạn (401) → tự refresh → retry
5. Refresh fail → logout → về màn login

### 8.3 Phân quyền & bảo vệ route

App tự **chặn truy cập** theo role:

- CUSTOMER (role=3): **không được dùng app** — logout + thông báo
- SALE chưa active: chỉ dashboard/profile
- OWNER chưa KYC: không tạo/sửa cơ sở → redirect flow xác minh
- ADMIN-only routes: KYC queue, user management, trial

### 8.4 Đồng bộ dữ liệu

| Cơ chế | Dùng cho |
|---|---|
| Pull-to-refresh | Dashboard, danh sách booking |
| App resume | Refresh profile (KYC/subscription thay đổi) |
| Polling 30s | Chờ admin duyệt KYC, trạng thái thanh toán |
| FCM Push | Thông báo booking, thanh toán |

---

## 9. Các gói subscription — Chi tiết đầy đủ

Mỗi gói gồm **3 nhóm quyền lợi**:

1. **Phần mềm quản lý (PMS)** — công cụ trên app mobile  
2. **Nền tảng Halong24h** — listing, tiếp cận khách, cam kết thương hiệu  
3. **Hỗ trợ & đồng hành** — mức SLA, kênh liên hệ, đào tạo  

### 9.1 Nguyên tắc chung

| Quy tắc | Chi tiết |
|---|---|
| Phân tier theo **số phòng tối đa** | Mini=1, Starter=5, Standard=10, Pro=20, Business=50, Enterprise=∞ |
| Chu kỳ thanh toán | **Tháng** hoặc **Năm** (giảm **20%**) |
| VAT | **10%** trên subtotal |
| Trial | **7 ngày miễn phí** sau admin duyệt KYC — không thu tiền trong trial |
| KYC bắt buộc | Mọi gói đều cần xác minh CCCD — mới được listing & cam kết Halong24h |
| Nâng cấp | Đổi gói khi mở rộng số phòng — không mất dữ liệu |

### 9.2 Bảng giá tóm tắt

| Gói | Số phòng | Giá/tháng | Giá/năm (-20%) | Đối tượng |
|---|---:|---:|---:|---|
| **Mini** | 1 | 199.000đ | ~1,91 triệu | Cá nhân cho thuê 1 phòng |
| **Starter** | 5 | 599.000đ | ~5,75 triệu | Homestay nhỏ Hạ Long |
| **Standard** | 10 | 999.000đ | ~9,59 triệu | Homestay/villa vừa |
| **Pro** | 20 | 1.799.000đ | ~17,27 triệu | Cơ sở lớn, nhiều view |
| **Business** | 50 | 3.999.000đ | ~38,39 triệu | Chuỗi homestay |
| **Enterprise** | Không giới hạn | Liên hệ | Hợp đồng riêng | Khách sạn, resort |

*Giá năm = monthly × 12 × 0,8 (+ VAT 10%).*

---

### 9.3 GÓI MINI — 1 phòng · 199.000đ/tháng

**Dành cho:** Chủ cá nhân cho thuê 1 phòng/homestay mini, mới bắt đầu bỏ sổ/Zalo.

#### A. Phần mềm quản lý (PMS)

| Tính năng | Chi tiết |
|---|---|
| Quản lý 1 cơ sở, tối đa **1 phòng** | Thông tin, ảnh, giá, tiện nghi |
| Lịch phòng tuần/tháng | Trạng thái trống / đã đặt / đang ở — realtime |
| Booking hold & confirm | Giữ phòng, xác nhận, huỷ — nhập tên/SĐT khách |
| Check-in / Check-out | Danh sách khách sắp đến/trả phòng (14 ngày) |
| Dashboard KPI | Phòng trống, doanh thu hôm nay/tháng, booking |
| Báo cáo cơ bản | Doanh thu theo kỳ, biểu đồ đơn giản |
| Thông báo push | Booking mới, nhắc check-in |
| 1 tài khoản OWNER | Không mời nhân viên sale |

#### B. Nền tảng Halong24h

| Quyền lợi | Chi tiết |
|---|---|
| Listing cơ sở trên Halong24h | Phòng hiển thị trên kênh chính thức sau KYC |
| Huy hiệu **"Chủ đã xác minh"** | CCCD + admin duyệt |
| Tham gia **Cam kết Halong24h** | Có phòng · Giá tốt nhất · Sạch · Đúng mô tả |
| Nhận lead từ kênh Halong24h | Khách đặt qua website/app → booking vào app |
| Hiển thị review công khai | Khách review sau khi ở |
| Phân loại phòng | View biển, view phố, tiện nghi chuẩn hoá |

#### C. Hỗ trợ

| Hạng mục | Chi tiết |
|---|---|
| Kênh | Zalo OA / Email |
| Thời gian phản hồi | **48 giờ** (ngày làm việc) |
| Đào tạo | Video hướng dẫn + FAQ trong app |
| Onboarding | Tự phục vụ qua app |
| Xử lý tranh chấp | Halong24h hỗ trợ theo chính sách nền tảng |

---

### 9.4 GÓI STARTER — 5 phòng · 599.000đ/tháng

**Dành cho:** Homestay nhỏ Hạ Long (3–5 phòng), bắt đầu có nhân viên sale, muốn thay sale tự do.

#### A. Phần mềm quản lý (PMS)

| Tính năng | Chi tiết |
|---|---|
| **Tất cả Mini** | — |
| Tối đa **5 phòng** | Quản lý nhiều loại phòng (view biển, view phố…) |
| **Pricing rules cơ bản** | Giá theo ngày thường / cuối tuần / lễ |
| **Multi-staff: tối đa 3 nhân viên SALE** | Mời qua email, gán quyền giữ booking |
| Upload nhiều ảnh/phòng | Gallery, ảnh cover |
| Chính sách huỷ | Linh hoạt / vừa phải / nghiêm |

#### B. Nền tảng Halong24h

| Quyền lợi | Chi tiết |
|---|---|
| **Tất cả Mini** | — |
| Listing **5 phòng** với filter view biển/phố | Khách dễ tìm đúng loại phòng |
| Ưu tiên hiển thị **cơ bản** trên kênh Halong24h | Trên listing miễn phí |
| Link đặt phòng chia sẻ | Gắn vào FB/TikTok/Zalo cá nhân → dẫn về nền tảng |
| Tham gia chương trình **"Giá tốt nhất thị trường"** | Cam kết giá niêm yết = giá thật |

#### C. Hỗ trợ

| Hạng mục | Chi tiết |
|---|---|
| Kênh | Zalo OA / Email / Hotline (giờ hành chính) |
| Thời gian phản hồi | **24 giờ** |
| Đào tạo | 1 buổi online setup cơ sở (30 phút) |
| Hỗ trợ upload phòng | Hướng dẫn chụp ảnh, mô tả view biển/phố chuẩn |

---

### 9.5 GÓI STANDARD — 10 phòng · 999.000đ/tháng

**Dành cho:** Homestay/villa vừa (6–10 phòng), vận hành chuyên nghiệp, cần báo cáo & pricing nâng cao.

#### A. Phần mềm quản lý (PMS)

| Tính năng | Chi tiết |
|---|---|
| **Tất cả Starter** | — |
| Tối đa **10 phòng** | — |
| **Dynamic pricing** | Gợi ý/điều chỉnh giá theo mùa, occupancy *(roadmap)* |
| **Housekeeping + Expenses** | Quản lý dọn phòng, chi phí vận hành *(roadmap)* |
| **Báo cáo nâng cao** | Xu hướng doanh thu, occupancy rate, so sánh kỳ |
| Biểu đồ phân tích booking | Donut trạng thái, trend chart |

#### B. Nền tảng Halong24h

| Quyền lợi | Chi tiết |
|---|---|
| **Tất cả Starter** | — |
| Listing **10 phòng** — đa dạng view | Biển, phố, núi, gia đình |
| **Badge "Homestay tiêu chuẩn Halong24h"** | Sau khi duy trì rating ≥ 4.0 |
| Ưu tiên hiển thị **trung bình** trên trang chủ khu vực | Hạ Long, Tuần Châu, Bãi Cháy… |
| Hiển thị tiện nghi chuẩn hoá | Bể bơi, BBQ, view biển, gần Bãi Cháy… |

#### C. Hỗ trợ

| Hạng mục | Chi tiết |
|---|---|
| Kênh | Zalo OA / Email / Hotline |
| Thời gian phản hồi | **12 giờ** |
| Đào tạo | 1 buổi online + tài liệu vận hành sale chuẩn |
| Tư vấn pricing | Gợi ý giá theo mùa Hạ Long (lễ, cuối tuần, mùa cao điểm) |

---

### 9.6 GÓI PRO — 20 phòng · 1.799.000đ/tháng

**Dành cho:** Cơ sở lớn, nhiều loại phòng (view biển + view phố), nhiều nhân viên sale.

#### A. Phần mềm quản lý (PMS)

| Tính năng | Chi tiết |
|---|---|
| **Tất cả Standard** | — |
| Tối đa **20 phòng** | — |
| **Multi-staff không giới hạn** | Mời bao nhiêu SALE cũng được |
| **Multi-property** | Quản lý **nhiều cơ sở** (2+ homestay/villa) |
| Báo cáo theo từng cơ sở | So sánh performance giữa các property |
| Lịch tổng hợp | Xem lịch tất cả cơ sở trên một màn hình |

#### B. Nền tảng Halong24h

| Quyền lợi | Chi tiết |
|---|---|
| **Tất cả Standard** | — |
| Listing **20 phòng** across multi-property | Portfolio view trên Halong24h |
| **Badge "Chủ uy tín"** | Rating ≥ 4.5, KYC lâu năm |
| Ưu tiên hiển thị **cao** — vị trí nổi bật | Banner khu vực, gợi ý "Top view biển" |
| Trang profile chủ riêng | Giới thiệu tất cả cơ sở, review tổng hợp |

#### C. Hỗ trợ

| Hạng mục | Chi tiết |
|---|---|
| Kênh | Zalo OA / Email / Hotline ưu tiên |
| Thời gian phản hồi | **8 giờ** |
| Đào tạo | 2 buổi: setup hệ thống + đào tạo team sale |
| Account manager | 1 người phụ trách (shared, giờ hành chính) |
| Hỗ trợ tranh chấp | Ưu tiên xử lý khiếu nại khách |

---

### 9.7 GÓI BUSINESS — 50 phòng · 3.999.000đ/tháng

**Dành cho:** Chuỗi homestay/khách sạn mini, cần đồng bộ OTA và tích hợp kỹ thuật.

#### A. Phần mềm quản lý (PMS)

| Tính năng | Chi tiết |
|---|---|
| **Tất cả Pro** | — |
| Tối đa **50 phòng** | — |
| **Channel sync (OTA)** | Đồng bộ Booking.com, Agoda — 1 lịch, hết overbooking *(roadmap)* |
| **API + Webhook** | Tích hợp website riêng, CRM, chatbot Zalo *(roadmap)* |
| Export báo cáo | PDF/Excel doanh thu, occupancy |
| Admin contact calendar | Lịch liên hệ admin toàn hệ thống |

#### B. Nền tảng Halong24h

| Quyền lợi | Chi tiết |
|---|---|
| **Tất cả Pro** | — |
| Listing **50 phòng** — full portfolio | — |
| **Badge "Đối tác Business Halong24h"** | Hiển thị nổi bật trên mọi trang |
| **Featured placement** | Top search, banner trang chủ Halong24h |
| Chiến dịch marketing đồng thương hiệu | Co-branded content FB/TikTok Halong24h |
| Báo cáo hiệu suất kênh | Lead từ Halong24h vs direct vs OTA |

#### C. Hỗ trợ

| Hạng mục | Chi tiết |
|---|---|
| Kênh | Hotline ưu tiên / Zalo VIP / Email |
| Thời gian phản hồi | **4 giờ** (giờ hành chính) |
| Đào tạo | On-site hoặc online — đào tạo toàn team |
| Account manager | Dedicated (1 AM / 5 account Business) |
| Tư vấn vận hành | Review pricing, occupancy, chiến lược ngày cao điểm |

---

### 9.8 GÓI ENTERPRISE — Không giới hạn · Liên hệ

**Dành cho:** Khách sạn, resort, chuỗi lớn — hợp đồng riêng, SLA cao nhất.

#### A. Phần mềm quản lý (PMS)

| Tính năng | Chi tiết |
|---|---|
| **Tất cả Business** | — |
| **Số phòng không giới hạn** | — |
| Custom integration | ERP, PMS hiện có, channel manager riêng |
| Multi-brand | Nhiều thương hiệu dưới 1 account |
| SLA uptime | 99.5% cam kết hợp đồng |

#### B. Nền tảng Halong24h

| Quyền lợi | Chi tiết |
|---|---|
| **Tất cả Business** | — |
| **Trang thương hiệu riêng** trên Halong24h | Microsite cho chuỗi |
| **Exclusive partnership** | Không listing đối thủ cùng phân khúc trong khu vực cam kết |
| Chiến dịch marketing riêng | PR, KOL, content production |
| White-label option | App/website mang thương hiệu chủ *(roadmap)* |

#### C. Hỗ trợ

| Hạng mục | Chi tiết |
|---|---|
| Kênh | Hotline **24/7** · Zalo VIP · Email ưu tiên |
| Thời gian phản hồi | **1 giờ** (critical) · **4 giờ** (thường) |
| **Onboarding 1-1** | Chuyên viên setup toàn bộ hệ thống tại cơ sở |
| Dedicated account manager | 1 AM riêng, họp review hàng tháng |
| Đào tạo không giới hạn | On-site + online cho mọi cấp nhân viên |
| Hỗ trợ pháp lý cơ bản | Hợp đồng, chính sách huỷ, điều khoản cam kết |

---

### 9.9 Ma trận so sánh nhanh

#### Phần mềm (PMS)

| Tính năng | Mini | Starter | Standard | Pro | Business | Enterprise |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Số phòng tối đa | 1 | 5 | 10 | 20 | 50 | ∞ |
| Lịch + Booking | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Check-in/out | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Báo cáo cơ bản | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Pricing rules | — | ✅ | ✅ | ✅ | ✅ | ✅ |
| Dynamic pricing | — | — | ✅* | ✅* | ✅* | ✅* |
| Nhân viên SALE | 0 | 3 | 3 | ∞ | ∞ | ∞ |
| Multi-property | — | — | — | ✅ | ✅ | ✅ |
| Báo cáo nâng cao | — | — | ✅ | ✅ | ✅ | ✅ |
| Channel sync OTA | — | — | — | — | ✅* | ✅* |
| API + Webhook | — | — | — | — | ✅* | ✅* |

*\* = trong lộ trình phát triển, cam kết theo hợp đồng gói*

#### Nền tảng Halong24h

| Quyền lợi | Mini | Starter | Standard | Pro | Business | Enterprise |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Listing trên Halong24h | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Huy hiệu KYC | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Cam kết Halong24h (4 điều) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Link chia sẻ FB/TikTok/Zalo | — | ✅ | ✅ | ✅ | ✅ | ✅ |
| Giá tốt nhất thị trường | — | ✅ | ✅ | ✅ | ✅ | ✅ |
| Ưu tiên hiển thị | Thấp | Cơ bản | Trung bình | Cao | Featured | Exclusive |
| Badge uy tín | — | — | Tiêu chuẩn | Chủ uy tín | Business | Đối tác |

#### Hỗ trợ

| Hạng mục | Mini | Starter | Standard | Pro | Business | Enterprise |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Phản hồi | 48h | 24h | 12h | 8h | 4h | 1h (critical) |
| Hotline | — | ✅ | ✅ | Ưu tiên | VIP | 24/7 |
| Đào tạo | Video | 30' online | 1 buổi | 2 buổi | On-site | Không giới hạn |
| Account manager | — | — | — | Shared | Dedicated | Dedicated riêng |
| Onboarding 1-1 | — | — | — | — | — | ✅ |

### 9.10 Phương thức thanh toán subscription

| Phương thức | Trạng thái |
|---|---|
| **Chuyển khoản / VietQR** | ✅ Active |
| **Thẻ tín dụng/ghi nợ** | 🔜 Sắp ra mắt |
| **VNPay QR** | 🔜 Roadmap |

### 9.11 Vòng đời subscription

```
none → KYC + chọn gói + thanh toán → admin duyệt → trial (7 ngày)
    → active (auto-charge tháng/năm)
    → past_due (quá hạn — cảnh báo, giới hạn listing)
    → cancelled (huỷ — gỡ khỏi nền tảng Halong24h)
```

**Lưu ý:** Chủ huỷ gói / quá hạn thanh toán → phòng **gỡ khỏi listing Halong24h** — khách không thể đặt qua cam kết nền tảng nữa. App quản lý vẫn truy cập ở mức hạn chế để khuyến khích gia hạn.

> **Minh bạch cho nhà đầu tư:** Core PMS (booking, lịch, dashboard, KYC, staff, báo cáo cơ bản) **đã có trên app v1.1.4**. Các tính năng đánh dấu *roadmap* (dynamic pricing, OTA sync, API…) là cam kết lộ trình theo tier — tăng ARPU và retention khi scale.

---

## 10. Mô hình kinh doanh & Nguồn thu

### 10.1 Nguồn thu chính (hiện tại & gần hạn)

| # | Nguồn thu | Mô tả | Trạng thái |
|---|---|---|---|
| 1 | **Subscription SaaS** | Phí hàng tháng/năm theo gói (số phòng) | ✅ Đang triển khai |
| 2 | **Gói Enterprise** | Hợp đồng riêng, giá thương lượng, SLA 24/7 | ✅ Có tier, sales-led |
| 3 | **Thanh toán năm (Yearly)** | Giảm 20% so với trả tháng × 12 — tăng cash flow & retention | ✅ Có trên app |

**Công thức doanh thu recurring (MRR):**

```
MRR = Σ (số OWNER active × giá gói tháng)
ARR = MRR × 12  (+ phần yearly prepaid)
```

**Ví dụ:** 100 OWNER gói Starter (599.000đ/tháng) → MRR ≈ **59,9 triệu VND/tháng** (~720 triệu VND/năm).

### 10.2 Nguồn thu tiềm năng (roadmap)

| # | Nguồn thu | Mô tả |
|---|---|---|
| 4 | **Channel Manager add-on** | Đồng bộ Booking.com, Agoda — tính phí cao hơn hoặc add-on gói Business |
| 5 | **Payment processing** | Thu phí qua VNPay/thẻ — margin trên giao dịch cọc/booking |
| 6 | **Commission booking B2C** | Phí trên booking khách đặt qua kênh Halong24h *(khi app khách ra mắt)* |
| 7 | **White-label / API** | Bán license cho đối tác du lịch |
| 8 | **Marketing co-brand** | Gói Business/Enterprise — chiến dịch FB/TikTok chung |

### 10.3 Unit economics (khung tính)

| Chỉ số | Ghi chú |
|---|---|
| **CAC** | Chi phí acquisition qua Facebook/Zalo ads, đối tác homestay Hạ Long |
| **LTV** | Giá gói trung bình × thời gian giữ chân (target > 12 tháng) |
| **Churn** | Theo dõi qua `subscriptionStatus = cancelled/past_due` |
| **Trial → Paid** | Tỷ lệ chuyển đổi sau trial 7 ngày |
| **Gross margin SaaS** | Cao (~70–85%) sau khi trừ hosting, payment fee, support |

---

## 11. Luồng onboarding chủ mới (KYC + Trial)

### Tại sao cần KYC?

- Xác minh **chủ cơ sở thật** — chống sale ảo, lừa đảo trên FB/TikTok/Zalo
- Tuân thủ **xác thực danh tính** tại Việt Nam
- **Điều kiện bắt buộc** để listing trên Halong24h và cam kết bảo vệ khách

### 7 bước verify flow

| Bước | Màn hình | Hành động |
|---|---|---|
| 1 | Chụp CCCD mặt trước | Upload + OCR |
| 2 | Chụp CCCD mặt sau | Upload |
| 3 | Selfie liveness | Face match với CCCD |
| 4 | Chọn gói | Pick tier + Monthly/Yearly |
| 5 | Thanh toán | Chuyển khoản VietQR |
| 6 | Chờ duyệt | Admin review (poll 30s) |
| 7 | Trial active | 7 ngày miễn phí → auto-charge |

**Admin duyệt KYC** → kích hoạt trial 7 ngày. **Từ chối** → hoàn tiền 3–7 ngày làm việc.

---

## 12. Công nghệ & Trạng thái phát triển

### 12.1 Tech stack

| Thành phần | Công nghệ |
|---|---|
| Mobile | Flutter 3.5+, Dart |
| State management | Riverpod |
| Navigation | GoRouter |
| HTTP | Dio + auto refresh token |
| Auth storage | Flutter Secure Storage |
| Push | Firebase Cloud Messaging |
| Analytics/Crash | Firebase Crashlytics |
| Backend | Node.js REST API (riêng biệt) |

### 12.2 Trạng thái phát triển

| Hạng mục | Trạng thái |
|---|---|
| Auth (login, register, Google) | ✅ Production |
| Dashboard KPI | ✅ Production |
| Property/Room CRUD | ✅ Production |
| Calendar grid | ✅ Production |
| Booking hold/confirm/cancel | ✅ Production |
| Báo cáo doanh thu | ✅ Production |
| KYC + Subscription + Trial | ✅ Production |
| Staff invite | ✅ Production |
| Admin KYC queue | ✅ Production |
| Push notifications | ✅ Production |
| Check-in/Check-out API | 🔜 Roadmap BE |
| Abuse reports (admin) | 🟡 UI có, chờ BE API |
| Channel sync OTA | 🔜 Roadmap |
| Kênh khách Halong24h (website/app B2C) | 🔜 Roadmap — luồng chủ nhận booking đã sẵn sàng |

**App version hiện tại:** 1.1.4+13 · **Target market:** Hạ Long 24h homestay ecosystem.

---

## 13. Lộ trình mở rộng

### Giai đoạn 1 — Hoàn thiện nền tảng tin cậy (0–6 tháng)

- [ ] Website Halong24h — khách tìm & đặt phòng với cam kết 4 điều
- [ ] Check-in/Check-out API đầy đủ
- [ ] VNPay / thẻ tín dụng tự động
- [ ] Link chia sẻ từ FB/TikTok/Zalo → landing đặt phòng Halong24h
- [ ] Abuse reports + audit log BE

### Giai đoạn 2 — Mở rộng thị trường Hạ Long (6–12 tháng)

- [ ] App khách lưu trú (B2C) — product riêng
- [ ] Dynamic pricing + housekeeping
- [ ] Channel Manager (Booking.com, Agoda sync)
- [ ] Mở rộng Hạ Long → Quảng Ninh → Bắc Bộ

### Giai đoạn 3 — Platform du lịch (12–24 tháng)

- [ ] Commission model trên booking B2C
- [ ] API marketplace / white-label
- [ ] AI gợi ý giá, dự báo occupancy ngày cao điểm

---

## 14. Chỉ số theo dõi (KPI gợi ý cho nhà đầu tư)

| Nhóm | KPI |
|---|---|
| **Growth** | Số OWNER đăng ký/tháng, số cơ sở active, số phòng trên nền tảng |
| **Conversion** | Trial → Paid rate, KYC approval rate, thời gian onboarding |
| **Revenue** | MRR, ARR, ARPU (average revenue per user), % yearly vs monthly |
| **Retention** | Churn rate hàng tháng, NPS, thời gian sử dụng app/ngày |
| **Trust** | Tỷ lệ khiếu nại, thời gian xử lý tranh chấp, rating trung bình |
| **Marketplace** | Booking qua kênh Halong24h vs direct, conversion FB/TikTok → platform |
| **Unit economics** | LTV/CAC ratio (target > 3), payback period (< 12 tháng) |

---

## Phụ lục — Sơ đồ tổng thể

```mermaid
flowchart TB
    subgraph Pain["Thị trường Hạ Long hiện tại"]
        P1[Sale tự do FB/TikTok/Zalo]
        P2[Khách bị lừa đảo]
        P3[OTA từ chối ngày cao điểm]
    end

    subgraph Platform["Halong24h Platform"]
        B2B[App quản lý — OWNER/SALE/ADMIN]
        B2C[Kênh khách — website/app *(roadmap)*]
        Trust[Cam kết: Có phòng · Giá tốt · Sạch · Đa dạng view]
    end

    subgraph Owners["Chủ nhà"]
        O1[Quản lý phòng trực tiếp]
        O2[Nhận lead tập trung]
        O3[KYC + listing chính thức]
    end

    subgraph Guests["Khách lưu trú"]
        G1[Đặt phòng yên tâm]
        G2[View biển · view phố · homestay]
    end

    subgraph Revenue["Doanh thu"]
        R1[Subscription SaaS]
        R2[Enterprise]
        R3[Commission B2C *(roadmap)*]
    end

    P1 --> Platform
    P2 --> Trust
    P3 --> Trust
    Owners --> B2B
    B2C --> Guests
    B2B --> Trust
    Trust --> Guests
    Platform --> R1
    Platform --> R2
    Platform --> R3
```

---

## Liên hệ & Tài liệu kỹ thuật bổ sung

| Tài liệu | Mô tả |
|---|---|
| `docs/FE_APP_ANDROID.md` | Chi tiết API ↔ màn hình (cho dev/QA) |
| `CLAUDE.md` | Conventions & architecture nội bộ |
| Swagger BE | `http://160.30.169.42/index.html` |

---

*Tài liệu v1.1 — mô tả tầm nhìn Halong24h, chi tiết gói subscription, cam kết khách hàng và trạng thái sản phẩm app mobile v1.1.4. Kênh đặt phòng B2C (website/app khách) nằm trong lộ trình; app hiện tại tập trung phía vận hành chủ nhà.*
