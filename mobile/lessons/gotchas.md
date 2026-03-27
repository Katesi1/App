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

_(Thêm gotcha mới vào đây khi phát hiện)_
