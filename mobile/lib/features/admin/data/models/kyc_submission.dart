import 'package:equatable/equatable.dart';

import '../../../verify/data/models/cccd_upload.dart';
import '../../../verify/data/models/selfie_upload.dart';
import '../../../verify/data/models/verify_enums.dart';

/// Một hồ sơ KYC chờ admin duyệt — view-model cho [KYCApprovalListScreen]
/// và [KYCApprovalDetailScreen].
///
/// Wraps [CCCDUpload] front + back + [SelfieUpload] cùng metadata về owner
/// đã submit (tên, phone, plan đã chọn, total tiền tạm giữ).
class KYCSubmission extends Equatable {
  final String id;

  // ── Owner submitting ──
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String? ownerEmail;

  // ── KYC payload ──
  final CCCDUpload cccdFront;
  final CCCDUpload cccdBack;
  final SelfieUpload selfie;

  // ── Subscription context ──
  final String planName; // e.g. "Professional · Hàng năm"
  final int totalAmount; // tiền đã thanh toán (tạm giữ)
  final int expectedRooms;

  // ── Timeline ──
  final DateTime submittedAt;
  final VerifyStatus status;

  /// Reason nếu admin reject (null nếu chưa quyết định).
  final String? rejectReason;
  final List<RejectableItem> rejectedItems;

  /// Tên admin xử lý (set khi approve/reject).
  final String? handledByAdmin;
  final DateTime? handledAt;

  const KYCSubmission({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    this.ownerEmail,
    required this.cccdFront,
    required this.cccdBack,
    required this.selfie,
    required this.planName,
    required this.totalAmount,
    required this.expectedRooms,
    required this.submittedAt,
    required this.status,
    this.rejectReason,
    this.rejectedItems = const [],
    this.handledByAdmin,
    this.handledAt,
  });

  bool get isPending => status == VerifyStatus.awaitingApproval;
  bool get isApproved => status == VerifyStatus.approved;
  bool get isRejected => status == VerifyStatus.rejected;

  /// Số giờ kể từ lúc submit (để hiển thị "5h trước" / "Quá 24h").
  Duration get age => DateTime.now().difference(submittedAt);

  /// Vượt SLA 24h chưa.
  bool get isOverdue => age.inHours >= 24 && isPending;

  KYCSubmission copyWith({
    VerifyStatus? status,
    String? rejectReason,
    List<RejectableItem>? rejectedItems,
    String? handledByAdmin,
    DateTime? handledAt,
  }) =>
      KYCSubmission(
        id: id,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        ownerEmail: ownerEmail,
        cccdFront: cccdFront,
        cccdBack: cccdBack,
        selfie: selfie,
        planName: planName,
        totalAmount: totalAmount,
        expectedRooms: expectedRooms,
        submittedAt: submittedAt,
        status: status ?? this.status,
        rejectReason: rejectReason ?? this.rejectReason,
        rejectedItems: rejectedItems ?? this.rejectedItems,
        handledByAdmin: handledByAdmin ?? this.handledByAdmin,
        handledAt: handledAt ?? this.handledAt,
      );

  @override
  List<Object?> get props => [
        id,
        ownerId,
        status,
        rejectReason,
        rejectedItems,
        handledByAdmin,
        handledAt,
      ];
}
