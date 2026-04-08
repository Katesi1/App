import 'package:equatable/equatable.dart';

enum NotificationType {
  booking,
  payment,
  system,
}

extension NotificationTypeX on NotificationType {
  String get label => switch (this) {
        NotificationType.booking => 'Booking',
        NotificationType.payment => 'Thanh toán',
        NotificationType.system => 'Hệ thống',
      };
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? targetId;
  final String? targetType;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.targetId,
    this.targetType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (json['type'] as String?)?.toLowerCase(),
        orElse: () => NotificationType.system,
      ),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      targetId: json['targetId'] as String?,
      targetType: json['targetType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'type': type.name,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'targetId': targetId,
        'targetType': targetType,
      };

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      subtitle: subtitle,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      targetId: targetId,
      targetType: targetType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        type,
        isRead,
        createdAt,
        targetId,
        targetType,
      ];
}
