# Report cho BE — 409 `paymentPending` thiếu `pendingSession.sessionId`

> **From**: FE Mobile (Flutter — Halong24h OWNER app)  
> **To**: BE team  
> **Date**: 2026-06-06  
> **Status**: ✅ **RESOLVED** — 2026-06-06 (BE live PID 12884)  
> **Priority**: P1 — chặn user huỷ phiên cũ & tạo phiên mới  
> **Environment**: `https://api.halong24h.com` (prod)  
> **Spec tham chiếu**: `docs/API_SPEC_FULL.md` §10.2.6  
> **FE liên quan**: `lib/features/verify/utils/payment_pending_handler.dart`

---

## 1. Tóm tắt

User báo lỗi trên app:

> **「Không xác định được phiên cũ. Vui lòng thử lại sau.」**

**Đây KHÔNG phải lỗi FE “không biết tài khoản nào có phiên nào”.**  
FE đã xác định đúng user qua **Bearer token** — request `POST /payments/initiate` hoặc `POST /payments/renew` trả **409 `paymentPending`**, modal hiện đúng.

Lỗi xảy ra khi user chọn **「Huỷ phiên & tạo mới」**: FE cần `sessionId` từ body 409 để gọi:

```http
POST /payments/:sessionId/cancel
```

Nếu **`pendingSession` thiếu hoặc không có `sessionId`**, FE không thể huỷ phiên → hiện message trên.

---

## 2. Luồng FE (để BE reproduce)

```
1. User OWNER đăng nhập (token hợp lệ)
2. Tạo phiên CK: POST /payments/initiate hoặc POST /payments/renew
   → session status = pending, user chưa chuyển khoản / chưa mark-paid
3. User thử mua gói khác (hoặc gia hạn lại):
   POST /payments/initiate  hoặc  POST /payments/renew
4. BE trả 409 paymentPending → FE hiện bottom sheet:
   - 「Tiếp tục phiên cũ」 → GET /payments/active
   - 「Huỷ phiên & tạo mới」 → POST /payments/:sessionId/cancel → retry initiate/renew
5. User chọn 「Huỷ phiên & tạo mới」
6. FE đọc error.pendingSession.sessionId từ body bước 4
   → Nếu null/empty → toast 「Không xác định được phiên cũ...」  ← BUG
```

**FE không tự suy ra sessionId** — chỉ dùng field BE trả trong 409, hoặc fallback `GET /payments/active` (chỉ dùng cho luồng “tiếp tục”, không dùng cho cancel trong bản hiện tại).

---

## 3. Contract bắt buộc (§10.2.6)

Khi `POST /payments/initiate` hoặc `POST /payments/renew` bị chặn vì đã có session `pending`, BE **PHẢI** trả:

| Field | Bắt buộc | Ghi chú |
|---|---|---|
| HTTP status | `409` | |
| `code` | `"paymentPending"` | FE parse từ **root body** |
| `message` | string (i18n vi/en) | Hiển thị trực tiếp |
| `pendingSession` | object | **Không được null/thiếu** |
| `pendingSession.sessionId` | UUID string | Dùng cho `POST /payments/:id/cancel` |
| `pendingSession.expiresAt` | ISO 8601 | TTL 24h |
| `pendingSession.totalAmount` | int VND | |
| `pendingSession.kind` | `subscription\|renew\|upgrade\|...` | |
| `pendingSession.planId`, `planLabel`, `cycle`, `method` | khuyến nghị | FE hiển thị summary modal |

**Response mẫu đúng** (theo spec):

```json
{
  "success": false,
  "statusCode": 409,
  "code": "paymentPending",
  "message": "Bạn đang có phiên thanh toán chờ duyệt. Vui lòng hoàn tất hoặc hủy phiên hiện tại trước khi tạo mới.",
  "pendingSession": {
    "sessionId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "kind": "upgrade",
    "totalAmount": 769450,
    "planId": "rooms_10",
    "planLabel": "Standard · Tháng",
    "cycle": "monthly",
    "method": "bank_transfer",
    "createdAt": "2026-06-06T10:00:00.000Z",
    "expiresAt": "2026-06-07T10:00:00.000Z"
  }
}
```

