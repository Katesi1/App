import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// 1 trang tin nhắn (cursor-based, oldest-first) + cursor trang kế.
class MessagePage {
  final List<ChatMessage> messages;
  final String? nextCursor;
  const MessagePage({required this.messages, this.nextCursor});
}

/// REST cho chat (BE §17.1). Realtime đi qua [ChatSocketService]; REST dùng để
/// tải lịch sử, inbox, unread badge, mark-read và fallback gửi tin.
class ChatRepository {
  final Dio _dio = ApiClient.instance;

  Future<ApiResponse<List<Conversation>>> getConversations({
    String? role,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final res = await _dio.get(ApiConstants.conversations, queryParameters: {
        if (role != null && role.isNotEmpty) 'role': role,
        'page': page,
        'limit': limit,
      });
      return ApiResponse(
        success: true,
        data: _items(res.data).map(Conversation.fromJson).toList(),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  Future<ApiResponse<int>> getUnreadCount() async {
    try {
      final res = await _dio.get(ApiConstants.conversationsUnreadCount);
      final data = res.data is Map ? res.data['data'] : res.data;
      final count = data is Map ? (data['count'] ?? data['unread']) : data;
      return ApiResponse(
        success: true,
        data: (count as num?)?.toInt() ?? 0,
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  /// Lấy (hoặc tạo) hội thoại `type=booking` cho 1 booking. BE idempotent:
  /// gọi nhiều lần cùng `bookingId` → trả về đúng 1 hội thoại (BE §17.1).
  Future<ApiResponse<Conversation>> createOrGetBookingConversation(
    String bookingId,
  ) async {
    try {
      final res = await _dio.post(ApiConstants.conversations, data: {
        'type': 'booking',
        'bookingId': bookingId,
      });
      return ApiResponse(
        success: true,
        data: Conversation.fromJson(res.data['data'] as Map<String, dynamic>),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  Future<ApiResponse<Conversation>> getConversation(String id) async {
    try {
      final res = await _dio.get(ApiConstants.conversationDetail(id));
      return ApiResponse(
        success: true,
        data: Conversation.fromJson(res.data['data'] as Map<String, dynamic>),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  Future<ApiResponse<MessagePage>> getMessages(
    String conversationId, {
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.conversationMessages(conversationId),
        queryParameters: {
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
          'limit': limit,
        },
      );
      final body = res.data is Map ? res.data['data'] : null;
      final rawList = body is Map
          ? (body['items'] ?? body['messages'] ?? body['data'])
          : body;
      final nextCursor = body is Map ? body['nextCursor'] as String? : null;
      final list = (rawList is List ? rawList : const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
      return ApiResponse(
        success: true,
        data: MessagePage(messages: list, nextCursor: nextCursor),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  /// REST fallback gửi tin (BE tự broadcast qua WS). Dùng khi socket rớt.
  Future<ApiResponse<ChatMessage>> sendMessage(
    String conversationId, {
    required String content,
    List<ChatAttachment> attachments = const [],
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.conversationMessages(conversationId),
        data: {
          'content': content,
          if (attachments.isNotEmpty)
            'attachments': attachments.map((a) => a.toJson()).toList(),
        },
      );
      return ApiResponse(
        success: true,
        data: ChatMessage.fromJson(res.data['data'] as Map<String, dynamic>),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  Future<ApiResponse<void>> markRead(String conversationId) async {
    try {
      await _dio.patch(ApiConstants.conversationRead(conversationId));
      return ApiResponse(success: true, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Sửa nội dung tin nhắn (chỉ sender, trong 15 phút). BE broadcast
  /// `message:edit` qua WS → các client khác tự cập nhật.
  Future<ApiResponse<ChatMessage>> editMessage(
    String messageId, {
    required String content,
  }) async {
    try {
      final res = await _dio.patch(
        ApiConstants.conversationMessage(messageId),
        data: {'content': content},
      );
      return ApiResponse(
        success: true,
        data: ChatMessage.fromJson(res.data['data'] as Map<String, dynamic>),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(success: false, message: _badSchema);
    }
  }

  /// Xoá (soft-delete) tin nhắn — sender hoặc admin. BE broadcast
  /// `message:delete` qua WS.
  Future<ApiResponse<void>> deleteMessage(String messageId) async {
    try {
      await _dio.delete(ApiConstants.conversationMessage(messageId));
      return ApiResponse(success: true, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
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
