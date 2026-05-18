import 'package:equatable/equatable.dart';

import '../../../verify/data/models/cccd_upload.dart';
import '../../../verify/data/models/selfie_upload.dart';
import '../../../verify/data/models/verify_enums.dart';

/// A KYC application waiting for admin review — view-model for
/// [KYCApprovalListScreen] and [KYCApprovalDetailScreen].
///
/// Wraps [CCCDUpload] front + back + [SelfieUpload] along with submitting
/// owner metadata (name, phone, selected plan, total amount held in escrow).
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
  final int totalAmount; // amount already paid (held in escrow)
  final int expectedRooms;

  // ── Timeline ──
  final DateTime submittedAt;
  final VerifyStatus status;

  /// Reason if admin rejected (null if not yet decided).
  final String? rejectReason;
  final List<RejectableItem> rejectedItems;

  /// Name of the admin who handled it (set on approve/reject).
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

  /// Time since submission (used to display "5h ago" / "Overdue 24h").
  Duration get age => DateTime.now().difference(submittedAt);

  /// Whether the 24h SLA has been exceeded.
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
