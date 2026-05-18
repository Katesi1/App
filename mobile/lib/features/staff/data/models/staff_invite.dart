import 'package:equatable/equatable.dart';

/// Invite status — matches backend.
enum StaffInviteStatus { pending, accepted, expired, cancelled, unknown }

StaffInviteStatus _statusFromString(String? raw) {
  switch (raw) {
    case 'pending':
      return StaffInviteStatus.pending;
    case 'accepted':
      return StaffInviteStatus.accepted;
    case 'expired':
      return StaffInviteStatus.expired;
    case 'cancelled':
      return StaffInviteStatus.cancelled;
    default:
      return StaffInviteStatus.unknown;
  }
}

extension StaffInviteStatusX on StaffInviteStatus {
  String get apiValue {
    switch (this) {
      case StaffInviteStatus.pending:
        return 'pending';
      case StaffInviteStatus.accepted:
        return 'accepted';
      case StaffInviteStatus.expired:
        return 'expired';
      case StaffInviteStatus.cancelled:
        return 'cancelled';
      case StaffInviteStatus.unknown:
        return '';
    }
  }

  String get label {
    switch (this) {
      case StaffInviteStatus.pending:
        return 'Đang chờ';
      case StaffInviteStatus.accepted:
        return 'Đã chấp nhận';
      case StaffInviteStatus.expired:
        return 'Hết hạn';
      case StaffInviteStatus.cancelled:
        return 'Đã huỷ';
      case StaffInviteStatus.unknown:
        return '—';
    }
  }
}

/// Invite created by OWNER. Returned from `POST /staff/invites` and `GET /staff/invites`.
class StaffInvite extends Equatable {
  final String id;
  final String email;
  final String shortCode;
  final StaffInviteStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final String? acceptedUserId;
  final String? inviteLink;

  const StaffInvite({
    required this.id,
    required this.email,
    required this.shortCode,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.acceptedAt,
    this.acceptedUserId,
    this.inviteLink,
  });

  factory StaffInvite.fromJson(Map<String, dynamic> json) => StaffInvite(
        id: json['id'] as String,
        email: json['email'] as String,
        shortCode: json['shortCode'] as String? ?? '',
        status: _statusFromString(json['status'] as String?),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        acceptedAt: json['acceptedAt'] == null
            ? null
            : DateTime.tryParse(json['acceptedAt'] as String),
        acceptedUserId: json['acceptedUserId'] as String?,
        inviteLink: json['inviteLink'] as String?,
      );

  bool get isExpired =>
      status == StaffInviteStatus.expired ||
      DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        id,
        email,
        shortCode,
        status,
        expiresAt,
        createdAt,
        acceptedAt,
        acceptedUserId,
        inviteLink,
      ];
}

/// Preview of OWNER info + invite — returned from `GET /staff/invites/verify/:token`.
/// Used to show confirm screen before accepting.
class StaffInvitePreview extends Equatable {
  final String email;
  final String ownerName;
  final String? ownerAvatar;
  final String? homestayName;
  final DateTime expiresAt;
  final StaffInviteStatus status;

  const StaffInvitePreview({
    required this.email,
    required this.ownerName,
    this.ownerAvatar,
    this.homestayName,
    required this.expiresAt,
    required this.status,
  });

  factory StaffInvitePreview.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    return StaffInvitePreview(
      email: json['email'] as String,
      ownerName: owner['name'] as String? ?? '',
      ownerAvatar: owner['avatar'] as String?,
      homestayName: owner['homestayName'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      status: _statusFromString(json['status'] as String?),
    );
  }

  bool get canAccept => status == StaffInviteStatus.pending;

  @override
  List<Object?> get props =>
      [email, ownerName, ownerAvatar, homestayName, expiresAt, status];
}
