# Báo cáo cập nhật BE v1.12 — Apple IAP compliance & Silent OWNER Trial

> **Ngày**: 2026-06-10
> **BE version**: v1.12
> **Đối tượng**: FE iOS, FE Android, FE Web
> **Mức độ thay đổi**: Behavioral (không breaking schema, có breaking UX flow trên iOS)
> **Tham chiếu**: `docs/API_SPEC_FULL.md` §2A.5 + Changelog v1.12

---

## 1. Bối cảnh

Apple Guideline 3.1.1 cấm app dạng quản lý (management/B2B) dùng chuyển khoản ngoài cho dịch vụ digital. Trước đây OWNER mua/gia hạn gói qua VietQR/bank transfer hiển thị ngay trong app → vi phạm.

**Quyết định business:**

- **iOS**: Gỡ toàn bộ UI thanh toán khỏi app.
- **Android (Google Play) + Web**: Giữ nguyên flow thanh toán cũ (VietQR/manual_bank → admin duyệt).
- **OWNER mới đăng ký được trial ngầm 60 ngày** ở mọi nền tảng → đủ thời gian hoàn tất KYC và sử dụng tính năng.
- **Hết 60 ngày mà chưa có thanh toán** → tài khoản tự khóa silent, BE trả lỗi entitlement chung. User liên hệ admin / mua gói qua Web hoặc Play.

---

## 2. Thay đổi BE (đã deploy)

### 2.1 Đăng ký OWNER → cấp trial ngầm

Mọi endpoint đăng ký với `role=1` (OWNER) BE tự set:

```
subscriptionStatus = "trial"
trialEndsAt        = now + 60 days
```

Áp dụng cho:

- `POST /auth/register` (email)
- `POST /auth/google` (user mới chọn `role=1`)
- `POST /auth/apple` (user mới chọn `role=1`)

CUSTOMER (`role=3`) **không** bị ảnh hưởng.

### 2.2 Entitlement gate generic

BE check ở các endpoint write sau:

| Endpoint | Trước đây | Bây giờ |
|---|---|---|
| `POST /properties` | Chỉ check KYC | Check KYC **+ entitlement** |
| `PUT /properties/:id` | Chỉ check KYC | Check KYC **+ entitlement** |
| `POST /staff/invites` | Trả `staff.subscriptionRequired` khi hết sub | Trả **`subscription.featureLocked`** generic |

Quy tắc entitlement (BE pass khi thoả MỘT trong):

- `kycBypass = true` (ADMIN cấp tay), HOẶC
- `subscriptionStatus = "active"`, HOẶC
- `subscriptionStatus = "trial"` **và** `trialEndsAt > now`.

Không thoả → **HTTP 403** với body:

```json
{
  "success": false,
  "message": "Tài khoản chưa có quyền dùng tính năng này.",
  "data": null
}
```

(EN: `"Your account is not authorized to use this feature."`)

Lưu ý: BE **cố tình** không phân biệt nguyên nhân (hết trial / cancelled / past_due / frozen) trong message — để FE không lộ trạng thái subscription nội bộ ra cho user iOS.

### 2.3 Unlock

ADMIN duyệt thanh toán → `POST /admin/users/:id/subscription/mark-paid` → `subscriptionStatus = "active"` → mọi endpoint mở lại **ngay**, user không cần đăng xuất / đăng nhập lại.

---

## 3. Luồng OWNER theo state

| Giai đoạn | KYC | Trial | Tính năng read | Tính năng write |
|---|---|---|---|---|
| Vừa đăng ký | `none` | 60d còn | ✅ | ❌ chặn bởi KYC (403 `kyc.propertyRequiresKyc`) |
| KYC đang chờ duyệt | `pending` | 60d còn | ✅ | ❌ vẫn chặn KYC |
| KYC duyệt | `approved` | 60d còn | ✅ | ✅ **đủ quyền** |
| KYC duyệt | `approved` | **đã hết hạn** | ✅ | ❌ 403 `subscription.featureLocked` |
| ADMIN mark-paid | `approved` | — | ✅ | ✅ active vĩnh viễn cho tới chu kỳ kế |

SALE inherit entitlement của OWNER được gán (`user.ownerId`). OWNER bị khóa → SALE cũng bị khóa.

---

## 4. Việc FE cần làm

### 4.1 Chung cho cả 3 nền tảng (iOS / Android / Web)

**Bắt 403 `subscription.featureLocked`** ở 3 endpoint sau:

- `POST /properties`
- `PUT /properties/:id`
- `POST /staff/invites`

Khi gặp 403 với message `"Tài khoản chưa có quyền dùng tính năng này."`:

1. Hiển thị dialog/snackbar với message từ BE (đã i18n sẵn vi/en).
2. Đóng dialog → giữ user ở màn hình hiện tại, không tự navigate.
3. CTA tuỳ nền tảng — xem §4.2, §4.3, §4.4.

**Không gọi** `/subscriptions/me` chỉ để check trial countdown — BE đã đảm bảo gate ở write endpoint, FE không cần đoán trước.

### 4.2 iOS — REMOVE thanh toán

