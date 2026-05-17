# Integration Tests

Tests chạy trên thiết bị/simulator thật, exercise nhiều screen + service cùng lúc.

## Chạy

```bash
# Single test
flutter test integration_test/login_flow_test.dart

# Tất cả
flutter test integration_test/

# Chạy trên device cụ thể
flutter test integration_test/ -d <device-id>
```

## Cấu trúc

| File | Critical flow |
|---|---|
| `login_flow_test.dart` | Splash → Login screen → form validation → tap Google button |
| `staff_invite_flow_test.dart` | Login screen → "Tôi có mã mời" → InviteAcceptScreen → token verify |
| `booking_flow_test.dart` | Customer Home → Search → Property detail → Hold booking |

## Lưu ý

- Tests dùng **mock API** (override `Provider`) — KHÔNG hit production BE
- Mỗi test reset `SecureStorage` ở `setUp()` để isolate
- Force-update prompt + Firebase init có thể fail trong test → đã wrap try/catch
