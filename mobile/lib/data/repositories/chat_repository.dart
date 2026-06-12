import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// 1 trang messages trả về từ GET /conversations/:id/messages (cursor-based,
/// oldest-first + nextCursor).
typedef MessagePage = ({List<MessageModel> messages, String? nextCursor});

/// Data layer cho Chat REST API (xem API §17.1). WebSocket realtime nằm ở
/// `core/services/chat_socket_service.dart`. Repository chỉ gọi API + parse,
/// luôn trả [ApiResponse] — không throw (theo convention dự án, Section 10).
class ChatRepository {
  final Dio _dio = ApiClient.instance;

  /// Inbox — sort `lastMessageAt DESC`, trả `myUnread` per item.
  Future<ApiResponse<List<ConversationModel>>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.conversations,
        queryParameters: {'page': page, 'limit': limit},
      );
      final list = (response.data['data'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ConversationModel.fromJson)
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// Badge tổng số tin chưa đọc.
  Future<ApiResponse<int>> getUnreadCount() async {
    try {
      final response = await _dio.get(ApiConstants.conversationsUnreadCount);
      final data = response.data['data'];
      final count = data is Map
          ? (data['count'] as num?)?.toInt() ?? 0
          : (data as num?)?.toInt() ?? 0;
      return ApiResponse(success: true, data: count, message: '');
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// Detail kèm members hydrated.
  Future<ApiResponse<ConversationModel>> getConversation(String id) async {
    try {
      final response = await _dio.get(ApiConstants.conversationDetail(id));
      return ApiResponse(
        success: true,
        data: ConversationModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        ),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// Tạo conversation. Idempotent với booking-type (BE trả conversation đã có
  /// nếu trùng booking).
  Future<ApiResponse<ConversationModel>> createConversation({
    required ConversationType type,
    String? bookingId,
    String? subject,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.conversations,
        data: {
          'type': type.name,
          if (bookingId != null) 'bookingId': bookingId,
          if (subject != null && subject.isNotEmpty) 'subject': subject,
        },
      );
      return ApiResponse(
        success: true,
        data: ConversationModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        ),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// Lịch sử tin — cursor-based, oldest-first + nextCursor. Cursor sai/expired
  /// BE tự degrade về đầu danh sách (không throw 500).
  Future<ApiResponse<MessagePage>> getMessages(
    String conversationId, {
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.conversationMessages(conversationId),
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      final body = response.data;
      final rawList = (body['data'] as List? ?? body['messages'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MessageModel.fromJson)
          .toList();
      final nextCursor =
          (body['nextCursor'] ?? body['meta']?['nextCursor']) as String?;
      return ApiResponse(
        success: true,
        data: (messages: rawList, nextCursor: nextCursor),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// REST fallback gửi tin (BE tự broadcast qua WS). Dùng khi socket chưa
  /// connect.
  Future<ApiResponse<MessageModel>> sendMessage(
    String conversationId, {
    required String content,
    List<MessageAttachment> attachments = const [],
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.conversationMessages(conversationId),
        data: {
          'content': content,
          if (attachments.isNotEmpty)
            'attachments': attachments.map((a) => a.toJson()).toList(),
        },
      );
      return ApiResponse(
        success: true,
        data: MessageModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        ),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// Mark toàn bộ conversation đã đọc.
  Future<ApiResponse<void>> markRead(String conversationId) async {
    try {
      await _dio.patch(ApiConstants.conversationRead(conversationId));
      return ApiResponse(success: true, message: '');
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// Sửa tin (chỉ sender, trong 15 phút). Broadcast `message:edit`.
  Future<ApiResponse<MessageModel>> editMessage(
    String messageId, {
    required String content,
  }) async {
    try {
      final response = await _dio.patch(
        ApiConstants.conversationMessageDetail(messageId),
        data: {'content': content},
      );
      return ApiResponse(
        success: true,
        data: MessageModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        ),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// Xoá tin (sender hoặc admin). Soft-delete. Broadcast `message:delete`.
  Future<ApiResponse<void>> deleteMessage(String messageId) async {
    try {
      await _dio.delete(ApiConstants.conversationMessageDetail(messageId));
      return ApiResponse(success: true, message: '');
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }
}
