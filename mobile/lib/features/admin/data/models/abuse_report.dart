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
