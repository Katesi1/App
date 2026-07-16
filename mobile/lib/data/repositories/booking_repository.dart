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
      final list = (response.data['data'] as List? ?? [])
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
      final list = (response.data['data'] as List? ?? [])
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

  /// PATCH /bookings/:id/paid — OWNER/SALE ghi nhận thu tiền cọc của khách.
  /// [amount] bỏ trống → BE mặc định 50% totalAmount (hoặc depositAmount).
  /// Nếu booking đang HOLD → BE tự chuyển CONFIRMED.
  Future<ApiResponse<BookingModel>> markPaid(String id, {int? amount}) async {
    try {
      final response = await _dio.patch(
        ApiConstants.bookingPaid(id),
        data: {if (amount != null) 'amount': amount},
      );
      return ApiResponse(
        success: true,
        data: BookingModel.fromJson(response.data['data']),
        message: response.data['message'] ?? 'Đã ghi nhận thanh toán',
      );
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// PATCH /bookings/:id/checkin — xác nhận khách nhận phòng + thu nốt →
  /// COMPLETED (yêu cầu booking đang CONFIRMED). [amount] bỏ trống → BE thu
  /// cho đủ totalAmount; có [amount] → cộng dồn vào paidAmount.
  Future<ApiResponse<BookingModel>> checkinBooking(String id,
      {int? amount}) async {
    try {
      final response = await _dio.patch(
        ApiConstants.bookingCheckin(id),
        data: {if (amount != null) 'amount': amount},
      );
      return ApiResponse(
        success: true,
        data: BookingModel.fromJson(response.data['data']),
        message: response.data['message'] ?? 'Đã hoàn tất nhận phòng',
      );
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
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
