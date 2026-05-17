import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

/// Gọi `/devices` endpoint để register/unregister FCM token.
class DeviceRepository {
  final Dio _dio = ApiClient.instance;

  /// Register FCM token cho user hiện tại. BE upsert theo token (cùng device
  /// đổi user → user_id update). Idempotent.
  Future<ApiResponse<void>> register({
    required String fcmToken,
    required String platform,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
    String? locale,
  }) async {
    try {
      await _dio.post(
        ApiConstants.devices,
        data: {
          'fcmToken': fcmToken,
          'platform': platform,
          if (deviceModel != null) 'deviceModel': deviceModel,
          if (osVersion != null) 'osVersion': osVersion,
          if (appVersion != null) 'appVersion': appVersion,
          if (locale != null) 'locale': locale,
        },
      );
      return ApiResponse(success: true, message: 'Device registered');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Unregister FCM token (gọi trước khi logout). Idempotent.
  Future<ApiResponse<void>> unregister(String fcmToken) async {
    try {
      await _dio.delete(ApiConstants.deviceDetail(fcmToken));
      return ApiResponse(success: true, message: 'Device unregistered');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
