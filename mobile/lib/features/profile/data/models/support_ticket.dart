import 'package:equatable/equatable.dart';

/// Ticket hỗ trợ — `GET/POST /support/tickets`.
class SupportTicket extends Equatable {
  final String id;
  final String? ticketCode;
  final String subject;
  final String status;
  final String? priority;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportTicket({
    required this.id,
    this.ticketCode,
    required this.subject,
    required this.status,
    this.priority,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      ticketCode: (json['ticketCode'] ?? json['ticket_code'] ?? json['code'])
          as String?,
      subject: (json['subject'] ?? json['title'] ?? '') as String,
      status: (json['status'] ?? 'open') as String,
      priority: json['priority'] as String?,
      category: json['category'] as String?,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  String get displayCode =>
      ticketCode != null && ticketCode!.isNotEmpty ? ticketCode! : id;

  String get statusLabel => _statusLabel(status);

  static String _statusLabel(String raw) {
    switch (raw.toLowerCase()) {
      case 'open':
      case 'pending':
        return 'Mới';
      case 'in_progress':
      case 'processing':
      case 'investigating':
        return 'Đang xử lý';
      case 'resolved':
      case 'closed':
        return 'Đã giải quyết';
      case 'cancelled':
        return 'Đã huỷ';
      default:
        return raw;
    }
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  @override
  List<Object?> get props =>
      [id, ticketCode, subject, status, priority, category, createdAt];
}

/// Tin nhắn trong thread ticket.
class SupportTicketMessage extends Equatable {
  final String id;
  final String body;
  final String senderType;
  final DateTime? createdAt;

  const SupportTicketMessage({
    required this.id,
    required this.body,
    required this.senderType,
    this.createdAt,
  });

  factory SupportTicketMessage.fromJson(Map<String, dynamic> json) {
    return SupportTicketMessage(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      body: (json['body'] ?? json['message'] ?? json['content'] ?? '')
          as String,
      senderType: (json['senderType'] ??
              json['sender_type'] ??
              json['sender'] ??
              'user')
          as String,
      createdAt: SupportTicket._parseDate(
        json['createdAt'] ?? json['created_at'],
      ),
    );
  }

  bool get isStaff =>
      senderType.toLowerCase() == 'staff' ||
      senderType.toLowerCase() == 'admin' ||
      senderType.toLowerCase() == 'support';

  @override
  List<Object?> get props => [id, body, senderType, createdAt];
}

class SupportTicketDetail extends Equatable {
  final SupportTicket ticket;
  final List<SupportTicketMessage> messages;

  const SupportTicketDetail({
    required this.ticket,
    required this.messages,
  });

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    final messagesRaw = (json['messages'] ??
            json['replies'] ??
            json['thread'] ??
            const []) as List;
    return SupportTicketDetail(
      ticket: SupportTicket.fromJson(json),
      messages: messagesRaw
          .whereType<Map<String, dynamic>>()
          .map(SupportTicketMessage.fromJson)
          .toList(),
    );
  }

  @override
  List<Object?> get props => [ticket, messages];
}
