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
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Kết nối quá thời gian, vui lòng thử lại';
    case DioExceptionType.connectionError:
      return 'Không kết nối được server';
    default:
      return 'Có lỗi xảy ra, vui lòng thử lại';
  }
}
