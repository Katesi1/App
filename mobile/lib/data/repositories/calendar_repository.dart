import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/calendar_model.dart';

class CalendarRepository {
  final _dio = ApiClient.instance;

  /// GET /calendar/public-grid — public overview grid (no auth required).
  Future<ApiResponse<CalendarGrid>> getPublicGrid({
    required String startDate,
    required String endDate,
    String? propertyId,
    int? type,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.calendarPublicGrid,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (propertyId != null) 'propertyId': propertyId,
          if (type != null) 'type': type,
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

  /// GET /calendar/grid — management grid (Bearer token).
  /// OWNER/SALE see only their own properties; ADMIN sees everything.
  Future<ApiResponse<CalendarGrid>> getGrid({
    required String startDate,
    required String endDate,
    String? propertyId,
    int? type,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.calendarGrid,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (propertyId != null) 'propertyId': propertyId,
          if (type != null) 'type': type,
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

  /// POST /calendar/lock — lock a room for a given date.
  /// status: 0=LOCKED, 1=HOLD, 2=BOOKED
  Future<ApiResponse<Map<String, dynamic>>> lockRoom({
    required String propertyId,
    required String date,
    int status = 0,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.calendarLock,
        data: {'propertyId': propertyId, 'date': date, 'status': status},
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

  /// PATCH /calendar/sold — mark as sold (status = BOOKED).
  Future<ApiResponse<Map<String, dynamic>>> markAsSold({
    required String propertyId,
    required String date,
  }) async {
    try {
      final response = await _dio.patch(
        ApiConstants.calendarSold,
        data: {'propertyId': propertyId, 'date': date},
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

  /// DELETE /calendar/lock — unlock a room (body: propertyId + date).
  Future<ApiResponse<void>> unlockRoom({
    required String propertyId,
    required String date,
  }) async {
    try {
      await _dio.delete(
        ApiConstants.calendarLock,
        data: {'propertyId': propertyId, 'date': date},
      );
      return ApiResponse(success: true, message: 'Đã mở khoá phòng');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// GET /calendar/admin-contact — admin contact info (public).
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
