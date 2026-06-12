import 'package:dio/dio.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;

  /// Mã lỗi máy đọc được từ BE (vd `subscription.featureLocked`). Null khi
  /// thành công hoặc BE không trả `code`.
  final String? code;

  /// HTTP status code khi lỗi (vd 403). Null khi thành công / lỗi mạng.
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    required this.message,
    this.code,
    this.statusCode,
  });

  /// Build error response từ [DioException] — giữ message qua [parseDioError]
  /// (không đổi hành vi comma-split), đồng thời trích `code` + `statusCode` để
  /// caller phân biệt được lỗi business (vd featureLocked vs KYC required).
  factory ApiResponse.fromDioError(DioException e) {
    final data = e.response?.data;
    String? code;
    if (data is Map && data['code'] != null) {
      code = data['code'].toString();
    }
    return ApiResponse(
      success: false,
      message: parseDioError(e),
      code: code,
      statusCode: e.response?.statusCode,
    );
  }
}

/// Mã lỗi business BE trả ở field `code` (khớp i18n key backend).
class ApiErrorCodes {
  ApiErrorCodes._();

  /// Hết trial / chưa active / past_due / cancelled / frozen — generic, BE cố
  /// tình không lộ trạng thái cụ thể (Apple IAP compliance).
  static const String featureLocked = 'subscription.featureLocked';

  /// OWNER chưa hoàn thành KYC khi tạo/sửa property hoặc mời nhân viên.
  static const String kycPropertyRequiresKyc = 'kyc.propertyRequiresKyc';
}

extension ApiResponseErrorX<T> on ApiResponse<T> {
  /// True khi BE chặn vì hết quyền dùng tính năng (hết trial / chưa mua gói).
  /// Fallback: 403 không kèm `code` cũng coi là featureLocked (BE luôn trả
  /// code, fallback chỉ để phòng thủ). Caller nên check [isKycRequired] trước.
  bool get isFeatureLocked =>
      code == ApiErrorCodes.featureLocked ||
      (code == null && statusCode == 403);

  bool get isKycRequired => code == ApiErrorCodes.kycPropertyRequiresKyc;
}

// Helper để parse lỗi từ Dio
String parseDioError(DioException e) {
  if (e.response?.data != null) {
    final data = e.response!.data;
    if (data is Map && data['message'] != null) {
      final raw = data['message'].toString();
      // BE đôi khi concat nhiều validation errors thành 1 string:
      // "Email không được để trống, Email không hợp lệ, Mật khẩu tối thiểu 6 ký tự"
      // → chỉ hiện lỗi đầu tiên để UX rõ ràng (1 vấn đề / lần).
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