---

## 4. Giả thuyết lỗi phía BE (cần verify)

### 4.1 Trả 409 nhưng **thiếu `pendingSession`**

```json
{
  "success": false,
  "statusCode": 409,
  "code": "paymentPending",
  "message": "..."
}
```

→ User vẫn thấy modal (có message), nhưng **Huỷ & tạo mới** fail vì không có `sessionId`.

### 4.2 `pendingSession` có nhưng **sai tên field id**

Ví dụ BE trả `"id"` thay vì `"sessionId"`:

```json
"pendingSession": { "id": "uuid-...", ... }
```

FE hiện parse: `sessionId` **hoặc** `session_id` (snake_case).  
**Không** parse field `id` — cần BE chuẩn hóa `sessionId` hoặc BE bổ sung alias.

### 4.3 **`pendingSession` nằm trong `data`**, không ở root

```json
{
  "success": false,
  "statusCode": 409,
  "message": "...",
  "data": {
    "code": "paymentPending",
    "pendingSession": { ... }
  }
}
```

FE đọc `code` / `pendingSession` từ **root** (`e.response.data`), không unwrap `data`.  
→ `code` có thể null, `pendingSession` null → cùng triệu chứng.

### 4.4 **Mâu thuẫn nội bộ BE** (quan trọng)

| Endpoint | Kỳ vọng | Nếu lệch |
|---|---|---|
| `POST /payments/initiate\|renew` | 409 vì **có** session pending của **user trong token** | |
| `GET /payments/active` | Trả **cùng** session pending (full QR/bankInfo) | Trả `data: null` trong khi initiate vẫn 409 → user **Tiếp tục phiên cũ** cũng fail |

Đây không phải “nhầm tài khoản” mà là **lookup session pending không nhất quán** giữa 2 endpoint (filter `userId`, `status`, `expiresAt`, soft-delete, v.v.).

### 4.5 Session gắn **userId / ownerId** sai (ít gặp hơn)

Nếu session pending lưu `userId` khác token hiện tại:
- Initiate có thể 409 generic hoặc không trả `pendingSession` đầy đủ
- `GET /payments/active` trả null (đúng user token)

Cần BE confirm mọi query pending **scope theo `req.user.id`** từ JWT.

---

## 5. Cách reproduce nhanh (curl)

Thay `$TOKEN`, `$BASE`:

```bash
# 1) Tạo pending (OWNER token)
curl -s -X POST "$BASE/payments/initiate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"planId":"rooms_5","cycle":"monthly","method":"bank_transfer","rooms":5,"totalAmount":658900}'

# 2) Gọi lại initiate → expect 409 + pendingSession.sessionId
curl -s -X POST "$BASE/payments/initiate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"planId":"rooms_10","cycle":"monthly","method":"bank_transfer","rooms":10,"totalAmount":...}' \
  | jq '{code, pendingSession}'

# 3) Active session cùng user → phải trả cùng sessionId
curl -s "$BASE/payments/active" \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.data.sessionId'

# 4) Cancel bằng sessionId từ bước 2
curl -s -X POST "$BASE/payments/{sessionId}/cancel" \
  -H "Authorization: Bearer $TOKEN"
```

**Pass criteria**: Bước 2 **luôn** có `pendingSession.sessionId` non-empty; bước 3 **khớp** sessionId bước 2.

---

## 6. Checklist fix BE

- [x] Mọi 409 `paymentPending` từ `initiate` / `renew` đều include `pendingSession` ở **root body**
- [x] `pendingSession.sessionId` = UUID của `PaymentSession` row `status=pending` của **đúng user token**
- [x] Field naming: `sessionId` (camelCase) — service đã set `sessionId: pending.id`
- [x] `GET /payments/active` trả cùng session mà logic 409 đang chặn (query `findFirst({ userId, status: PENDING })` đúng scope)
- [ ] Log khi throw 409: `userId`, `pendingSessionId`, `kind` — optional observability
- [ ] Unit/integration test: double initiate → 409 body có `pendingSession.sessionId`; cancel → initiate lại 201

