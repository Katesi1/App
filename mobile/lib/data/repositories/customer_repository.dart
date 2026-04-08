import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/booking_model.dart';
import '../models/room_model.dart';

class CustomerRepository {
  final _dio = ApiClient.instance;

  /// Lấy danh sách phòng public (cho customer xem)
  Future<ApiResponse<List<RoomModel>>> getPublicRooms({
    DateTime? checkinDate,
    DateTime? checkoutDate,
    int? guests,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.propertiesPublic,
        queryParameters: {
          if (checkinDate != null)
            'checkinDate': checkinDate.toIso8601String().split('T')[0],
          if (checkoutDate != null)
            'checkoutDate': checkoutDate.toIso8601String().split('T')[0],
          if (guests != null) 'guests': guests,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
        },
      );
      final list = (response.data['data'] as List)
          .map((e) => RoomModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Customer đặt phòng (auto HOLD)
  Future<ApiResponse<BookingModel>> customerHoldRoom(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post(ApiConstants.customerHold, data: data);
      return ApiResponse(
        success: true,
        data: BookingModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Lấy danh sách booking của customer hiện tại
  Future<ApiResponse<List<BookingModel>>> getMyBookings({
    int? status,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.myBookings,
        queryParameters: {
          if (status != null) 'status': status,
        },
      );
      final list = (response.data['data'] as List)
          .map((e) => BookingModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Customer huỷ booking (chỉ HOLD)
  Future<ApiResponse<void>> customerCancelBooking(String id) async {
    try {
      await _dio.patch(ApiConstants.customerCancel(id));
      return ApiResponse(success: true, message: 'Đã huỷ đặt phòng');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
