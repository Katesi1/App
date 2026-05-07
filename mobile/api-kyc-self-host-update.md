# API Update — Bỏ FPT.AI, frontend tự extract OCR/QR

> **Áp dụng cho**: Team backend Halong24h API
> **Supersedes**: phần "FPT.AI integration" trong [`api-kyc-implementation-spec.md`](api-kyc-implementation-spec.md) mục 2 + [`BACKEND_CHANGES_REPORT.md`](BACKEND_CHANGES_REPORT.md) mục 15
> **Ngày update**: 2026-05-04

---

## Quyết định

Halong24h là app **internal cho 1 chủ doanh nghiệp** (không phải SaaS phục vụ nhiều khách), KHÔNG phụ thuộc bên thứ 3.

→ Bỏ tích hợp **FPT.AI eKYC**. Toàn bộ extract data làm **client-side** trên app Flutter:
- **Mặt trước CCCD**: ML Kit Text Recognition (on-device, free) → parse text → extract fields
- **Mặt sau CCCD**: ML Kit Barcode Scanning (on-device, free) → decode QR code chip mới → 100% chính xác
- **Selfie**: chỉ ảnh, không OCR/face match. Admin duyệt thủ công

→ Backend chỉ cần: **upload ảnh lên Cloudinary** + **lưu OCR/QR JSON từ client gửi lên** + **để admin duyệt thủ công**.

---

## Thay đổi endpoint

### `POST /kyc/upload-cccd-front` + `POST /kyc/upload-cccd-back`

**KHÔNG đổi URL/method**. Chỉ thêm 1 multipart field optional:

```http
POST /kyc/upload-cccd-front
Content-Type: multipart/form-data
Authorization: Bearer <OWNER_TOKEN>

image: <binary jpg/png>
ocrResult: '{                                    ← MỚI, optional
  "cccdNumber": "012345678901",
  "fullName": "NGUYỄN VĂN A",
  "dob": "01/01/1990",
  "gender": "Nam",
  "address": "123 Đường ABC, Phường XYZ, TP. HCM",
  "expiryDate": "01/01/2030"
}'
```

**Backend xử lý**:
1. Lấy/tạo `kyc_submission` cho user (giữ logic cũ)
2. Upload `image` lên Cloudinary → trả `imageUrl`
3. Parse field `ocrResult` (JSON string) nếu có → lưu nguyên xi vào `kyc_uploads.ocr_result` (column JSONB đã có)
4. **BỎ**: gọi FPT.AI ID Recognition / OCR engine
5. **BỎ**: tính `confidence` — luôn trả `null` (frontend đã handle null = "skip warning, admin duyệt")

**Response không đổi** — vẫn theo schema cũ:
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "imageUrl": "https://res.cloudinary.com/...",
    "ocrResult": { ...nguyên xi từ client... },
    "confidence": null,
    "uploadedAt": "..."
  }
}
```

### `POST /kyc/upload-selfie`

**Không đổi gì**. Backend chỉ:
1. Upload ảnh lên Cloudinary
2. Lưu URL vào `kyc_uploads`
3. **BỎ**: gọi FPT.AI Face Match
4. **Luôn trả `faceMatchScore: null`, `isValid: true`** — admin nhìn ảnh CCCD + selfie trong queue và quyết định

---

## QR mặt sau — format chuẩn để backend hiểu

Frontend đã decode QR và gửi parsed JSON lên — backend KHÔNG cần parse lại. Tuy nhiên để team backend nắm:

```
<cccdId 12 digits>|<cmndCu 9 digits or empty>|<hoTen>|<dob ddMMyyyy>|<gioiTinh>|<queQuan>|<diaChi>|<ngayCap ddMMyyyy>
```

→ Frontend trả `ocrResult` JSON với 8 field tương ứng:
```json
{
  "cccdNumber": "012345678901",
  "oldCmndNumber": "025212345",
  "fullName": "NGUYỄN VĂN A",
  "dob": "01/01/1990",
  "gender": "Nam",
  "hometown": "Xã ABC, Huyện XYZ, Tỉnh DEF",
  "address": "123 Đường ABC, Phường XYZ, Quận DEF, TP. HCM",
  "issueDate": "01/01/2021"
}
```

→ Backend lưu nguyên xi vào `kyc_uploads.ocr_result`. Admin queue UI hiển thị các field này.

---

## DB schema — thêm 3 cột optional vào `kyc_uploads`

(Hoặc giữ nguyên cột `ocr_result` JSONB và để các field nằm trong JSON — tuỳ team backend chọn.)

Nếu muốn flat columns cho query nhanh:
```sql
ALTER TABLE kyc_uploads
  ADD COLUMN cccd_number VARCHAR(20),
  ADD COLUMN full_name TEXT,
  ADD COLUMN dob VARCHAR(10),
  ADD COLUMN gender VARCHAR(8),
  ADD COLUMN address TEXT,
  ADD COLUMN expiry_date VARCHAR(10),
  ADD COLUMN old_cmnd_number VARCHAR(10),
  ADD COLUMN hometown TEXT,
  ADD COLUMN issue_date VARCHAR(10);
