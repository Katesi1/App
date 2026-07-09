import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/booking_model.dart';

class BookingRepository {
  final _dio = ApiClient.instance;

  Future<ApiResponse<BookingModel>> getBookingDetail(String id) async {
    try {
      final response = await _dio.get(ApiConstants.bookingDetail(id));
      return ApiResponse(
        success: true,
        data: BookingModel.fromJson(response.data['data']),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<List<BookingModel>>> getBookings(
      {String? propertyId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.bookings,
        queryParameters: propertyId != null ? {'propertyId': propertyId} : null,
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
      String propertyId, int year, int month) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.bookings}/calendar/$propertyId',
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
      final response = await _dio.patch(ApiConstants.bookingConfirm(id));
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
      await _dio.patch(ApiConstants.bookingCancel(id));
      return ApiResponse(success: true, message: 'Huỷ booking thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Ghi nhận tiền cọc/tiền phòng của KHÁCH (chuyển khoản tay / tiền mặt /
  /// offline). Body optional `{amount}` — bỏ trống → BE dùng totalAmount hoặc
  /// depositAmount. Booking HOLD → BE tự chuyển CONFIRMED + clear holdExpireAt.
  Future<ApiResponse<BookingModel>> markPaid(String id,
      {double? amount}) async {
    try {
      final response = await _dio.patch(
        ApiConstants.bookingPaid(id),
        data: amount != null ? {'amount': amount} : null,
      );
      return ApiResponse(
        success: true,
        data: BookingModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Xác nhận khách nhận phòng + thu nốt tiền (§5.5). Body optional `{amount}`:
  /// gửi amount → cộng dồn vào paidAmount; bỏ trống → BE thu cho đủ totalAmount.
  /// Yêu cầu booking CONFIRMED → thành công chuyển COMPLETED.
  Future<ApiResponse<BookingModel>> checkin(String id, {double? amount}) async {
    try {
      final response = await _dio.patch(
        ApiConstants.bookingCheckin(id),
        data: amount != null ? {'amount': amount} : null,
      );
      return ApiResponse(
        success: true,
        data: BookingModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<BookingModel>> updateBooking(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put(ApiConstants.bookingUpdate(id), data: data);
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
