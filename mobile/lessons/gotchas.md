# Lessons Learned — Gotchas & Edge Cases

Ghi lại các lỗi, edge case, bài học từ quá trình phát triển. Format: **Vấn đề → Nguyên nhân → Giải pháp**

---

## GoRouter Redirect + Provider Chain

**Vấn đề**: `ref.read(isCustomerModeProvider)` trong GoRouter redirect trả sai giá trị ngay sau login.

**Nguyên nhân**: Provider chain (`isCustomerModeProvider` phụ thuộc `authProvider` + `viewModeProvider`) chưa kịp propagate khi redirect callback chạy ngay sau auth state thay đổi.

**Giải pháp**: Tính `isCustomerMode` trực tiếp từ `authState.user` + `ref.read(viewModeProvider)` trong redirect callback, KHÔNG dùng derived provider.

---

## Role Migration: OWNER/SALE → STAFF

**Vấn đề**: Code cũ check `role == 'OWNER'` hoặc `role == 'SALE'` không match data mới.

**Nguyên nhân**: Hệ thống đã gộp role OWNER + SALE thành STAFF (3 roles: ADMIN, STAFF, CUSTOMER).

**Giải pháp**: Luôn dùng `UserModel.isStaff`, `UserModel.isManagement` (bao gồm ADMIN + STAFF) thay vì check string trực tiếp.

---

## CachedNetworkImage Memory Overflow

**Vấn đề**: App lag/crash khi scroll danh sách phòng có nhiều ảnh.

**Nguyên nhân**: `CachedNetworkImage` không set `memCacheWidth` → decode ảnh full resolution (4000x3000 = ~48MB/ảnh).

**Giải pháp**: Luôn set `memCacheWidth` (400 cho thumbnail, 800 cho detail). Xem bảng chi tiết trong CLAUDE.md Section 11.

---

## invalidate() Family Provider

**Vấn đề**: Sau mutation, UI không refresh data.

**Nguyên nhân**: `ref.invalidate(bookingListProvider)` invalidate family root, không invalidate variant đang dùng.

**Giải pháp**: Truyền đúng parameter: `ref.invalidate(bookingListProvider(null))` hoặc `ref.invalidate(bookingListProvider(roomId))`.

---

## MVC thiếu Controller — Feature không đầy đủ cấu trúc

**Vấn đề**: Các feature `dashboard`, `profile`, `reports` chỉ có `views/` mà không có `controllers/`. Vi phạm MVC convention, logic tính toán bị hardcode trong view, không reusable.

**Nguyên nhân**: Khi tạo feature mới hoặc rà code, không kiểm tra đầy đủ cấu trúc MVC (Model → Repository → Controller → View). Chỉ tập trung vào UI mà quên tầng controller.

**Giải pháp**:
1. **Mọi feature PHẢI có `controllers/` directory** với ít nhất 1 controller file, dù logic đơn giản.
2. Khi rà code hoặc tạo feature mới, **checklist bắt buộc**: controllers/ tồn tại? views/ tồn tại? providers đã khai báo?
3. Logic tính toán (KPI, stats, filter) **PHẢI nằm trong controller**, KHÔNG hardcode trong view.
4. Dùng skill `scaffolding` khi tạo feature mới để đảm bảo đầy đủ thư mục.

---

## Selfie KYC — ML Kit không nhận mặt (kẹt "Đặt khuôn mặt vào khung")

**Vấn đề**: Màn quét selfie/liveness không detect khuôn mặt, pill luôn hiện "Đặt khuôn mặt vào khung".

**Nguyên nhân**:
1. `selfie_scanner_screen` concat **tất cả** `image.planes` vào một buffer → bytes sai format NV21 → `FaceDetector` trả `faces.isEmpty` mọi frame.
2. Một số thiết bị Android (`camera_android_camerax`) vẫn trả YUV_420_888 (3 plane) dù đã set `ImageFormatGroup.nv21`.
3. `deviceOrientation == null` bỏ qua frame; UI không `setState` khi `_processing == true` nên progress không cập nhật.

**Giải pháp**: Dùng `cameraImageToMlKitInput()` (`lib/features/verify/utils/camera_mlkit_input.dart`) — plane đầu cho NV21/BGRA, convert YUV→NV21 khi 3 plane, fallback orientation `0`. CCCD scanner cũng dùng helper này.

**Tiếp theo (kẹt "Căn giữa khuôn mặt" dù log `detectFaces` chạy)**: ML Kit đã detect nhưng so center bằng `image.width/height` thô (landscape) trong khi box nằm trong không gian đã xoay; preview front cam mirror ngang. Dùng `FaceAnalysisSpace` — swap W/H khi rotation 90°/270°, mirror X cho front camera.

**Liveness trái/phải**: ML Kit yaw trên front cam đảo so với góc nhìn user — `lookLeft` enum match `yaw > threshold` nhưng hiển thị **"Quay PHẢI"** + `arrow_forward`; `lookRight` match `yaw < -threshold` hiển thị **"Quay TRÁI"** + `arrow_back`. Đừng gắn label theo tên enum.

**Sau selfie Option A**: `context.go('/verify/pending')` — không về dashboard; màn pending có timeline + "Liên hệ admin" / "Trang tổng quan".

---

_(Thêm gotcha mới vào đây khi phát hiện)_
