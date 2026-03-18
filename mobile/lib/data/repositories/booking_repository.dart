import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final _dio = ApiClient.instance;

  Future<ApiResponse<List<BookingModel>>> getBookings({String? roomId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.bookings,
        queryParameters: roomId != null ? {'roomId': roomId} : null,
      );
      final list = (response.data['data'] as List)
          .map((e) => BookingModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<List<CalendarBooking>>> getCalendar(
      String roomId, int year, int month) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.bookings}/calendar/$roomId',
        queryParameters: {'year': year, 'month': month},
      );
      final list = (response.data['data'] as List)
          .map((e) => CalendarBooking.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<BookingModel>> holdRoom(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.holdRoom, data: data);
      return ApiResponse(
        success: true,
        data: BookingModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<BookingModel>> confirmBooking(String id) async {
    try {
      final response = await _dio.patch('${ApiConstants.bookings}/$id/confirm');
      return ApiResponse(
        success: true,
        data: BookingModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> cancelBooking(String id) async {
    try {
      await _dio.patch('${ApiConstants.bookings}/$id/cancel');
      return ApiResponse(success: true, message: 'Huỷ booking thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<BookingModel>> updateBooking(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put('${ApiConstants.bookings}/$id', data: data);
      return ApiResponse(
        success: true,
        data: BookingModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
