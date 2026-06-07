import 'package:equatable/equatable.dart';

import 'cccd_upload.dart';
import 'payment_session.dart';
import 'plan.dart';
import 'selfie_upload.dart';
import 'verify_enums.dart';

/// Aggregate state for the entire verify + subscription flow.
///
/// Drafts are saved/loaded via SharedPreferences so the user can resume after
/// closing the app (see [toJson] / [fromJson]).
class VerifyFlowState extends Equatable {
  // KYC
  final CCCDUpload? cccdFront;
  final CCCDUpload? cccdBack;
  final SelfieUpload? selfie;

  /// Number of consecutive face-match failures (lock after 3).
  final int selfieFailAttempts;

  // Property info
  /// Expected room count (drives pricing + tier auto-suggest).
  final int expectedRooms;

  // Subscription
  final Plan? selectedPlan;
  final BillingCycle billingCycle;

  // Payment
  final PaymentSession? paymentSession;
  final PaymentStatus? paymentStatus;

  // Submission
  final String? submissionId;
  final VerifyStatus status;
  final String? rejectReason;
  final List<RejectableItem> rejectedItems;
  final DateTime? approvedAt;
  final DateTime? trialEndsAt;
  final DateTime? chargeStartsAt;

  /// True after refund processed → Screen 8 switches to the confirmation view.
  final bool refundProcessed;
  final int? refundedAmount;

  const VerifyFlowState({
    this.cccdFront,
    this.cccdBack,
    this.selfie,
    this.selfieFailAttempts = 0,
    this.expectedRooms = 5,
    this.selectedPlan,
    this.billingCycle = BillingCycle.yearly,
    this.paymentSession,
    this.paymentStatus,
    this.submissionId,
    this.status = VerifyStatus.draft,
    this.rejectReason,
    this.rejectedItems = const [],
    this.approvedAt,
    this.trialEndsAt,
    this.chargeStartsAt,
    this.refundProcessed = false,
    this.refundedAmount,
  });

  /// Have all 3 uploads (CCCD front + back + selfie) been submitted?
  bool get hasCompleteKyc =>
      cccdFront != null && cccdBack != null && selfie != null;

  /// Step within the KYC capture flow (1 = CCCD front, 2 = CCCD back,
  /// 3 = selfie). KYC and subscription are DECOUPLED — plan + payment are a
  /// separate flow that happens after admin approval, so they are NOT counted
  /// here. The paywall (the only consumer) resumes this 3-step capture only;
  /// it must never offer a non-existent "bước 5".
  int get currentStep {
    if (cccdFront == null) return 1;
    if (cccdBack == null) return 2;
    return 3;
  }

  VerifyFlowState copyWith({
    CCCDUpload? cccdFront,
    CCCDUpload? cccdBack,
    SelfieUpload? selfie,
    int? selfieFailAttempts,
    int? expectedRooms,
    Plan? selectedPlan,
    BillingCycle? billingCycle,
    PaymentSession? paymentSession,
    PaymentStatus? paymentStatus,
    String? submissionId,
    VerifyStatus? status,
    String? rejectReason,
    List<RejectableItem>? rejectedItems,
    DateTime? approvedAt,
    DateTime? trialEndsAt,
    DateTime? chargeStartsAt,
    bool? refundProcessed,
    int? refundedAmount,
    bool clearReject = false,
  }) =>
      VerifyFlowState(
        cccdFront: cccdFront ?? this.cccdFront,
        cccdBack: cccdBack ?? this.cccdBack,
        selfie: selfie ?? this.selfie,
        selfieFailAttempts: selfieFailAttempts ?? this.selfieFailAttempts,
        expectedRooms: expectedRooms ?? this.expectedRooms,
        selectedPlan: selectedPlan ?? this.selectedPlan,
        billingCycle: billingCycle ?? this.billingCycle,
        paymentSession: paymentSession ?? this.paymentSession,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        submissionId: submissionId ?? this.submissionId,
        status: status ?? this.status,
        rejectReason: clearReject ? null : (rejectReason ?? this.rejectReason),
        rejectedItems:
            clearReject ? const [] : (rejectedItems ?? this.rejectedItems),
        approvedAt: approvedAt ?? this.approvedAt,
        trialEndsAt: trialEndsAt ?? this.trialEndsAt,
        chargeStartsAt: chargeStartsAt ?? this.chargeStartsAt,
        refundProcessed: refundProcessed ?? this.refundProcessed,
        refundedAmount: refundedAmount ?? this.refundedAmount,
      );