- ✅ **Gỡ hoàn toàn** màn hình mua gói / gia hạn / nhập STK chuyển khoản nếu còn sót.
- ✅ **Ẩn**: `trialEndsAt`, `subscriptionStatus`, banner "Còn X ngày dùng thử", banner "Gia hạn ngay".
  - Có nghĩa: không hiển thị bất cứ chỗ nào (profile, dashboard, settings, header) các field này.
  - Vẫn nhận từ `/auth/profile` được — chỉ là không render.
- ✅ Khi gặp 403 `subscription.featureLocked` → CTA hướng dẫn:
  - "Vui lòng liên hệ hỗ trợ để kích hoạt tài khoản" + nút mở chat support / mở mail.
  - **Không** nhắc tới "thanh toán", "gia hạn", "gói", "trial" trong UI iOS.
- ❌ **Không** wire endpoint `POST /payments/initiate` từ iOS.

### 4.3 Android (Google Play) — Giữ nguyên flow thanh toán cũ

- Giữ màn hình mua gói + VietQR như hiện tại.
- Hiển thị `trialEndsAt` + banner "Còn X ngày" được phép (không bị Apple chi phối).
- Khi gặp 403 `subscription.featureLocked` → CTA "Mua / Gia hạn gói" → mở màn `POST /payments/initiate`.

### 4.4 Web — Giữ nguyên flow thanh toán cũ

- Giống Android: vẫn dùng `GET /subscriptions/me`, hiển thị banner gia hạn, flow `POST /payments/initiate`.
- Khi gặp 403 `subscription.featureLocked` → redirect / mở modal mua gói.

### 4.5 Test case cần verify

| # | Hành động | Kết quả mong đợi |
|---|---|---|
| 1 | OWNER mới đăng ký bằng email, gọi `/auth/profile` | `subscriptionStatus="trial"`, `trialEndsAt` ≈ now+60d |
| 2 | OWNER mới chưa KYC, gọi `POST /properties` | 403 `kyc.propertyRequiresKyc` (không phải featureLocked) |
| 3 | OWNER KYC approved, trong trial, gọi `POST /properties` | 200 OK |
| 4 | OWNER KYC approved, trial hết hạn (set DB `trialEndsAt = now - 1d`), gọi `POST /properties` | 403 `subscription.featureLocked` |
| 5 | Sau test 4, ADMIN gọi `POST /admin/users/:id/subscription/mark-paid` | Tiếp theo `POST /properties` → 200 OK |
| 6 | iOS: OWNER xem profile sau đăng ký | KHÔNG có UI hiển thị countdown trial |
| 7 | Android/Web: cùng case | Hiển thị banner trial + nút mua gói |
| 8 | SALE được OWNER hết trial gán, gọi `POST /properties` | 403 `subscription.featureLocked` |

---

## 5. Schema / Contract — không đổi

Field shapes giữ nguyên:

```jsonc
// GET /auth/profile.data
{
  "id": "uuid",
  "role": 1,
  "kycStatus": "none|pending|approved|rejected",
  "kycBypass": false,
  "subscriptionStatus": "none|trial|active|past_due|cancelled|frozen",
  "subscriptionPlanId": "string|null",
  "trialEndsAt": "ISO|null",
  // ... các field khác
}
```

Có nghĩa: FE iOS **vẫn parse được response cũ**, chỉ là không render trial-related fields. Không cần đổi DTO.

---

## 6. Risk & lưu ý

| Risk | Mitigation |
|---|---|
| iOS reviewer phát hiện UI thanh toán còn sót | Grep codebase iOS: `payments/initiate`, `VietQR`, `bank_transfer`, `gói`, `subscription` → đảm bảo gỡ sạch trước build submit |
| User iOS không hiểu vì sao tài khoản bị khoá | Message đã rõ + cung cấp link support; team CS phải biết flow để hướng dẫn user thanh toán qua Web |
| OWNER iOS muốn nâng cấp gói mid-trial | Hướng dẫn vào Web để mua → admin duyệt → next sync `/auth/profile` thấy `active` |
| Trial 60d kéo dài user free-ride | Đã giới hạn quota SALE theo `subscriptionPlanId` qua `staff-entitlement.ts` (mirror BE↔FE); user trial chưa gắn plan → entitle theo default |
| FE Android/Web nhầm message → hiển thị "trial hết hạn" cho iOS | Dùng đúng `msg.subscription.featureLocked` từ BE, không tự render text. |

---

## 7. Rollback plan

Nếu cần rollback nhanh:

1. Set `OWNER_SIGNUP_TRIAL_DAYS` về 0 ở `src/common/constants.ts` → user mới không có trial.
2. Hoặc comment 2 dòng `assertOwnerEntitled` trong `properties.service.ts` → quay lại logic chỉ check KYC.
3. `npm run build && pm2 restart homestay-api`.

Schema không đổi → không cần migration rollback.

---

## 8. Câu hỏi liên hệ

- **BE / Spec**: team backend (Katesi1)
- **Apple review compliance**: team iOS lead
- **Customer support flow**: team CS

Tham khảo chi tiết technical: `docs/API_SPEC_FULL.md` §2A.5 + Changelog v1.12.