---

## 7. FE đã implement (không cần BE đổi flow)

| Hành vi | API |
|---|---|
| Chặn tạo session khi pending | BE 409 (§10.2.6) |
| Tiếp tục phiên cũ | `GET /payments/active` |
| Huỷ phiên cũ | `POST /payments/:sessionId/cancel` — **bắt buộc sessionId từ 409** |
| Poll trạng thái | `GET /payments/:sessionId/status` |
| Source of truth pending | API only — **không** persist session local |

---

## 8. Đề xuất FE tạm (optional, nếu BE chưa fix kịp)

FE có thể fallback: khi `pendingSession.sessionId` thiếu, gọi `GET /payments/active` lấy `sessionId` rồi cancel.  
**Khuyến nghị vẫn fix BE** — contract §10.2.6 yêu cầu body 409 đầy đủ; tránh phụ thuộc thêm round-trip.

---

## 9. Liên hệ / log cần từ BE khi fix

Nếu cần trace case prod, gửi FE:

- `userId` / email OWNER
- Timestamp gọi `POST /payments/initiate|renew` → 409
- Raw JSON response (ẩn token)
- Kết quả `GET /payments/active` cùng thời điểm
- `PaymentSession.id` trong DB `status=pending`

---

## 10. Resolution (BE — 2026-06-06)

### Root cause ✅

`src/common/filters/http-exception.filter.ts` — global exception filter chỉ extract `message`, `code`, `errors` từ exception response object. **Mọi field còn lại bị drop** (`pendingSession`, `effectiveAt`, `pendingPlanId`).

→ Khớp **giả thuyết 4.1** trong report (409 có `code` nhưng thiếu `pendingSession` ở client).

**Loại trừ** (BE confirm):

| Giả thuyết | Kết quả |
|---|---|
| 4.2 Sai tên `id` vs `sessionId` | ❌ Service đã set `sessionId: pending.id` |
| 4.3 Nested trong `data` | ❌ Throw exception trực tiếp |
| 4.4 / 4.5 Lookup / userId | ❌ Query scope đúng |

### Fix ✅

Filter **spread mọi field non-reserved** từ exception response ra root body.

Reserved keys: `message`, `errors`, `code`, `statusCode`, `error`.

Generic — áp dụng cho:

- `paymentPending` → `pendingSession`
- `downgradeScheduled` → `effectiveAt`, `pendingPlanId`
- Mọi exception tương lai có extras

### Verified response shape (prod)

```json
{
  "success": false,
  "statusCode": 409,
  "message": "Bạn đang có phiên thanh toán chờ duyệt...",
  "code": "paymentPending",
  "errors": null,
  "pendingSession": {
    "sessionId": "<uuid>",
    "kind": "renew",
    "totalAmount": 658900,
    "planId": "rooms_5",
    "planLabel": "Starter · Tháng",
    "cycle": "monthly",
    "method": "bank_transfer",
    "createdAt": "...",
    "expiresAt": "..."
  },
  "path": "/payments/initiate",
  "timestamp": "..."
}
```

**Live**: `https://api.halong24h.com` (PID 12884)

### FE compatibility ✅

FE đã parse đúng shape trên — không cần đổi code:

- `VerifyApiException.fromDio` đọc `code`, `pendingSession`, `effectiveAt`, `pendingPlanId` từ **root** `response.data`
- `payment_pending_handler.dart` → `POST /payments/:sessionId/cancel` khi user chọn **Huỷ phiên & tạo mới**

**FE test plan** (manual):

1. Tạo session pending (CK chưa mark-paid)
2. Gọi initiate/renew lần 2 → bottom sheet 409 có card summary (gói, tiền, hết hạn)
3. **Tiếp tục phiên cũ** → QR dialog từ `GET /payments/active`
4. **Huỷ phiên & tạo mới** → cancel OK → session mới + QR mới
5. (Bonus) Hạ gói → 409 `downgradeScheduled` hiển thị ngày `effectiveAt`

---

*Báo cáo gốc mô tả gap §10.2.6 — đã closed sau fix exception filter.*
