import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/review_model.dart';

/// Repository cho feature `reviews` — không chứa business logic, chỉ gọi API
/// + parse + return `ApiResponse<T>` (theo convention CLAUDE.md section 10).
class ReviewRepository {
  final _dio = ApiClient.instance;

  /// `GET /properties/:id/reviews` — public, không cần token.
  Future<ApiResponse<PropertyReviewsPage>> getReviews(
    ReviewListParams params,
  ) async {
    try {
      final response = await _dio.get(
        ApiConstants.propertyReviews(params.propertyId),
        queryParameters: {
          'page': params.page,
          'pageSize': params.pageSize,
          'sort': params.sort.apiValue,
          if (params.minRating != null) 'minRating': params.minRating,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        data: PropertyReviewsPage.fromJson(data),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// `POST /properties/:id/reviews` — Bearer CUSTOMER. Backend reject:
  /// 400 booking_not_completed | 403 not_your_booking | 409 already_reviewed.
  Future<ApiResponse<void>> createReview(
    String propertyId,
    CreateReviewPayload payload,
  ) async {
    try {
      await _dio.post(
        ApiConstants.propertyReviews(propertyId),
        data: payload.toJson(),
      );
      return ApiResponse(success: true, message: 'Đã gửi đánh giá');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// `POST /properties/:id/reviews/:reviewId/reply` — Bearer OWNER/ADMIN.
  /// Gọi lại sẽ ghi đè reply cũ (không lỗi 409).
  Future<ApiResponse<void>> replyReview({
    required String propertyId,
    required String reviewId,
    required String reply,
  }) async {
    try {
      await _dio.post(
        ApiConstants.propertyReviewReply(propertyId, reviewId),
        data: {'reply': reply.trim()},
      );
      return ApiResponse(success: true, message: 'Đã gửi phản hồi');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// `DELETE /admin/reviews/:reviewId` — Bearer ADMIN. Soft-hide
  /// (set `is_hidden = true`, không xoá row).
  Future<ApiResponse<void>> hideReview({
    required String reviewId,
    required String reason,
  }) async {
    try {
      await _dio.delete(
        ApiConstants.adminHideReview(reviewId),
        data: {'reason': reason.trim()},
      );
      return ApiResponse(success: true, message: 'Đã ẩn đánh giá');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
