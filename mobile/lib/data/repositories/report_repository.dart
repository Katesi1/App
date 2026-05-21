import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/booking_model.dart';

class ReportRepository {
  final _dio = ApiClient.instance;

  /// Lấy report. Param mới (`period`/`from`/`to`) ưu tiên hơn legacy
  /// (`month`/`year`). Backend mặc định = `month` (tháng hiện tại) nếu
  /// không truyền gì.
  Future<ApiResponse<Map<String, dynamic>>> getReport({
    String? period,
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.reports,
        queryParameters: {
          if (period != null) 'period': period,
          if (from != null) 'from': _formatDate(from),
          if (to != null) 'to': _formatDate(to),
          if (month != null) 'month': month,
          if (year != null) 'year': year,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      // Parse recentBookings nếu có
      if (data['recentBookings'] != null) {
        data['recentBookingsParsed'] = (data['recentBookings'] as List? ?? [])
            .map((e) => BookingModel.fromJson(e))
            .toList();
      }
      return ApiResponse(success: true, data: data, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