  Map<String, dynamic> toJson() => {
        'cccdFront': cccdFront?.toJson(),
        'cccdBack': cccdBack?.toJson(),
        'selfie': selfie?.toJson(),
        'selfieFailAttempts': selfieFailAttempts,
        'expectedRooms': expectedRooms,
        'selectedPlan': selectedPlan?.toJson(),
        'billingCycle': billingCycle.name,
        // KHÔNG persist paymentSession/paymentStatus (tiền + phiên). Đây là
        // server state — resume bằng `GET /payments/active`, không cache local.
        'submissionId': submissionId,
        'status': status.name,
        'rejectReason': rejectReason,
        'rejectedItems': rejectedItems.map((e) => e.id).toList(),
        'approvedAt': approvedAt?.toIso8601String(),
        'trialEndsAt': trialEndsAt?.toIso8601String(),
        'chargeStartsAt': chargeStartsAt?.toIso8601String(),
        'refundProcessed': refundProcessed,
        'refundedAmount': refundedAmount,
      };

  factory VerifyFlowState.fromJson(Map<String, dynamic> json) =>
      VerifyFlowState(
        cccdFront: json['cccdFront'] == null
            ? null
            : CCCDUpload.fromJson(json['cccdFront'] as Map<String, dynamic>),
        cccdBack: json['cccdBack'] == null
            ? null
            : CCCDUpload.fromJson(json['cccdBack'] as Map<String, dynamic>),
        selfie: json['selfie'] == null
            ? null
            : SelfieUpload.fromJson(json['selfie'] as Map<String, dynamic>),
        selfieFailAttempts: (json['selfieFailAttempts'] as int?) ?? 0,
        expectedRooms: (json['expectedRooms'] as int?) ?? 5,
        selectedPlan: json['selectedPlan'] == null
            ? null
            : Plan.fromJson(json['selectedPlan'] as Map<String, dynamic>),
        billingCycle: BillingCycle.values.firstWhere(
          (c) => c.name == (json['billingCycle'] as String? ?? 'yearly'),
          orElse: () => BillingCycle.yearly,
        ),
        // paymentSession/paymentStatus KHÔNG khôi phục từ local — luôn lấy lại
        // từ server (`GET /payments/active`) để tránh hiển thị tiền/phiên cũ.
        submissionId: json['submissionId'] as String?,
        status: VerifyStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String? ?? 'draft'),
          orElse: () => VerifyStatus.draft,
        ),
        rejectReason: json['rejectReason'] as String?,
        rejectedItems: (json['rejectedItems'] as List? ?? const [])
            .map((e) => RejectableItemX.fromId(e as String))
            .whereType<RejectableItem>()
            .toList(),
        approvedAt: json['approvedAt'] == null
            ? null
            : DateTime.parse(json['approvedAt'] as String),
        trialEndsAt: json['trialEndsAt'] == null
            ? null
            : DateTime.parse(json['trialEndsAt'] as String),
        chargeStartsAt: json['chargeStartsAt'] == null
            ? null
            : DateTime.parse(json['chargeStartsAt'] as String),
        refundProcessed: (json['refundProcessed'] as bool?) ?? false,
        refundedAmount: json['refundedAmount'] as int?,
      );

  @override
  List<Object?> get props => [
        cccdFront,
        cccdBack,
        selfie,
        selfieFailAttempts,
        expectedRooms,
        selectedPlan,
        billingCycle,
        paymentSession,
        paymentStatus,
        submissionId,
        status,
        rejectReason,
        rejectedItems,
        approvedAt,
        trialEndsAt,
        chargeStartsAt,
        refundProcessed,
        refundedAmount,
      ];
}

/// Thrown when face match score is below threshold.
class FaceMismatchException implements Exception {
  final double score;
  final int attemptNumber;

  /// Remaining attempts (3 - attempts).
  final int remainingAttempts;

  const FaceMismatchException({
    required this.score,
    required this.attemptNumber,
    required this.remainingAttempts,
  });

  @override
  String toString() =>
      'FaceMismatchException(score=$score, attempt=$attemptNumber/3)';
}

/// More than 3 face-match failures → lock 1 hour + escalate to admin.
class FaceMismatchTooManyAttemptsException implements Exception {
  const FaceMismatchTooManyAttemptsException();

  @override
  String toString() => 'FaceMismatchTooManyAttemptsException';
}
