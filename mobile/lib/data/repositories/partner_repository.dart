import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

/// Partner API — every request requires [partnerKey] (header `X-Partner-Key`).
/// The key is NOT stored in the repo; caller passes it in (env / separate config).
class PartnerRepository {
  final _dio = ApiClient.instance;

  Options _headers(String partnerKey) => Options(
        headers: {'X-Partner-Key': partnerKey},
      );

  Future<ApiResponse<List<Map<String, dynamic>>>> getProperties(
    String partnerKey,
  ) async {
    try {
      final response = await _dio.get(
        ApiConstants.partnerProperties,
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

  Future<ApiResponse<Map<String, dynamic>>> getPropertyDetail(
    String partnerKey,
    String propertyId,
  ) async {
    try {
      final response = await _dio.get(
        ApiConstants.partnerPropertyDetail(propertyId),
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

  Future<ApiResponse<Map<String, dynamic>>> getPropertyAvailability(
    String partnerKey,
    String propertyId, {
    required int year,
    required int month,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.partnerPropertyAvailability(propertyId),
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
