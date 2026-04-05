import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/calendar_model.dart';

class CalendarRepository {
  final _dio = ApiClient.instance;

  /// GET /calendar/property-groups — danh sách property nhóm cho lịch
  Future<ApiResponse<List<CalendarPropertyGroup>>> getPropertyGroups({
    String? category,
    String? ownerId,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.calendarPropertyGroups,
        queryParameters: {
          if (category != null) 'category': category,
          if (ownerId != null) 'ownerId': ownerId,
        },
      );
      final list = (response.data['data'] as List)
          .map((e) => CalendarPropertyGroup.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// GET /calendar/grid — lịch grid (rooms × dates)
  Future<ApiResponse<CalendarGrid>> getGrid({
    required String propertyGroupId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.calendarGrid,
        queryParameters: {
          'propertyGroupId': propertyGroupId,
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      return ApiResponse(
        success: true,
        data: CalendarGrid.fromJson(response.data['data']),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// POST /calendar/lock — khoá phòng theo ngày
  Future<ApiResponse<Map<String, dynamic>>> lockRoom({
    required String roomId,
    required String date,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.calendarLock,
        data: {'roomId': roomId, 'date': date},
      );
      return ApiResponse(
        success: true,
        data: response.data['data'],
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// POST /calendar/unlock — mở khoá phòng
  Future<ApiResponse<void>> unlockRoom({
    required String roomId,
    required String date,
  }) async {
    try {
      await _dio.post(
        ApiConstants.calendarUnlock,
        data: {'roomId': roomId, 'date': date},
      );
      return ApiResponse(success: true, message: 'Đã mở khoá phòng');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// GET /calendar/admin-contact — thông tin liên hệ admin (Public)
  Future<ApiResponse<AdminContact>> getAdminContact() async {
    try {
      final response = await _dio.get(ApiConstants.calendarAdminContact);
      return ApiResponse(
        success: true,
        data: AdminContact.fromJson(response.data['data']),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
