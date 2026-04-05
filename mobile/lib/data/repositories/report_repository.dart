import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/booking_model.dart';

class ReportRepository {
  final _dio = ApiClient.instance;

  Future<ApiResponse<Map<String, dynamic>>> getReport({
    int? month,
    int? year,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.reports,
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      // Parse recentBookings nếu có
      if (data['recentBookings'] != null) {
        data['recentBookingsParsed'] =
            (data['recentBookings'] as List)
                .map((e) => BookingModel.fromJson(e))
                .toList();
      }
      return ApiResponse(success: true, data: data, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
