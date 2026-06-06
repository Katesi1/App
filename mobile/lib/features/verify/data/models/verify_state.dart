import 'package:equatable/equatable.dart';

import 'cccd_upload.dart';
import 'payment_quote.dart';
import 'payment_session.dart';
import 'plan.dart';
import 'selfie_upload.dart';
import 'verify_enums.dart';

/// State tổng cho toàn flow verify + subscription.
///
/// Lưu/load draft từ SharedPreferences để resume nếu user close app
/// (xem [toJson] / [fromJson]).
class VerifyFlowState extends Equatable {
  // ── KYC ──
  final CCCDUpload? cccdFront;
  final CCCDUpload? cccdBack;
  final SelfieUpload? selfie;

  /// Số lần fail face match liên tiếp (lock sau 3 lần).
  final int selfieFailAttempts;

  // ── Property info ──
  /// Số phòng dự kiến (driver tính giá + auto-suggest tier).
  final int expectedRooms;

  // ── Subscription ──
  final Plan? selectedPlan;
  final BillingCycle billingCycle;

  // ── Payment ──
  final PaymentQuote? paymentQuote;
  final PaymentSession? paymentSession;
  final PaymentStatus? paymentStatus;

  // ── Submission ──
  final String? submissionId;
  final VerifyStatus status;
  final String? rejectReason;
  final List<RejectableItem> rejectedItems;
  final DateTime? approvedAt;
  final DateTime? trialEndsAt;
  final DateTime? chargeStartsAt;

  /// Có refund đã processed → Screen 8 chuyển sang confirmation.
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
    this.paymentQuote,
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

  /// Đã upload đủ 3 ảnh CCCD front + back + selfie chưa.
  bool get hasCompleteKyc =>
      cccdFront != null && cccdBack != null && selfie != null;

  /// Step KYC (1–4): CCCD trước → sau → selfie → submit.
  int get kycCurrentStep {
    if (cccdFront == null) return 1;
    if (cccdBack == null) return 2;
    if (selfie == null) return 3;
    return 4;
  }

  /// Step mua gói (1–2): chọn plan → thanh toán.
  int get subscriptionCurrentStep {
    if (selectedPlan == null) return 1;
    return 2;
  }

  /// Resume paywall / property CTA — chỉ KYC, không gộp subscription.
  int get currentStep => kycCurrentStep;

  VerifyFlowState copyWith({
    CCCDUpload? cccdFront,
    CCCDUpload? cccdBack,
    SelfieUpload? selfie,
    int? selfieFailAttempts,
    int? expectedRooms,
    Plan? selectedPlan,
    BillingCycle? billingCycle,
    PaymentQuote? paymentQuote,
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
    bool clearPaymentSession = false,
    bool clearPaymentQuote = false,
  }) =>
      VerifyFlowState(
        cccdFront: cccdFront ?? this.cccdFront,
        cccdBack: cccdBack ?? this.cccdBack,
        selfie: selfie ?? this.selfie,
        selfieFailAttempts: selfieFailAttempts ?? this.selfieFailAttempts,
        expectedRooms: expectedRooms ?? this.expectedRooms,
        selectedPlan: selectedPlan ?? this.selectedPlan,
        billingCycle: billingCycle ?? this.billingCycle,
        paymentQuote:
            clearPaymentQuote ? null : (paymentQuote ?? this.paymentQuote),
        paymentSession: clearPaymentSession
            ? null
            : (paymentSession ?? this.paymentSession),
        paymentStatus:
            clearPaymentSession ? null : (paymentStatus ?? this.paymentStatus),
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
        'paymentQuote': null,
        // paymentSession / paymentStatus: runtime cache từ API — không persist.
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
        // Không restore payment từ draft — luôn hydrate qua GET /payments/active.
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
        paymentQuote,
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

/// Custom exception khi face match score < threshold.
class FaceMismatchException implements Exception {
  final double score;
  final int attemptNumber;

  /// Còn được thử bao nhiêu lần nữa (3 - attempts).
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

/// Quá 3 lần fail face match → lock 1 giờ + escalate admin.
class FaceMismatchTooManyAttemptsException implements Exception {
  const FaceMismatchTooManyAttemptsException();

  @override
  String toString() => 'FaceMismatchTooManyAttemptsException';
}
