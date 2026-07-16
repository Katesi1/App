import 'package:equatable/equatable.dart';

enum AbuseReportStatus {
  pending,
  investigating,
  resolved,
  dismissed,
}

enum AbuseReportLevel {
  high,
  medium,
  low,
}

enum AbuseReportCategory {
  spam,
  content,
  fraud,
  other,
}

enum AbuseTargetType {
  property,
  user,
  review,
  booking,
}

extension AbuseReportStatusX on AbuseReportStatus {
  String get label => switch (this) {
        AbuseReportStatus.pending => 'Chờ xử lý',
        AbuseReportStatus.investigating => 'Đang điều tra',
        AbuseReportStatus.resolved => 'Đã xử lý',
        AbuseReportStatus.dismissed => 'Bỏ qua',
      };

  bool get isActionable =>
      this == AbuseReportStatus.pending ||
      this == AbuseReportStatus.investigating;
}

extension AbuseReportLevelX on AbuseReportLevel {
  String get label => switch (this) {
        AbuseReportLevel.high => 'Cao',
        AbuseReportLevel.medium => 'Trung bình',
        AbuseReportLevel.low => 'Thấp',
      };
}

extension AbuseReportCategoryX on AbuseReportCategory {
  String get label => switch (this) {
        AbuseReportCategory.spam => 'Spam',
        AbuseReportCategory.content => 'Nội dung',
        AbuseReportCategory.fraud => 'Gian lận',
        AbuseReportCategory.other => 'Khác',
      };
}

extension AbuseTargetTypeX on AbuseTargetType {
  String get label => switch (this) {
        AbuseTargetType.property => 'Tin đăng',
        AbuseTargetType.user => 'Người dùng',
        AbuseTargetType.review => 'Đánh giá',
        AbuseTargetType.booking => 'Booking',
      };
}

class AbuseReport extends Equatable {
  final String id;
  final String title;
  final String description;
  final String reporterId;
  final String reporterName;
  final AbuseReportLevel level;
  final AbuseReportCategory category;
  final AbuseReportStatus status;
  final AbuseTargetType targetType;
  final String targetId;
  final String targetLabel;
  final DateTime createdAt;
  final DateTime? handledAt;
  final String? handledBy;
  final String? resolution;

  const AbuseReport({
    required this.id,
    required this.title,
    required this.description,
    required this.reporterId,
    required this.reporterName,
    required this.level,
    required this.category,
    required this.status,
    required this.targetType,
    required this.targetId,
    required this.targetLabel,
    required this.createdAt,
    this.handledAt,
    this.handledBy,
    this.resolution,
  });

  bool get isPending => status == AbuseReportStatus.pending;

  /// Map 1 dispute DTO (backend `/admin/disputes` list item hoặc
  /// `/admin/disputes/:id` detail) → [AbuseReport].
  ///
  /// Dispute không có field `level`/`category`/`targetType` tương đương —
  /// suy diễn từ `type` (xem [_levelFromDisputeType]/[_categoryFromDisputeType]).
  /// Dispute luôn gắn với 1 booking nên `targetType` = booking.
  factory AbuseReport.fromDisputeJson(Map<String, dynamic> json) {
    final openerType = json['openerType'] as String?;
    final owner = json['owner'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;
    final property = json['property'] as Map<String, dynamic>?;
    final booking = json['booking'] as Map<String, dynamic>?;

    // Người mở tranh chấp — detail trả kèm owner/customer, list có thể không.
    final opener = switch (openerType) {
      'owner' || 'sale' => owner,
      'customer' => customer,
      _ => null,
    };
    final reporterId = (opener?['id'] as String?) ??
        (json['openedById'] as String?) ??
        (json['reporterId'] as String?) ??
        '';
    final reporterName = (opener?['name'] as String?) ??
        _openerLabel(openerType);

    final bookingId = (json['bookingId'] as String?) ??
        (booking?['id'] as String?) ??
        '';
    final targetLabel = (property?['name'] as String?) ??
        (booking?['code'] as String?) ??
        (bookingId.isNotEmpty ? 'Booking $bookingId' : '—');

    final type = json['type'] as String?;

    return AbuseReport(
      id: (json['id'] as String?) ?? '',
      title: (json['subject'] as String?) ?? '—',
      description: (json['description'] as String?) ?? '',
      reporterId: reporterId,
      reporterName: reporterName,
      level: _levelFromDisputeType(type),
      category: _categoryFromDisputeType(type),
      status: _statusFromDisputeApi(json['status'] as String?),
      targetType: AbuseTargetType.booking,
      targetId: bookingId,
      targetLabel: targetLabel,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      handledAt: _parseDate(json['resolvedAt']),
      handledBy: (json['resolvedByName'] as String?) ??
          (json['resolvedById'] as String?),
      resolution: (json['resolution'] as String?) ??
          (json['verdict'] as String?),
    );
  }

  static String _openerLabel(String? openerType) => switch (openerType) {
        'owner' => 'Chủ homestay',
        'sale' => 'Nhân viên',
        'customer' => 'Khách hàng',
        'admin' => 'Quản trị viên',
        _ => 'Người dùng',
      };

  // `rejected` (dispute) ↔ `dismissed` (báo cáo vi phạm).
  static AbuseReportStatus _statusFromDisputeApi(String? raw) =>
      switch (raw) {
        'pending' => AbuseReportStatus.pending,
        'investigating' => AbuseReportStatus.investigating,
        'resolved' => AbuseReportStatus.resolved,
        'rejected' => AbuseReportStatus.dismissed,
        _ => AbuseReportStatus.pending,
      };

  // Suy diễn mức độ ưu tiên từ loại tranh chấp (dispute không có field level).
  static AbuseReportLevel _levelFromDisputeType(String? type) =>
      switch (type) {
        'refund_request' || 'damage_claim' => AbuseReportLevel.high,
        'service_quality' || 'no_show' || 'overbooking' =>
          AbuseReportLevel.medium,
        _ => AbuseReportLevel.low,
      };

  // Ánh xạ gần đúng dispute type → category (không có mapping 1-1).
  static AbuseReportCategory _categoryFromDisputeType(String? type) =>
      switch (type) {
        'refund_request' || 'damage_claim' => AbuseReportCategory.fraud,
        'service_quality' => AbuseReportCategory.content,
        _ => AbuseReportCategory.other,
      };

  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  AbuseReport copyWith({
    AbuseReportStatus? status,
    DateTime? handledAt,
    String? handledBy,
    String? resolution,
  }) {
    return AbuseReport(
      id: id,
      title: title,
      description: description,
      reporterId: reporterId,
      reporterName: reporterName,
      level: level,
      category: category,
      status: status ?? this.status,
      targetType: targetType,
      targetId: targetId,
      targetLabel: targetLabel,
      createdAt: createdAt,
      handledAt: handledAt ?? this.handledAt,
      handledBy: handledBy ?? this.handledBy,
      resolution: resolution ?? this.resolution,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        reporterId,
        reporterName,
        level,
        category,
        status,
        targetType,
        targetId,
        targetLabel,
        createdAt,
        handledAt,
        handledBy,
        resolution,
      ];
}