```

→ Trigger update từ JSON `ocr_result` khi insert/update. Optional optimization.

---

---

## Update mới (2026-05-04): Đổi sang 6 tier cố định theo số phòng

**KHÔNG còn 3 tier (Starter/Pro/Enterprise) + user nhập số phòng tự do**.
Giờ là **6 tier theo số phòng cố định** — số phòng = thuộc tính của tier:

| Plan ID (mới) | Tier name | Rooms | Monthly (VND) |
|---|---|:-:|---:|
| `rooms_1` | Mini | 1 | 199.000 |
| `rooms_5` | Starter | 5 | 599.000 |
| `rooms_10` | Standard | 10 | 999.000 |
| `rooms_20` | Pro | 20 | 1.799.000 |
| `rooms_50` | Business | 50 | 3.999.000 |
| `enterprise` | Enterprise | ∞ | `null` ("Liên hệ") |

→ User pick tier → frontend gửi `planId = "rooms_5"` (vd) → `rooms = 5` (auto from tier). Yearly discount 20% + VAT 10% giữ nguyên cách tính.

### Backend cần update

1. **Bảng `billing_plans`** — re-seed 6 plan mới:
   ```sql
   DELETE FROM billing_plans WHERE id IN ('starter', 'professional', 'enterprise');

   INSERT INTO billing_plans (id, name, monthly_price, rooms, sort_order, features) VALUES
     ('rooms_1',     'Mini',        199000,    1,  10, '["Booking + Calendar","Check-in/out","Báo cáo cơ bản"]'),
     ('rooms_5',     'Starter',     599000,    5,  20, '["Tất cả Mini","Pricing rules cơ bản","Multi-staff (3 nv)"]'),
     ('rooms_10',    'Standard',    999000,   10,  30, '["Tất cả Starter","Dynamic pricing","Housekeeping","Báo cáo nâng cao"]'),
     ('rooms_20',    'Pro',         1799000,  20,  40, '["Tất cả Standard","Multi-staff không giới hạn","Multi-property"]'),
     ('rooms_50',    'Business',    3999000,  50,  50, '["Tất cả Pro","Channel sync","API + Webhook"]'),
     ('enterprise',  'Enterprise',  NULL,     -1,  60, '["Số phòng không giới hạn","Hợp đồng tuỳ biến","SLA + hỗ trợ 24/7","Onboarding 1-1"]');
   ```

2. **Bỏ field cũ** — schema `billing_plans` cần đổi (nếu chưa thì migration):
   - BỎ: `price_per_room`, `min_charge`, `max_rooms`, `yearly_discount_pct`, `vat_pct`
   - THÊM: `monthly_price INT NULL` (NULL = "Liên hệ" cho enterprise), `rooms INT` (-1 = unlimited)
   - Yearly discount + VAT giờ là constant ở app (20% + 10%) — không cần cột

3. **`POST /payments/initiate`** — body field `planId` đổi sang ID mới (`rooms_1|rooms_5|...|enterprise`). Validate `totalAmount` theo công thức:
   ```
   monthly = plan.monthlyPrice
   subtotal = (cycle == 'yearly') ? monthly * 12 * 0.8 : monthly
   total    = round(subtotal * 1.10)   // VAT 10%
   ```
   Sai lệch > 1% → 400 `amount_mismatch`.

4. **Enterprise**: KHÔNG được initiate payment với `planId='enterprise'` — frontend redirect user về help thay vì payment. Backend reject với 400 `enterprise_requires_contact` nếu nhận.

5. **`expectedRooms` field** trong `kyc_submissions` + `payment_sessions` — vẫn lưu, giá trị = `plan.rooms` (frontend gửi sẵn). Admin queue UI dùng để hiển thị.

### `GET /billing/plans` — response shape mới

```json
{
  "success": true,
  "data": [
    {
      "id": "rooms_1",
      "name": "Mini",
      "tier": "rooms1",
      "rooms": 1,
      "monthlyPrice": 199000,
      "features": ["Booking + Calendar", ...]
    },
    ...
    {
      "id": "enterprise",
      "name": "Enterprise",
      "tier": "enterprise",
      "rooms": -1,
      "monthlyPrice": null,
      "features": [...]
    }
  ]
}
```

→ Frontend đã handle `monthlyPrice: null` = hiển thị "Liên hệ".

---

## Bỏ khỏi backend

| Module | Trạng thái |
|---|---|
| `services/fptai.js` (FPT.AI wrapper) | **BỎ** — không cần wire |
| ENV vars `FPT_AI_API_KEY`, `FPT_AI_API_SECRET` | **BỎ** — không cần |
| Phụ thuộc HTTP client gọi FPT.AI | **BỎ** |
| Logic auto-set `isValid` dựa trên `faceMatchScore` | **BỎ** — admin set khi approve |

---

## Lợi ích

- **Tiết kiệm**: ~5-15k VND/lượt verify (FPT.AI charge per call) → 0đ
- **Không phụ thuộc**: FPT.AI down/đổi pricing không ảnh hưởng app
- **Privacy tốt hơn**: Ảnh CCCD KHÔNG gửi cho bên thứ 3 (chỉ Cloudinary của bạn)
- **Giảm latency**: Không gọi external API → upload nhanh hơn
- **Đơn giản hơn**: Backend chỉ làm storage + admin queue, không quản lý API key/quota provider

## Trade-off

- **Mặt trước CCCD độ chính xác ~85-90%** (ML Kit OCR text) thay vì ~98% (FPT.AI). Admin sẽ thấy trong queue và sửa thủ công khi cần.
- **CCCD chip cũ (CMND 9 số)** không có QR mặt sau → frontend gửi `ocrResult: null` cho mặt sau → admin nhập tay khi review. Số lượng dùng CMND cũ giảm dần (Bộ CA đã ngừng cấp từ 2021).

---

## PROMPT cho AI implement update backend

```
Bạn là backend engineer làm việc trên repo Halong24h API. Update KYC endpoints:

