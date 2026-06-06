import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/data_export_request.dart';
import '../models/notification_preferences.dart';
import '../models/support_ticket.dart';
import '../models/user_consents.dart';

class ProfileSettingsRepository {
  final Dio _dio = ApiClient.instance;

  // ── Support tickets ───────────────────────────────────────────────────────

  Future<ApiResponse<List<SupportTicket>>> getTickets({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.supportTickets,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = res.data['data'];
      final list = _asList(data).map(SupportTicket.fromJson).toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<SupportTicket>> createTicket({
    required String subject,
    required String message,
    String? category,
    String? contact,
    String? priority,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.supportTickets,
        data: {
          'subject': subject,
          'message': message,
          if (category != null) 'category': category,
          if (contact != null && contact.isNotEmpty) 'contact': contact,
          if (priority != null) 'priority': priority,
        },
      );
      final raw = res.data['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        data: SupportTicket.fromJson(raw),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<SupportTicketDetail>> getTicketDetail(String id) async {
    try {
      final res = await _dio.get(ApiConstants.supportTicketDetail(id));
      final raw = res.data['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        data: SupportTicketDetail.fromJson(raw),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<SupportTicketMessage>> replyTicket({
    required String ticketId,
    required String message,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.supportTicketReply(ticketId),
        data: {'message': message},
      );
      final raw = res.data['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        data: SupportTicketMessage.fromJson(raw),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  Future<ApiResponse<void>> submitFeedback({
    required String category,
    required String content,
    String? contact,
    bool includeDeviceInfo = false,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      await _dio.post(
        ApiConstants.feedback,
        data: {
          'category': category,
          'content': content,
          if (contact != null && contact.isNotEmpty) 'contact': contact,
          'includeDeviceInfo': includeDeviceInfo,
          if (includeDeviceInfo && deviceInfo != null)
            'deviceInfo': deviceInfo,
        },
      );
      return ApiResponse(success: true, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  // ── Data export ───────────────────────────────────────────────────────────

  Future<ApiResponse<List<DataExportRequest>>> getDataExports() async {
    try {
      final res = await _dio.get(ApiConstants.userMeDataExport);
      final data = res.data['data'];
      if (data is Map<String, dynamic>) {
        return ApiResponse(
          success: true,
          data: [DataExportRequest.fromJson(data)],
          message: '',
        );
      }
      final list = _asList(data).map(DataExportRequest.fromJson).toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<DataExportRequest>> requestDataExport() async {
    try {
      final res = await _dio.post(ApiConstants.userMeDataExport);
      final raw = res.data['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        data: DataExportRequest.fromJson(raw),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  // ── Consents ──────────────────────────────────────────────────────────────

  Future<ApiResponse<UserConsents>> getConsents() async {
    try {
      final res = await _dio.get(ApiConstants.userMeConsents);
      final raw = res.data['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        data: UserConsents.fromJson(raw),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<UserConsents>> updateConsents(
    UserConsents consents,
  ) async {
    try {
      final res = await _dio.put(
        ApiConstants.userMeConsents,
        data: consents.toJson(),
      );
      final raw = res.data['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        data: UserConsents.fromJson(raw),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  // ── Notification preferences ────────────────────────────────────────────────

  Future<ApiResponse<NotificationPreferences>>
      getNotificationPreferences() async {
    try {
      final res = await _dio.get(ApiConstants.userMeNotificationPreferences);
      final raw = res.data['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        data: NotificationPreferences.fromJson(raw),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<NotificationPreferences>> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    try {
      final res = await _dio.put(
        ApiConstants.userMeNotificationPreferences,
        data: prefs.toJson(),
      );
      final raw = res.data['data'] as Map<String, dynamic>;
      return ApiResponse(
        success: true,
        data: NotificationPreferences.fromJson(raw),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['tickets'] ?? data['exports'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }
}

final profileSettingsRepositoryProvider =
    Provider<ProfileSettingsRepository>((ref) => ProfileSettingsRepository());
