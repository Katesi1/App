import 'package:dio/dio.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;

  ApiResponse({required this.success, this.data, required this.message});
}

// Helper để parse lỗi từ Dio
String parseDioError(DioException e) {
  if (e.response?.data != null) {
    final data = e.response!.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
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
