import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/account_models.dart';

/// API cho các module "Tài khoản" của profile (BE §24): support tickets,
/// feedback, data export, consents, notification preferences. Theo chuẩn
/// `ApiResponse<T>` (không throw).
class AccountRepository {
  final Dio _dio = ApiClient.instance;

  // ── Support tickets ───────────────────────────────────────────────────────

  Future<ApiResponse<List<SupportTicket>>> getTickets({
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _dio.get(ApiConstants.supportTickets, queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'limit': limit,
      });
      return ApiResponse(
        success: true,
        data: _items(res.data).map(SupportTicket.fromJson).toList(),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  Future<ApiResponse<SupportTicket>> getTicket(String id) async {
    try {
      final res = await _dio.get(ApiConstants.supportTicketDetail(id));
      return ApiResponse(
        success: true,
        data: SupportTicket.fromJson(res.data['data'] as Map<String, dynamic>),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  Future<ApiResponse<SupportTicket>> createTicket({
    required String subject,
    required String category,
    required String description,
  }) async {
    try {
      final res = await _dio.post(ApiConstants.supportTickets, data: {
        'subject': subject,
        'category': category,
        'description': description,
      });
      return ApiResponse(
        success: true,
        data: SupportTicket.fromJson(res.data['data'] as Map<String, dynamic>),
        message: res.data['message'] ?? 'Đã gửi yêu cầu',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  Future<ApiResponse<void>> replyTicket(String id, String message) async {
    try {
      await _dio.post(ApiConstants.supportTicketReply(id),
          data: {'message': message});
      return ApiResponse(success: true, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  Future<ApiResponse<void>> submitFeedback({
    required String category,
    required String message,
    String? contact,
    String? deviceInfo,
  }) async {
    try {
      await _dio.post(ApiConstants.feedback, data: {
        'category': category,
        'message': message,
        if (contact != null && contact.isNotEmpty) 'contact': contact,
        if (deviceInfo != null && deviceInfo.isNotEmpty)
          'deviceInfo': deviceInfo,
      });
      return ApiResponse(success: true, message: 'Đã gửi phản hồi');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  // ── Data export (GDPR) ────────────────────────────────────────────────────

  Future<ApiResponse<List<DataExportRequest>>> getDataExports() async {
    try {
      final res = await _dio.get(ApiConstants.dataExport);
      return ApiResponse(
        success: true,
        data: _items(res.data).map(DataExportRequest.fromJson).toList(),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  Future<ApiResponse<DataExportRequest>> requestDataExport() async {
    try {
      final res = await _dio.post(ApiConstants.dataExport);
      return ApiResponse(
        success: true,
        data: DataExportRequest.fromJson(
            res.data['data'] as Map<String, dynamic>),
        message: res.data['message'] ?? 'Đã gửi yêu cầu',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  // ── Consents ──────────────────────────────────────────────────────────────

  Future<ApiResponse<ConsentSettings>> getConsents() async {
    try {
      final res = await _dio.get(ApiConstants.consents);
      return ApiResponse(
        success: true,
        data:
            ConsentSettings.fromJson(res.data['data'] as Map<String, dynamic>),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  Future<ApiResponse<ConsentSettings>> updateConsents(
      {required bool marketing}) async {
    try {
      final res =
          await _dio.put(ApiConstants.consents, data: {'marketing': marketing});
      return ApiResponse(
        success: true,
        data:
            ConsentSettings.fromJson(res.data['data'] as Map<String, dynamic>),
        message: res.data['message'] ?? 'Đã lưu',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  // ── Notification preferences ──────────────────────────────────────────────

  Future<ApiResponse<NotificationPrefs>> getNotificationPrefs() async {
    try {
      final res = await _dio.get(ApiConstants.notificationPreferences);
      return ApiResponse(
        success: true,
        data: NotificationPrefs.fromJson(
            res.data['data'] as Map<String, dynamic>),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  Future<ApiResponse<NotificationPrefs>> updateNotificationPrefs(
      NotificationPrefs prefs) async {
    try {
      final res = await _dio.put(ApiConstants.notificationPreferences,
          data: prefs.toJson());
      return ApiResponse(
        success: true,
        data: NotificationPrefs.fromJson(
            res.data['data'] as Map<String, dynamic>),
        message: res.data['message'] ?? 'Đã lưu',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  static const _badSchema = 'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại.';

  /// `{ data: { items:[...] } }` (Shape A) hoặc `{ data: [...] }`.
  List<Map<String, dynamic>> _items(dynamic body) {
    final data = body is Map ? body['data'] : null;
    final raw = data is Map ? data['items'] : data;
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}
