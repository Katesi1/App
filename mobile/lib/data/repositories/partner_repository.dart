import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

/// Partner API — mọi request cần [partnerKey] (header `X-Partner-Key`).
/// Không lưu key trong repo; caller truyền vào (env / cấu hình riêng).
class PartnerRepository {
  final _dio = ApiClient.instance;

  Options _headers(String partnerKey) => Options(
        headers: {'X-Partner-Key': partnerKey},
      );

  Future<ApiResponse<List<Map<String, dynamic>>>> getRooms(
    String partnerKey,
  ) async {
    try {
      final response = await _dio.get(
        ApiConstants.partnerRooms,
        options: _headers(partnerKey),
      );
      final list = (response.data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getRoomDetail(
    String partnerKey,
    String roomId,
  ) async {
    try {
      final response = await _dio.get(
        ApiConstants.partnerRoomDetail(roomId),
        options: _headers(partnerKey),
      );
      final data = Map<String, dynamic>.from(
        response.data['data'] as Map,
      );
      return ApiResponse(success: true, data: data, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getRoomAvailability(
    String partnerKey,
    String roomId, {
    required int year,
    required int month,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.partnerRoomAvailability(roomId),
        options: _headers(partnerKey),
        queryParameters: {'year': year, 'month': month},
      );
      final data = Map<String, dynamic>.from(
        response.data['data'] as Map,
      );
      return ApiResponse(success: true, data: data, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createBooking(
    String partnerKey,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(
        ApiConstants.partnerBookings,
        data: body,
        options: _headers(partnerKey),
      );
      final data = Map<String, dynamic>.from(
        response.data['data'] as Map,
      );
      return ApiResponse(
        success: true,
        data: data,
        message: response.data['message']?.toString() ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> cancelBooking(
    String partnerKey,
    String bookingId,
  ) async {
    try {
      await _dio.post(
        ApiConstants.partnerBookingCancel(bookingId),
        options: _headers(partnerKey),
      );
      return ApiResponse(success: true, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