1. BỎ tích hợp FPT.AI eKYC hoàn toàn:
   - Xoá `services/fptai.js` (hoặc tương đương)
   - Xoá ENV vars FPT_AI_*
   - Xoá HTTP client gọi FPT.AI

2. SỬA POST /kyc/upload-cccd-front + POST /kyc/upload-cccd-back:
   - Multipart body: thêm field optional `ocrResult` (JSON string) — frontend gửi data đã extract trên device
   - Backend: parse JSON → lưu nguyên xi vào kyc_uploads.ocr_result (JSONB column đã có)
   - BỎ: gọi OCR engine
   - Luôn trả confidence = null trong response
   - Response schema giữ nguyên (frontend đã handle confidence null)

3. SỬA POST /kyc/upload-selfie:
   - BỎ: gọi face match
   - Luôn trả faceMatchScore = null, isValid = true
   - Admin sẽ duyệt thủ công khi xem ảnh trong queue

4. GIỮ NGUYÊN:
   - Upload ảnh lên Cloudinary
   - Endpoint structure (URL, method, auth, response wrapper)
   - GET /admin/kyc/queue + approve/reject endpoints

5. ADMIN QUEUE UI (nếu có):
   - Hiển thị ocrResult JSON đã lưu (cccdNumber, fullName, dob, gender, address, expiryDate, oldCmndNumber, hometown, issueDate)
   - Cho phép admin sửa các field này trước khi approve (nếu OCR đọc sai)

OUTPUT: diff các file đã sửa + brief PR description tiếng Việt nêu impact (giảm chi phí, tăng privacy, độ chính xác giảm nhẹ nhưng admin duyệt nên OK).
```
