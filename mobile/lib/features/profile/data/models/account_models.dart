/// Models cho các module "Tài khoản" của profile (BE §24): support tickets,
/// data export (GDPR), consents, notification preferences.
library;

// ── Support tickets ─────────────────────────────────────────────────────────

class TicketMessage {
  final String id;
  final bool fromAdmin;
  final String message;
  final DateTime? createdAt;

  const TicketMessage({
    required this.id,
    required this.fromAdmin,
    required this.message,
    this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> j) => TicketMessage(
        id: (j['id'] ?? '') as String,
        fromAdmin: (j['fromAdmin'] ?? j['isAdmin'] ?? false) as bool,
        message: (j['message'] ?? j['content'] ?? '') as String,
        createdAt: _date(j['createdAt']),
      );
}

class SupportTicket {
  final String id;
  final String code; // HT-XXXXXX
  final String subject;
  final String category; // account | payment | technical | other
  final String status; // open | in_progress | resolved | closed
  final String? description;
  final List<TicketMessage> messages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SupportTicket({
    required this.id,
    required this.code,
    required this.subject,
    required this.category,
    required this.status,
    this.description,
    this.messages = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> j) => SupportTicket(
        id: (j['id'] ?? '') as String,
        code: (j['code'] ?? '') as String,
        subject: (j['subject'] ?? '') as String,
        category: (j['category'] ?? 'other') as String,
        status: (j['status'] ?? 'open') as String,
        description: j['description'] as String?,
        messages: (j['messages'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(TicketMessage.fromJson)
                .toList() ??
            const [],
        createdAt: _date(j['createdAt']),
        updatedAt: _date(j['updatedAt']),
      );

  String get categoryLabel => switch (category) {
        'account' => 'Tài khoản',
        'payment' => 'Thanh toán',
        'technical' => 'Kỹ thuật',
        _ => 'Khác',
      };

  String get statusLabel => switch (status) {
        'open' => 'Mới',
        'in_progress' => 'Đang xử lý',
        'resolved' => 'Đã giải quyết',
        'closed' => 'Đã đóng',
        _ => status,
      };

  bool get isClosed => status == 'resolved' || status == 'closed';
}

const kTicketCategories = <(String, String)>[
  ('account', 'Tài khoản'),
  ('payment', 'Thanh toán'),
  ('technical', 'Kỹ thuật'),
  ('other', 'Khác'),
];

// ── Data export (GDPR) ──────────────────────────────────────────────────────

class DataExportRequest {
  final String id;
  final String status; // pending | processing | ready | expired
  final DateTime? requestedAt;
  final DateTime? expiresAt;
  final String? downloadUrl;

  const DataExportRequest({
    required this.id,
    required this.status,
    this.requestedAt,
    this.expiresAt,
    this.downloadUrl,
  });

  factory DataExportRequest.fromJson(Map<String, dynamic> j) =>
      DataExportRequest(
        id: (j['id'] ?? '') as String,
        status: (j['status'] ?? 'pending') as String,
        requestedAt: _date(j['requestedAt'] ?? j['createdAt']),
        expiresAt: _date(j['expiresAt']),
        downloadUrl: j['downloadUrl'] as String?,
      );

  String get statusLabel => switch (status) {
        'pending' => 'Chờ xử lý',
        'processing' => 'Đang chuẩn bị',
        'ready' => 'Sẵn sàng tải',
        'expired' => 'Đã hết hạn',
        _ => status,
      };

  bool get isReady => status == 'ready' && (downloadUrl?.isNotEmpty ?? false);
  bool get isActive => status == 'pending' || status == 'processing';
}

// ── Consents ────────────────────────────────────────────────────────────────

class ConsentSettings {
  final bool kyc; // server-locked, luôn true khi đang dùng dịch vụ
  final bool marketing;
  final DateTime? updatedAt;

  const ConsentSettings({
    required this.kyc,
    required this.marketing,
    this.updatedAt,
  });

  factory ConsentSettings.fromJson(Map<String, dynamic> j) => ConsentSettings(
        kyc: (j['kyc'] ?? true) as bool,
        marketing: (j['marketing'] ?? false) as bool,
        updatedAt: _date(j['updatedAt']),
      );
}

// ── Notification preferences ────────────────────────────────────────────────

class NotificationPrefs {
  final bool booking;
  final bool payment;
  final bool system;
  final bool quietHours;
  final String quietFrom; // "22:00"
  final String quietTo; // "07:00"

  const NotificationPrefs({
    this.booking = true,
    this.payment = true,
    this.system = true,
    this.quietHours = false,
    this.quietFrom = '22:00',
    this.quietTo = '07:00',
  });

  factory NotificationPrefs.fromJson(Map<String, dynamic> j) =>
      NotificationPrefs(
        booking: (j['booking'] ?? true) as bool,
        payment: (j['payment'] ?? true) as bool,
        system: (j['system'] ?? true) as bool,
        quietHours: (j['quietHours'] ?? false) as bool,
        quietFrom: (j['quietFrom'] ?? '22:00') as String,
        quietTo: (j['quietTo'] ?? '07:00') as String,
      );

  Map<String, dynamic> toJson() => {
        'booking': booking,
        'payment': payment,
        'system': system,
        'quietHours': quietHours,
        'quietFrom': quietFrom,
        'quietTo': quietTo,
      };

  NotificationPrefs copyWith({
    bool? booking,
    bool? payment,
    bool? system,
    bool? quietHours,
  }) =>
      NotificationPrefs(
        booking: booking ?? this.booking,
        payment: payment ?? this.payment,
        system: system ?? this.system,
        quietHours: quietHours ?? this.quietHours,
        quietFrom: quietFrom,
        quietTo: quietTo,
      );
}

DateTime? _date(dynamic raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
