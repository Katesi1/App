# API SPECIFICATION — Halong24h Homestay Management

> Tài liệu đặc tả toàn bộ API cần thiết để app hoạt động trơn tru.
> Base URL: `http://103.183.118.148:3000`

---

## Mục lục

1. [Authentication](#1-authentication--xác-thực)
2. [Users](#2-users--quản-lý-người-dùng)
3. [Homestays](#3-homestays--cơ-sở-lưu-trú)
4. [Rooms](#4-rooms--quản-lý-phòng)
5. [Room Images](#5-room-images--ảnh-phòng)
6. [Room Prices](#6-room-prices--bảng-giá-phòng)
7. [Bookings (Staff/Admin)](#7-bookings-staffadmin--đặt-phòng-quản-lý)
8. [Bookings (Customer)](#8-bookings-customer--đặt-phòng-khách-hàng)
9. [Calendar Grid](#9-calendar-grid--lịch-phòng-mới)
10. [Notifications](#10-notifications--thông-báo)
11. [Dashboard / Reports](#11-dashboard--reports--thống-kê)
12. [Response Format](#12-response-format-chung)
13. [Auth Flow & Token](#13-auth-flow--token)
14. [Tổng kết endpoints](#14-tổng-kết-endpoints)

---

## 1. Authentication — Xác thực

### 1.1. Đăng ký
```
POST /auth/register
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `name` | string | ✅ | Họ tên |
| `phone` | string | ✅ | Số điện thoại (unique) |
| `password` | string | ✅ | Mật khẩu (min 6 ký tự) |
| `role` | string | ✅ | `STAFF` hoặc `CUSTOMER` |
| `email` | string | ❌ | Email (optional) |

**Response**: `{ success, data: { user, accessToken, refreshToken }, message }`

---

### 1.2. Đăng nhập
```
POST /auth/login
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `phone` | string | ✅ | Số điện thoại |
| `password` | string | ✅ | Mật khẩu |

**Response**: `{ success, data: { user, accessToken, refreshToken }, message }`

---

### 1.3. Đăng nhập Google
```
POST /auth/google
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `idToken` | string | ✅ | Google ID token |
| `role` | string | ❌ | Role nếu tạo user mới |

**Response**: Giống login

---

### 1.4. Refresh Token
```
POST /auth/refresh
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `refreshToken` | string | ✅ | Refresh token hiện tại |

**Response**: `{ success, data: { accessToken, refreshToken }, message }`

---

### 1.5. Đăng xuất
```
POST /auth/logout
Header: Authorization: Bearer {accessToken}
```
Không có body.

---

### 1.6. Lấy Profile
```
GET /auth/profile
Header: Authorization: Bearer {accessToken}
```
**Response**: `{ success, data: UserObject, message }`

---

### 1.7. Quên mật khẩu
```
POST /auth/forgot-password
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `identifier` | string | ✅ | SĐT hoặc email |

---

### 1.8. Reset mật khẩu
```
POST /auth/reset-password
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `token` | string | ✅ | Token từ email/SMS |
| `newPassword` | string | ✅ | Mật khẩu mới |

---

### 1.9. Đổi mật khẩu
```
PATCH /auth/change-password
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `currentPassword` | string | ✅ | Mật khẩu hiện tại |
| `newPassword` | string | ✅ | Mật khẩu mới |

---

## 2. Users — Quản lý người dùng

> Chỉ ADMIN mới có quyền CRUD users.

### 2.1. Danh sách users
```
GET /users?role={ADMIN|STAFF|CUSTOMER}
Header: Authorization: Bearer {accessToken}
```
| Query Param | Kiểu | Bắt buộc | Mô tả |
|-------------|-------|----------|-------|
| `role` | string | ❌ | Filter theo role |

**Response**: `{ success, data: [UserObject], message }`

---

### 2.2. Chi tiết user
```
GET /users/:id
Header: Authorization: Bearer {accessToken}
```

---

### 2.3. Tạo user
```
POST /users
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `name` | string | ✅ | Họ tên |
| `phone` | string | ✅ | SĐT (unique) |
| `password` | string | ✅ | Mật khẩu (min 6) |
| `role` | string | ✅ | `ADMIN`, `STAFF`, `CUSTOMER` |
| `email` | string | ❌ | Email |
| `isActive` | boolean | ❌ | Default: true |

---

### 2.4. Cập nhật user
```
PUT /users/:id
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `name` | string | ❌ | Họ tên |
| `phone` | string | ❌ | SĐT |
| `email` | string | ❌ | Email |
| `password` | string | ❌ | Mật khẩu mới |
| `role` | string | ❌ | Role |
| `isActive` | boolean | ❌ | Kích hoạt/vô hiệu hoá |
| `gender` | string | ❌ | Giới tính |
| `dateOfBirth` | string | ❌ | Ngày sinh |

---

### 2.5. Xoá (vô hiệu hoá) user
```
DELETE /users/:id
Header: Authorization: Bearer {accessToken}
```

---

### User Object (9 trường)
```json
{
  "id": "uuid",
  "name": "Nguyễn Văn A",
  "phone": "0912345678",
  "email": "a@gmail.com",
  "role": "STAFF",
  "isActive": true,
  "gender": "male",
  "dateOfBirth": "1990-01-15",
  "createdAt": "2026-01-01T00:00:00Z"
}
```

---

## 3. Homestays — Cơ sở lưu trú

### 3.1. Danh sách homestays
```
GET /homestays
Header: Authorization: Bearer {accessToken}
```
**Response**: `{ success, data: [HomestayObject], message }`

---

### 3.2. Chi tiết homestay
```
GET /homestays/:id
Header: Authorization: Bearer {accessToken}
```

---

### 3.3. Tạo homestay
```
POST /homestays
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `name` | string | ✅ | Tên cơ sở |
| `address` | string | ✅ | Địa chỉ |
| `ownerId` | string | ✅ | ID chủ nhà |
| `latitude` | double | ❌ | Vĩ độ |
| `longitude` | double | ❌ | Kinh độ |
| `mapLink` | string | ❌ | Link Google Maps |
| `isActive` | boolean | ❌ | Default: true |

---

### 3.4. Cập nhật homestay
```
PUT /homestays/:id
Header: Authorization: Bearer {accessToken}
```
Giống body tạo, tất cả optional.

---

### 3.5. Xoá homestay
```
DELETE /homestays/:id
Header: Authorization: Bearer {accessToken}
```

---

### Homestay Object (9 trường)
```json
{
  "id": "uuid",
  "ownerId": "uuid",
  "name": "Sunferia Villa",
  "address": "Bãi Cháy, Hạ Long",
  "latitude": 20.9555,
  "longitude": 107.0483,
  "mapLink": "https://maps.google.com/...",
  "isActive": true,
  "owner": { "id": "uuid", "name": "Chủ nhà A" },
  "_count": { "rooms": 12 }
}
```

---

## 4. Rooms — Quản lý phòng

### 4.1. Danh sách phòng
```
GET /rooms?homestayId={id}
Header: Authorization: Bearer {accessToken}
```
| Query Param | Kiểu | Bắt buộc | Mô tả |
|-------------|-------|----------|-------|
| `homestayId` | string | ❌ | Filter theo homestay |

---

### 4.2. Danh sách phòng công khai (Customer)
```
GET /rooms/public?checkinDate=&checkoutDate=&guests=&minPrice=&maxPrice=
```
| Query Param | Kiểu | Bắt buộc | Mô tả |
|-------------|-------|----------|-------|
| `checkinDate` | string (ISO) | ❌ | Ngày nhận phòng |
| `checkoutDate` | string (ISO) | ❌ | Ngày trả phòng |
| `guests` | int | ❌ | Số khách |
| `minPrice` | double | ❌ | Giá tối thiểu |
| `maxPrice` | double | ❌ | Giá tối đa |

---

### 4.3. Chi tiết phòng
```
GET /rooms/:id
Header: Authorization: Bearer {accessToken}
```

---

### 4.4. Tạo phòng
```
POST /rooms
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `homestayId` | string | ✅ | ID homestay chứa phòng |
| `name` | string | ✅ | Tên hiển thị |
| `code` | string | ✅ | Mã phòng (VD: C3-06) |
| `type` | string | ❌ | VILLA, HOMESTAY, APARTMENT, HOTEL |
| `bedrooms` | int | ❌ | Số phòng ngủ (default: 1) |
| `bathrooms` | int | ❌ | Số WC (default: 1) |
| `standardGuests` | int | ❌ | Sức chứa tiêu chuẩn (default: 2) |
| `maxGuests` | int | ❌ | Sức chứa tối đa (default: 2) |
| `description` | string | ❌ | Mô tả |
| `address` | string | ❌ | Địa chỉ riêng |
| `mapLink` | string | ❌ | Link Google Maps |
| `amenities` | string[] | ❌ | Danh sách tiện nghi |
| `cancellationPolicy` | string | ❌ | FLEXIBLE / MODERATE / STRICT |
| `adultSurcharge` | double | ❌ | Phụ thu người lớn |
| `childSurcharge` | double | ❌ | Phụ thu trẻ em |
| `isActive` | boolean | ❌ | Default: true |

**Tổng: 16 trường (3 bắt buộc, 13 optional)**

---

### 4.5. Cập nhật phòng
```
PUT /rooms/:id
Header: Authorization: Bearer {accessToken}
```
Giống body tạo, tất cả optional.

---

### 4.6. Xoá phòng
```
DELETE /rooms/:id
Header: Authorization: Bearer {accessToken}
```

---

### Room Object (20 trường)
```json
{
  "id": "uuid",
  "homestayId": "uuid",
  "name": "Villa Sunferia C3",
  "code": "C3-06",
  "type": "VILLA",
  "bedrooms": 3,
  "bathrooms": 2,
  "standardGuests": 6,
  "maxGuests": 10,
  "description": "Villa view biển...",
  "address": "Bãi Cháy, Hạ Long",
  "mapLink": "https://maps.google.com/...",
  "amenities": ["Wifi", "Bể bơi", "BBQ"],
  "cancellationPolicy": "MODERATE",
  "adultSurcharge": 200000,
  "childSurcharge": 100000,
  "isActive": true,
  "images": [RoomImageObject],
  "price": RoomPriceObject,
  "homestay": {
    "id": "uuid",
    "name": "Sunferia",
    "address": "Bãi Cháy"
  }
}
```

---

## 5. Room Images — Ảnh phòng

### 5.1. Upload ảnh
```
POST /rooms/:roomId/images
Header: Authorization: Bearer {accessToken}
Content-Type: multipart/form-data
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `images` | File[] | ✅ | Tối đa 20 ảnh |

**Response**: `{ success, data: [RoomImageObject], message }`

---

### 5.2. Xoá ảnh
```
DELETE /rooms/:roomId/images/:imageId
Header: Authorization: Bearer {accessToken}
```

---

### 5.3. Set ảnh bìa
```
PATCH /rooms/:roomId/images/:imageId/cover
Header: Authorization: Bearer {accessToken}
```
Không có body.

---

### Room Image Object (6 trường)
```json
{
  "id": "uuid",
  "roomId": "uuid",
  "imageUrl": "https://res.cloudinary.com/...",
  "publicId": "homestay/abc123",
  "isCover": true,
  "order": 0
}
```

---

## 6. Room Prices — Bảng giá phòng

### 6.1. Upsert giá phòng
```
PUT /rooms/:roomId/prices
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `weekdayPrice` | double | ✅ | Giá ngày thường (T2-T5) |
| `fridayPrice` | double | ✅ | Giá thứ 6 |
| `saturdayPrice` | double | ✅ | Giá thứ 7 |
| `holidayPrice` | double | ✅ | Giá ngày lễ / cao điểm |

**Tổng: 4 trường, tất cả bắt buộc**

---

### Room Price Object (6 trường)
```json
{
  "id": "uuid",
  "roomId": "uuid",
  "weekdayPrice": 5000000,
  "fridayPrice": 7000000,
  "saturdayPrice": 8000000,
  "holidayPrice": 12000000
}
```

---

## 7. Bookings (Staff/Admin) — Đặt phòng quản lý

### 7.1. Danh sách bookings
```
GET /bookings?roomId={id}
Header: Authorization: Bearer {accessToken}
```
| Query Param | Kiểu | Bắt buộc | Mô tả |
|-------------|-------|----------|-------|
| `roomId` | string | ❌ | Filter theo phòng |

---

### 7.2. Giữ phòng (Hold)
```
POST /bookings/hold
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `roomId` | string | ✅ | ID phòng |
| `checkinDate` | string (ISO) | ✅ | Ngày nhận phòng |
| `checkoutDate` | string (ISO) | ✅ | Ngày trả phòng |
| `customerName` | string | ❌ | Tên khách |
| `customerPhone` | string | ❌ | SĐT khách |
| `depositAmount` | double | ❌ | Tiền cọc |
| `notes` | string | ❌ | Ghi chú |

**Tổng: 7 trường (3 bắt buộc, 4 optional)**

**Logic**: Giữ phòng 30 phút → tự động huỷ nếu chưa confirm.

---

### 7.3. Xác nhận booking
```
PATCH /bookings/:id/confirm
Header: Authorization: Bearer {accessToken}
```
Không có body. Chuyển status `HOLD` → `CONFIRMED`.

---

### 7.4. Huỷ booking
```
PATCH /bookings/:id/cancel
Header: Authorization: Bearer {accessToken}
```
Không có body. Chuyển status → `CANCELLED`.

---

### 7.5. Cập nhật booking
```
PUT /bookings/:id
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `checkinDate` | string (ISO) | ❌ | Ngày nhận phòng |
| `checkoutDate` | string (ISO) | ❌ | Ngày trả phòng |
| `customerName` | string | ❌ | Tên khách |
| `customerPhone` | string | ❌ | SĐT khách |
| `depositAmount` | double | ❌ | Tiền cọc |
| `notes` | string | ❌ | Ghi chú |
| `status` | string | ❌ | HOLD/CONFIRMED/CANCELLED/COMPLETED |

---

### 7.6. Lịch booking theo phòng
```
GET /bookings/calendar/:roomId?year={year}&month={month}
Header: Authorization: Bearer {accessToken}
```
| Query Param | Kiểu | Bắt buộc | Mô tả |
|-------------|-------|----------|-------|
| `year` | int | ✅ | Năm |
| `month` | int | ✅ | Tháng |

**Response**: `{ success, data: [CalendarBookingObject], message }`

---

### Booking Object (14 trường)
```json
{
  "id": "uuid",
  "roomId": "uuid",
  "saleId": "uuid",
  "checkinDate": "2026-04-20T14:00:00Z",
  "checkoutDate": "2026-04-22T12:00:00Z",
  "status": "CONFIRMED",
  "holdExpireAt": "2026-04-20T14:30:00Z",
  "customerName": "Nguyễn Văn B",
  "customerPhone": "0987654321",
  "depositAmount": 2000000,
  "notes": "Cần thêm đệm",
  "holdRemainingSeconds": 0,
  "room": {
    "id": "uuid",
    "name": "C3-06",
    "code": "C3-06",
    "homestay": { "name": "Sunferia" }
  },
  "sale": {
    "id": "uuid",
    "name": "Nhân viên A"
  }
}
```

### Calendar Booking Object (5 trường)
```json
{
  "id": "uuid",
  "checkinDate": "2026-04-20T14:00:00Z",
  "checkoutDate": "2026-04-22T12:00:00Z",
  "status": "CONFIRMED",
  "customerName": "Nguyễn Văn B",
  "holdRemainingSeconds": 0
}
```

---

## 8. Bookings (Customer) — Đặt phòng khách hàng

### 8.1. Khách giữ phòng
```
POST /bookings/customer-hold
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `roomId` | string | ✅ | ID phòng |
| `checkinDate` | string (ISO) | ✅ | Ngày nhận phòng |
| `checkoutDate` | string (ISO) | ✅ | Ngày trả phòng |
| `customerName` | string | ❌ | Tên khách |
| `customerPhone` | string | ❌ | SĐT khách |
| `notes` | string | ❌ | Ghi chú |

---

### 8.2. Booking của tôi
```
GET /bookings/my?status={status}
Header: Authorization: Bearer {accessToken}
```
| Query Param | Kiểu | Bắt buộc | Mô tả |
|-------------|-------|----------|-------|
| `status` | string | ❌ | HOLD, CONFIRMED, CANCELLED |

---

### 8.3. Khách huỷ booking
```
PATCH /bookings/:id/customer-cancel
Header: Authorization: Bearer {accessToken}
```
Chỉ huỷ được booking có status `HOLD`.

---

## 9. Calendar Grid — Lịch phòng (MỚI)

> API mới cần tạo cho tính năng lịch grid (rooms × dates).
> Dùng chung cho cả **lịch tổng** (BookingCalendarScreen) và **lịch chủ nhà** (OwnerCalendarScreen).

### 9.1. Lấy danh sách property groups
```
GET /calendar/property-groups?category={VILLA|HOMESTAY|HOTEL}&ownerId={id}
Header: Authorization: Bearer {accessToken}
```
| Query Param | Kiểu | Bắt buộc | Mô tả |
|-------------|-------|----------|-------|
| `category` | string | ❌ | VILLA, HOMESTAY, HOTEL |
| `ownerId` | string | ❌ | Filter theo chủ nhà (cho lịch riêng) |

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Sunferia",
      "category": "VILLA",
      "roomCount": 12
    }
  ]
}
```

### PropertyGroup Object (4 trường)
```json
{
  "id": "uuid",
  "name": "Sunferia",
  "category": "VILLA",
  "roomCount": 12
}
```

---

### 9.2. Lấy calendar grid data
```
GET /calendar/grid?propertyGroupId={id}&startDate={ISO}&endDate={ISO}
Header: Authorization: Bearer {accessToken}
```
| Query Param | Kiểu | Bắt buộc | Mô tả |
|-------------|-------|----------|-------|
| `propertyGroupId` | string | ✅ | ID nhóm property |
| `startDate` | string (ISO) | ✅ | Ngày bắt đầu |
| `endDate` | string (ISO) | ✅ | Ngày kết thúc |

**Response**:
```json
{
  "success": true,
  "data": {
    "propertyGroup": {
      "id": "uuid",
      "name": "Sunferia"
    },
    "rooms": [
      {
        "id": "uuid",
        "code": "C3-06",
        "days": [
          {
            "date": "2026-04-21",
            "price": 5000000,
            "status": "AVAILABLE"
          },
          {
            "date": "2026-04-22",
            "price": 5000000,
            "status": "BOOKED"
          },
          {
            "date": "2026-04-23",
            "price": 8000000,
            "status": "HOLD"
          }
        ]
      }
    ]
  }
}
```

### CalendarDay Object (3 trường)
| Trường | Kiểu | Mô tả |
|--------|-------|-------|
| `date` | string (YYYY-MM-DD) | Ngày |
| `price` | double | Giá phòng ngày đó |
| `status` | string | `AVAILABLE`, `BOOKED`, `HOLD` |

---

### 9.3. Lock phòng (chủ nhà)
```
POST /calendar/lock
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `roomId` | string | ✅ | ID phòng |
| `date` | string (ISO) | ✅ | Ngày cần lock |

**Logic**: Chuyển ngày đó thành status `HOLD` cho phòng đó.

---

### 9.4. Unlock phòng (chủ nhà)
```
POST /calendar/unlock
Header: Authorization: Bearer {accessToken}
```
| Trường | Kiểu | Bắt buộc | Mô tả |
|--------|-------|----------|-------|
| `roomId` | string | ✅ | ID phòng |
| `date` | string (ISO) | ✅ | Ngày cần unlock |

**Logic**: Chuyển ngày đó thành status `AVAILABLE`. Chỉ unlock được `HOLD`, không unlock được `BOOKED`.

---

### 9.5. Lấy thông tin liên hệ admin (cho lịch tổng)
```
GET /calendar/admin-contact
```
**Response**:
```json
{
  "success": true,
  "data": {
    "name": "Admin Halong24h",
    "phone": "0912345678",
    "zaloUrl": "https://zalo.me/0912345678"
  }
}
```

### AdminContact Object (3 trường)
```json
{
  "name": "Admin Halong24h",
  "phone": "0912345678",
  "zaloUrl": "https://zalo.me/0912345678"
}
```

---

## 10. Notifications — Thông báo

> Hiện tại app dùng mock data. Cần API thật.

### 10.1. Danh sách thông báo
```
GET /notifications
Header: Authorization: Bearer {accessToken}
```

### 10.2. Số thông báo chưa đọc
```
GET /notifications/unread-count
Header: Authorization: Bearer {accessToken}
```
**Response**: `{ success, data: { count: 5 }, message }`

### 10.3. Đánh dấu đã đọc
```
PATCH /notifications/:id/read
Header: Authorization: Bearer {accessToken}
```

### 10.4. Đánh dấu tất cả đã đọc
```
PATCH /notifications/read-all
Header: Authorization: Bearer {accessToken}
```

### Notification Object (8 trường)
```json
{
  "id": "uuid",
  "title": "Booking mới",
  "subtitle": "Phòng C3-06 được đặt bởi Nguyễn Văn B",
  "type": "BOOKING",
  "isRead": false,
  "createdAt": "2026-04-20T10:30:00Z",
  "targetId": "booking-uuid",
  "targetType": "booking"
}
```

| type | Mô tả |
|------|-------|
| `BOOKING` | Thông báo về booking |
| `PAYMENT` | Thông báo thanh toán |
| `SYSTEM` | Thông báo hệ thống |

---

## 11. Dashboard / Reports — Thống kê

> Hiện tại app tự tính KPI từ rooms + bookings list.
> Nên có API riêng để tối ưu performance.

### 11.1. Dashboard KPIs
```
GET /dashboard/stats
Header: Authorization: Bearer {accessToken}
```
**Response**:
```json
{
  "success": true,
  "data": {
    "totalRooms": 24,
    "activeRooms": 22,
    "emptyRooms": 8,
    "occupiedRooms": 12,
    "checkoutToday": 4,
    "totalBookings": 156,
    "thisMonthBookings": 23,
    "monthlyRevenue": 184500000,
    "todayRevenue": 6200000
  }
}
```

### DashboardStats Object (9 trường)
| Trường | Kiểu | Mô tả |
|--------|-------|-------|
| `totalRooms` | int | Tổng số phòng |
| `activeRooms` | int | Phòng đang hoạt động |
| `emptyRooms` | int | Phòng trống hôm nay |
| `occupiedRooms` | int | Phòng đang có khách |
| `checkoutToday` | int | Checkout hôm nay |
| `totalBookings` | int | Tổng booking |
| `thisMonthBookings` | int | Booking tháng này |
| `monthlyRevenue` | double | Doanh thu tháng (VNĐ) |
| `todayRevenue` | double | Doanh thu hôm nay (VNĐ) |

---

### 11.2. Report Data
```
GET /reports?month={month}&year={year}
Header: Authorization: Bearer {accessToken}
```
**Response**:
```json
{
  "success": true,
  "data": {
    "totalRooms": 24,
    "activeRooms": 22,
    "totalBookings": 156,
    "thisMonthBookings": 23,
    "holdCount": 5,
    "confirmedCount": 15,
    "cancelledCount": 3,
    "completedCount": 133,
    "totalDeposit": 45000000,
    "occupancyRate": 75.5,
    "roomsWithCover": 20,
    "roomsWithPrice": 22,
    "recentBookings": [BookingObject]
  }
}
```

### ReportData Object (13 trường)
| Trường | Kiểu | Mô tả |
|--------|-------|-------|
| `totalRooms` | int | Tổng phòng |
| `activeRooms` | int | Phòng hoạt động |
| `totalBookings` | int | Tổng booking |
| `thisMonthBookings` | int | Booking tháng này |
| `holdCount` | int | Số booking đang giữ |
| `confirmedCount` | int | Số booking đã xác nhận |
| `cancelledCount` | int | Số booking đã huỷ |
| `completedCount` | int | Số booking hoàn thành |
| `totalDeposit` | double | Tổng tiền cọc (VNĐ) |
| `occupancyRate` | double | Tỷ lệ lấp đầy (%) |
| `roomsWithCover` | int | Phòng có ảnh bìa |
| `roomsWithPrice` | int | Phòng có giá |
| `recentBookings` | BookingObject[] | Booking gần đây |

---

## 12. Response Format chung

### Success
```json
{
  "success": true,
  "data": { ... },
  "message": "Thành công"
}
```

### Error
```json
{
  "success": false,
  "data": null,
  "message": "Mô tả lỗi"
}
```

### HTTP Status Codes
| Code | Ý nghĩa |
|------|---------|
| 200 | Thành công |
| 201 | Tạo mới thành công |
| 400 | Bad Request (thiếu/sai trường) |
| 401 | Unauthorized (token hết hạn) |
| 403 | Forbidden (không đủ quyền) |
| 404 | Not Found |
| 409 | Conflict (duplicate phone, phòng đã bán) |
| 500 | Server Error |

---

## 13. Auth Flow & Token

### Flow
```
Login/Register → { accessToken (15min), refreshToken }
    ↓
Mỗi request gắn Header: Authorization: Bearer {accessToken}
    ↓
Khi 401 → POST /auth/refresh { refreshToken }
    ↓
Nhận accessToken mới → retry request
    ↓
Nếu refresh cũng fail → logout, redirect /login
```

### Token Storage
| Key | Nơi lưu | Mô tả |
|-----|---------|-------|
| `access_token` | FlutterSecureStorage | JWT access token |
| `refresh_token` | FlutterSecureStorage | JWT refresh token |
| `user_data` | FlutterSecureStorage | User JSON string |

### Timeout
- Connection: 30s
- Receive: 30s

---

## 14. Tổng kết endpoints

### Đã có (đang hoạt động) — 28 endpoints

| # | Method | Endpoint | Mô tả |
|---|--------|----------|-------|
| 1 | POST | `/auth/register` | Đăng ký |
| 2 | POST | `/auth/login` | Đăng nhập |
| 3 | POST | `/auth/google` | Đăng nhập Google |
| 4 | POST | `/auth/refresh` | Refresh token |
| 5 | POST | `/auth/logout` | Đăng xuất |
| 6 | GET | `/auth/profile` | Lấy profile |
| 7 | POST | `/auth/forgot-password` | Quên mật khẩu |
| 8 | POST | `/auth/reset-password` | Reset mật khẩu |
| 9 | PATCH | `/auth/change-password` | Đổi mật khẩu |
| 10 | GET | `/users` | DS users |
| 11 | GET | `/users/:id` | Chi tiết user |
| 12 | POST | `/users` | Tạo user |
| 13 | PUT | `/users/:id` | Sửa user |
| 14 | DELETE | `/users/:id` | Xoá user |
| 15 | GET | `/homestays` | DS homestays |
| 16 | GET | `/homestays/:id` | Chi tiết homestay |
| 17 | POST | `/homestays` | Tạo homestay |
| 18 | PUT | `/homestays/:id` | Sửa homestay |
| 19 | DELETE | `/homestays/:id` | Xoá homestay |
| 20 | GET | `/rooms` | DS phòng |
| 21 | GET | `/rooms/:id` | Chi tiết phòng |
| 22 | GET | `/rooms/public` | DS phòng công khai |
| 23 | POST | `/rooms` | Tạo phòng |
| 24 | PUT | `/rooms/:id` | Sửa phòng |
| 25 | DELETE | `/rooms/:id` | Xoá phòng |
| 26 | POST | `/rooms/:roomId/images` | Upload ảnh |
| 27 | DELETE | `/rooms/:roomId/images/:imageId` | Xoá ảnh |
| 28 | PATCH | `/rooms/:roomId/images/:imageId/cover` | Set ảnh bìa |
| 29 | PUT | `/rooms/:roomId/prices` | Upsert giá |
| 30 | GET | `/bookings` | DS bookings |
| 31 | POST | `/bookings/hold` | Giữ phòng |
| 32 | GET | `/bookings/calendar/:roomId` | Lịch phòng |
| 33 | PATCH | `/bookings/:id/confirm` | Xác nhận |
| 34 | PATCH | `/bookings/:id/cancel` | Huỷ booking |
| 35 | PUT | `/bookings/:id` | Sửa booking |
| 36 | POST | `/bookings/customer-hold` | Khách giữ phòng |
| 37 | GET | `/bookings/my` | Booking của tôi |
| 38 | PATCH | `/bookings/:id/customer-cancel` | Khách huỷ |

### Cần tạo mới — 9 endpoints

| # | Method | Endpoint | Mô tả | Ưu tiên |
|---|--------|----------|-------|---------|
| 39 | GET | `/calendar/property-groups` | DS nhóm property | **CAO** |
| 40 | GET | `/calendar/grid` | Data lịch grid | **CAO** |
| 41 | POST | `/calendar/lock` | Khoá phòng | **CAO** |
| 42 | POST | `/calendar/unlock` | Mở khoá phòng | **CAO** |
| 43 | GET | `/calendar/admin-contact` | Thông tin liên hệ | TRUNG BÌNH |
| 44 | GET | `/notifications` | DS thông báo | TRUNG BÌNH |
| 45 | GET | `/notifications/unread-count` | Số chưa đọc | TRUNG BÌNH |
| 46 | PATCH | `/notifications/:id/read` | Đánh dấu đã đọc | TRUNG BÌNH |
| 47 | PATCH | `/notifications/read-all` | Đọc tất cả | TRUNG BÌNH |
| 48 | GET | `/dashboard/stats` | KPI dashboard | THẤP (app tự tính) |
| 49 | GET | `/reports` | Báo cáo | THẤP (app tự tính) |

### Tổng: 49 endpoints (38 đã có + 11 cần tạo mới)

---

## Phụ lục: Tổng số trường theo Object

| Object | Số trường | Ghi chú |
|--------|-----------|---------|
| User | 9 | 5 bắt buộc khi tạo |
| Homestay | 9 | 3 bắt buộc khi tạo |
| Room | 20 | 3 bắt buộc khi tạo, 13 optional |
| RoomImage | 6 | Upload qua multipart |
| RoomPrice | 6 | 4 giá bắt buộc |
| Booking | 14 | 3 bắt buộc khi hold |
| CalendarBooking | 5 | Lightweight cho calendar |
| CalendarDay | 3 | Cho grid calendar |
| PropertyGroup | 4 | Cho category tabs |
| AdminContact | 3 | Cho liên hệ Zalo |
| Notification | 8 | Cho push notification |
| DashboardStats | 9 | Cho trang tổng quan |
| ReportData | 13 | Cho trang báo cáo |
| **Tổng** | **109 trường** | |
