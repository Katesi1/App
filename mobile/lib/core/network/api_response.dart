import 'package:dio/dio.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;

  /// Machine-readable error code from the BE error envelope root (`code`),
  /// e.g. `subscription.featureLocked`, `paymentPending`. Null on success or
  /// when BE returns no code. Lets the UI branch without parsing localized text.
  final String? code;

  ApiResponse({
    required this.success,
    this.data,
    required this.message,
    this.code,
  });
}

/// Extracts the machine-readable `code` from a Dio error envelope root body
/// (see API_SPEC §10.2.7). Returns null when absent.
String? parseDioErrorCode(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['code'] != null) {
    return data['code'].toString();
  }
  return null;
}

// Helper to parse Dio errors into user-facing messages.
String parseDioError(DioException e) {
  if (e.response?.data != null) {
    final data = e.response!.data;
    if (data is Map && data['message'] != null) {
      final raw = data['message'].toString();
      // BE sometimes concatenates multiple validation errors into one string:
      // "Email không được để trống, Email không hợp lệ, Mật khẩu tối thiểu 6 ký tự"
      // → only show the first error for clearer UX (one issue at a time).
      if (raw.contains(',')) {
        return raw.split(',').first.trim();
      }
      return raw;
    }
  }
  switch (e.type) {
    case DioExceptionType.badResponse:
      return 'Lỗi máy chủ (${e.response?.statusCode ?? ''}).';
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return 'Kết nối quá thời gian, vui lòng thử lại';
    case DioExceptionType.connectionError:
      return 'Không kết nối được server';
    case DioExceptionType.badCertificate:
      return 'Kết nối bảo mật thất bại (SSL/TLS)';
    case DioExceptionType.cancel:
      return 'Yêu cầu đã bị huỷ';
    case DioExceptionType.unknown:
      final msg = e.message?.trim();
      if (msg != null && msg.isNotEmpty) {
        return 'Lỗi kết nối: $msg';
      }
      return 'Lỗi không xác định từ hệ thống mạng';
  }
}
