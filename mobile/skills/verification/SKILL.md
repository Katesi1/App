# Skill: Verification — Kiểm tra code trước khi done

## Khi nào dùng
- Sau khi hoàn thành bất kỳ task nào
- Trước khi báo "done" cho user
- Trước khi commit/push code

## The 4C Framework

Mỗi lần verify, kiểm tra 4 tiêu chí theo thứ tự:

### 1. Correctness — Logic đúng không?

```
[ ] Logic đúng với yêu cầu của user?
[ ] Không có bug hiển nhiên? (off-by-one, null pointer, wrong condition)
[ ] Edge cases đã xử lý?
    - List rỗng → EmptyStateWidget
    - API error → ErrorStateWidget + retry
    - Null values → null-safe operators, default values
    - Offline → error message rõ ràng
[ ] API response parse đúng format? (response.data['data'])
[ ] Role-based logic đúng? (ADMIN/STAFF/CUSTOMER)
```

### 2. Completeness — Đủ chưa?

```
[ ] Đủ các file cần thiết? (model → repo → controller → view → route)
[ ] Có loading state? (LoadingWidget / SkeletonList)
[ ] Có error state? (ErrorStateWidget + onRetry)
[ ] Có empty state? (EmptyStateWidget)
[ ] Có error handling trong repository? (try/catch DioException)
[ ] Unit test cho logic mới? (nếu applicable)
[ ] Endpoint mới đã thêm vào ApiConstants?
```

### 3. Context-fit — Đúng convention không?

```
[ ] Dùng AppColors thay vì hardcode Color()?
[ ] Dùng AppHelpers thay vì duplicate logic?
[ ] Dùng shared/widgets/ cho widget dùng chung?
[ ] Dùng ApiClient.instance (không tạo Dio mới)?
[ ] Dùng ApiResponse (không throw exception từ repo)?
[ ] Dùng ConsumerWidget + ref.watch (không setState)?
[ ] Không import chéo giữa features?
[ ] const ở mọi nơi có thể?
[ ] CachedNetworkImage có memCacheWidth?
[ ] ListView.builder thay vì Column + map?
[ ] File names đúng snake_case?
[ ] Relative imports?
```

### 4. Consequence — Rủi ro gì?

```
[ ] Nếu deploy thật, rủi ro lớn nhất là gì?
[ ] Có break flow hiện tại không? (auth, navigation, booking)
[ ] Route guard có chặn đúng role?
[ ] API call có quá nhiều/quá ít?
[ ] Memory leak? (dispose controllers, cancel timers)
[ ] Performance? (unnecessary rebuilds, missing debounce)
```

## Automated Checks

Chạy tất cả trước khi done:

```bash
# 1. Static analysis — phải pass clean
flutter analyze

# 2. Format — phải đúng
dart format .

# 3. Tests — phải pass
flutter test

# 4. Code gen — nếu thêm/sửa model
dart run build_runner build --delete-conflicting-outputs
```

## Quick Check (cho task nhỏ)

Nếu task chỉ sửa 1-2 file, dùng quick check:

```
[ ] Logic đúng?
[ ] Không break existing?
[ ] Đúng convention? (AppColors, AppHelpers, const)
[ ] flutter analyze pass?
```

## Khi verification fail

1. Fix issue ngay
2. Ghi vào `lessons/gotchas.md` nếu là edge case mới
3. Re-run verification
4. Chỉ báo done khi ALL checks pass
