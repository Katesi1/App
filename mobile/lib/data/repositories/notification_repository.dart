import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final _dio = ApiClient.instance;

  Future<ApiResponse<List<NotificationModel>>> getNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.notifications);
      final list = (response.data['data'] as List? ?? [])
          .map((e) => NotificationModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<int>> getUnreadCount() async {
    try {
      final response = await _dio.get(ApiConstants.notificationsUnreadCount);
      final count = response.data['data']['count'] as int? ?? 0;
      return ApiResponse(success: true, data: count, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> markAsRead(String id) async {
    try {
      await _dio.patch(ApiConstants.notificationRead(id));
      return ApiResponse(success: true, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> markAllAsRead() async {
    try {
      await _dio.patch(ApiConstants.notificationsReadAll);
      return ApiResponse(success: true, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
