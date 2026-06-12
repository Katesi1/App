import 'api_response.dart';

/// Lỗi business mang `code` + `statusCode` để truyền qua `AsyncValue.error` /
/// controller về tới UI (vì các notifier chỉ giữ `message` nếu dùng String).
///
/// `toString()` trả về `message` thuần để giữ nguyên UX ở các call site cũ dùng
/// `err.toString().replaceAll('Exception: ', '')`.
///
/// Khác với `VerifyApiException` (throw-style, riêng feature verify) — đây là
/// kiểu dùng chung cho luồng ApiResponse chuẩn.
class ApiFailure implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const ApiFailure(this.message, {this.code, this.statusCode});

  /// Build từ [ApiResponse] lỗi (giữ code + statusCode).
  factory ApiFailure.fromResponse(ApiResponse<dynamic> res) => ApiFailure(
        res.message,
        code: res.code,
        statusCode: res.statusCode,
      );

  bool get isFeatureLocked =>
      code == ApiErrorCodes.featureLocked ||
      (code == null && statusCode == 403);

  bool get isKycRequired => code == ApiErrorCodes.kycPropertyRequiresKyc;

  @override
  String toString() => message;
}
