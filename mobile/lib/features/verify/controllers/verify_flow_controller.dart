import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/models/cccd_upload.dart';
import '../data/models/ocr_result.dart';
import '../data/models/payment_history_item.dart';
import '../data/models/payment_session.dart';
import '../data/models/plan.dart';
import '../data/models/selfie_upload.dart';
import '../data/models/verify_enums.dart';
import '../data/models/verify_state.dart';
import '../data/repositories/verify_repository.dart';
import '../data/repositories/verify_repository_impl.dart';

final verifyRepositoryProvider = Provider<VerifyRepository>(
  (ref) => VerifyRepositoryImpl(),
);

final verifyPlansProvider = FutureProvider<List<Plan>>((ref) async {
  // Fall back to bundled defaults if backend `/billing/plans` is unreachable
  // OR returns an empty list — otherwise the select-plan screen crashes with
  // "Bad state: No element" when `planFor()` doesn't find the picked tier.
  try {
    final plans = await ref.read(verifyRepositoryProvider).fetchPlans();
    return plans.isEmpty ? kDefaultPlans : plans;
  } catch (_) {
    return kDefaultPlans;
  }
});

final paymentHistoryProvider = FutureProvider<PaymentHistoryPage>((ref) async {
  return ref.read(verifyRepositoryProvider).fetchPaymentHistory();
});

class PaymentHistoryListState {
  final List<PaymentHistoryItem> items;
  final String? nextCursor;
  final bool isLoadingFirstPage;
  final bool isLoadingMore;
  final String? error;

  const PaymentHistoryListState({
    this.items = const [],
    this.nextCursor,
    this.isLoadingFirstPage = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  PaymentHistoryListState copyWith({
    List<PaymentHistoryItem>? items,
    String? nextCursor,
    bool? isLoadingFirstPage,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    bool clearNextCursor = false,
  }) =>
      PaymentHistoryListState(
        items: items ?? this.items,
        nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
        isLoadingFirstPage: isLoadingFirstPage ?? this.isLoadingFirstPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : (error ?? this.error),
      );
}

class PaymentHistoryNotifier extends StateNotifier<PaymentHistoryListState> {
  PaymentHistoryNotifier(this._repo) : super(const PaymentHistoryListState()) {
    refresh();
  }

  final VerifyRepository _repo;
  static const _pageSize = 20;

  Future<void> refresh() async {
    state = state.copyWith(
      isLoadingFirstPage: true,
      clearError: true,
      items: const [],
      clearNextCursor: true,
    );
    try {
      final page = await _repo.fetchPaymentHistory(limit: _pageSize);
      state = state.copyWith(
        items: page.items,
        nextCursor: page.nextCursor,
        isLoadingFirstPage: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFirstPage: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final page = await _repo.fetchPaymentHistory(
        limit: _pageSize,
        cursor: state.nextCursor,
      );
      state = state.copyWith(
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        isLoadingMore: false,
        clearNextCursor: page.nextCursor == null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final paymentHistoryListProvider = StateNotifierProvider.autoDispose<
    PaymentHistoryNotifier, PaymentHistoryListState>((ref) {
  return PaymentHistoryNotifier(ref.read(verifyRepositoryProvider));
});

/// Controller for the entire verify + subscription flow.
///
/// State is persisted via [_persistDraft] — if the user closes the app
/// mid-flow, the next launch resumes from the last step.
final verifyFlowControllerProvider =
    StateNotifierProvider<VerifyFlowController, VerifyFlowState>(
  (ref) => VerifyFlowController(
    ref.read(verifyRepositoryProvider),
    ref,
  ),
);

class VerifyFlowController extends StateNotifier<VerifyFlowState> {
  final VerifyRepository _repo;
  final Ref _ref;

  VerifyFlowController(this._repo, this._ref) : super(const VerifyFlowState()) {
    _restoreDraft();
    // Security: wipe the in-progress draft whenever the signed-in account
    // changes (logout → null, or switch user) so one user's selected plan /
    // KYC images never carry over into another account's session.
    _ref.listen<String?>(
      currentUserProvider.select((u) => u?.id),
      (prev, next) {
        if (prev != null && next != prev) {
          clearDraft();
        }
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // Hydrate — load state from backend when re-entering the flow
  // ════════════════════════════════════════════════════════════

  /// Sync KYC state with backend (`GET /kyc/status`).
  ///
  /// Call when the user re-opens the app or enters the paywall modal so the
  /// flow resumes at the right step instead of always restarting from CCCD
  /// front. Idempotent — safe to call repeatedly.
  Future<void> hydrate() async {
    try {
      final snap = await _repo.getKycStatus();
      state = state.copyWith(
        status: snap.status,
        submissionId: snap.submissionId,
        rejectReason: snap.rejectReason,
        rejectedItems: snap.rejectedItems,
        approvedAt: snap.approvedAt,
        trialEndsAt: snap.trialEndsAt,
      );
    } catch (_) {
      // Hydrate failure should not crash the flow — user can still restart.
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.verifyDraftKey);
      if (raw == null || raw.isEmpty) {
        return;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // Security: only resume a draft that belongs to the current account.
      // Guards the edge case where the previous user didn't log out cleanly
      // (app killed) before this user signed in — never restore their plan.
      final draftUserId = json['ownerUserId'] as String?;
      final currentUserId = _ref.read(currentUserProvider)?.id;
      if (draftUserId != null &&
          currentUserId != null &&
          draftUserId != currentUserId) {
        await prefs.remove(AppConstants.verifyDraftKey);
        return;
      }
      state = VerifyFlowState.fromJson(json);
    } catch (_) {
      // Don't block the flow if parsing the old draft fails.
    }
  }

  // ════════════════════════════════════════════════════════════
  // KYC — Step 1, 2, 3
  // ════════════════════════════════════════════════════════════

  /// Step 1: Upload the front of the CCCD.
  ///
  /// `ocrResult` is data already extracted on-device (see [CCCDScannerScreen]).
  /// May be null if the user picks the image from the gallery.
  Future<CCCDUpload> uploadCCCDFront(
    File image, {
    OCRResult? ocrResult,
  }) async {
    final result = await _repo.uploadCCCDFront(image, ocrResult: ocrResult);
    state = state.copyWith(cccdFront: result, status: VerifyStatus.draft);
    _persistDraft();
    return result;
  }

  /// Step 2: Upload the back of the CCCD.
  ///
  /// `ocrResult` comes from the QR code on the back (100% accurate on newer
  /// chipped CCCDs).
  Future<CCCDUpload> uploadCCCDBack(
    File image, {
    OCRResult? ocrResult,
  }) async {
    final result = await _repo.uploadCCCDBack(image, ocrResult: ocrResult);
    // Merge front (OCR text) + back (QR machine-readable). Any field the QR
    // provides → prefer QR since it's more accurate (see `OCRResult.mergeWith`).
    final merged = state.cccdFront?.copyWith(
      ocrResult: state.cccdFront?.ocrResult?.mergeWith(result.ocrResult),
    );
    state = state.copyWith(cccdBack: result, cccdFront: merged);
    _persistDraft();
    return result;
  }

  /// Step 3: Upload selfie.
  ///
  /// **Do NOT auto-reject based on `faceMatchScore`**. Reasons:
  /// - Backend hasn't wired FPT.AI yet → score is always `null/0` → false reject
  /// - Scores 0.7-0.85 often hit real users due to lighting/angle/glasses → a
  ///   hard client cutoff would block legitimate customers
  /// - Admin sees CCCD + selfie + score together in the queue and makes the
  ///   final call (see [KYCApprovalDetailScreen])
  ///
  /// `faceMatchScore` and `isValid` from backend are only **display hints for
  /// admin** in the queue, not a client-side gate.
  Future<SelfieUpload> uploadSelfie(File image) async {
    final cccdFront = state.cccdFront;
    if (cccdFront == null) {
      throw StateError('Phải upload CCCD trước khi chụp selfie');
    }

    final result = await _repo.uploadSelfie(image, cccdFrontId: cccdFront.id);

    state = state.copyWith(
      selfie: result,
      selfieFailAttempts: 0,
      status: VerifyStatus.kycSubmitted,
    );
    _persistDraft();
    return result;
  }

  // ════════════════════════════════════════════════════════════
  // Subscription — Step 4
  // ════════════════════════════════════════════════════════════
  // `expectedRooms` is derived from `plan.rooms` in `selectPlan()` — the user
  // no longer enters the room count manually (new tier-based model with fixed
  // rooms per tier).

  /// Pick plan + cycle. `expectedRooms` auto-derives from `plan.rooms` (kept
  /// in state for payment + admin queue). Enterprise: rooms = -1 → keep the
  /// existing value (do not override).
  void selectPlan(Plan plan, BillingCycle cycle) {
    state = state.copyWith(
      selectedPlan: plan,
      billingCycle: cycle,
      expectedRooms: plan.rooms > 0 ? plan.rooms : state.expectedRooms,
    );
    _persistDraft();
  }

  void setBillingCycle(BillingCycle cycle) {
    state = state.copyWith(billingCycle: cycle);
    _persistDraft();
  }

  // ════════════════════════════════════════════════════════════
  // Payment — Step 6
  // ════════════════════════════════════════════════════════════

  /// Báo giá trước khi mở màn thanh toán (`POST /payments/quote`). BE là source
  /// of truth cho số tiền + loại giao dịch (subscription/renew/upgrade/downgrade).
  Future<PaymentQuote> getQuote() async {
    final plan = state.selectedPlan;
    if (plan == null) {
      throw StateError('Chưa chọn plan');
    }
    return _repo.getQuote(
      planId: plan.id,
      billingCycle: state.billingCycle,
      rooms: plan.rooms,
    );
  }

  /// Báo giá cho 1 plan + cycle bất kỳ (không đụng state) — dùng ở màn chọn gói
  /// để hiển thị đúng số tiền BE chốt khi user đổi plan/cycle.
  Future<PaymentQuote> getQuoteFor(Plan plan, BillingCycle cycle) {
    return _repo.getQuote(
      planId: plan.id,
      billingCycle: cycle,
      rooms: plan.rooms,
    );
  }

  /// Create a payment session (opens QR / bank info / card form).
  ///
  /// `totalAmount` **bắt buộc** đến từ quote (`POST /payments/quote`) — BE là
  /// source of truth. KHÔNG bao giờ tự tính local (liên quan tiền thật của chủ
  /// nhà; BE validate ±1% và sẽ 400 `amountMismatch` nếu sai).
  Future<PaymentSession> initiatePayment(
    PaymentMethod method, {
    required int totalAmount,
  }) async {
    final plan = state.selectedPlan;
    if (plan == null) {
      throw StateError('Chưa chọn plan');
    }
    final session = await _repo.initiatePayment(
      planId: plan.id,
      billingCycle: state.billingCycle,
      method: method,
      rooms: plan.rooms,
      totalAmount: totalAmount,
    );
    state = state.copyWith(
      paymentSession: session,
      paymentStatus: PaymentStatus.pending,
      status: VerifyStatus.paymentPending,
    );
    _persistDraft();
    return session;
  }

  /// Create a subscription renewal payment session. Backend uses the user's
  /// current plan + cycle; the app only sends the method.
  Future<PaymentSession> initiateRenewal(PaymentMethod method) async {
    final session = await _repo.renewSubscription(method: method);
    state = state.copyWith(
      paymentSession: session,
      paymentStatus: PaymentStatus.pending,
    );
    _persistDraft();
    return session;
  }

  /// Lấy phiên đang chờ đầy đủ (qrCode/bankInfo) để resume QR — dùng khi BE trả
  /// 409 `paymentPending`. Lưu vào state để màn QR + polling dùng lại.
  Future<PaymentSession?> getActivePayment() async {
    final session = await _repo.getActivePayment();
    if (session != null) {
      state = state.copyWith(
        paymentSession: session,
        paymentStatus: PaymentStatus.pending,
      );
      _persistDraft();
    }
    return session;
  }

  /// Cancel an open bank-transfer session — voids the pending bill on the
  /// backend so it's no longer reconciled. Clears the local payment state.
  Future<void> cancelPayment(String sessionId) async {
    await _repo.cancelPayment(sessionId);
    state = state.copyWith(paymentStatus: PaymentStatus.failed);
    _persistDraft();
  }

  /// Poll payment status (Screen 5 calls every 3s).
  ///
  /// Once paid → auto-submit the application for admin review.
  Future<PaymentStatus> checkPaymentStatus() async {
    final session = state.paymentSession;
    if (session == null) return PaymentStatus.pending;

    final status = await _repo.checkPaymentStatus(session.sessionId);
    state = state.copyWith(paymentStatus: status);

    // Auto-submit KYC after payment ONLY if KYC isn't already in/past the
    // approval queue. KYC and purchase are decoupled flows — if the user
    // already submitted (and admin already approved), buying a plan must
    // NOT re-trigger submission.
    final alreadyHandled = const {
      VerifyStatus.awaitingApproval,
      VerifyStatus.approved,
    }.contains(state.status);
    if (status == PaymentStatus.paid && !alreadyHandled) {
      await submitForApproval();
    }
    _persistDraft();
    return status;
  }

  /// Re-sync the signed-in user's profile from backend so a freshly-activated
  /// subscription (admin marked the bank transfer as paid) is reflected in
  /// `currentUserProvider` — drives the dashboard banner + route guards.
  /// Best-effort: a failure here never breaks the payment flow.
  Future<void> refreshUserProfile() async {
    try {
      await _ref.read(authProvider.notifier).refreshProfile();
    } catch (_) {
      // Ignore — app-resume + pull-to-refresh will re-sync later.
    }
  }

  // ════════════════════════════════════════════════════════════
  // Submission + Approval — Step 7
  // ════════════════════════════════════════════════════════════

  Future<void> submitForApproval() async {
    final result = await _repo.submitForApproval();
    state = state.copyWith(
      submissionId: result.submissionId,
      status: VerifyStatus.awaitingApproval,
    );
    _persistDraft();
  }

  /// Polling provider (Screen 6 calls every 30s).
  Future<VerifyStatus> checkApprovalStatus() async {
    final id = state.submissionId;
    if (id == null) return state.status;

    final result = await _repo.checkApprovalStatus(id);
    state = state.copyWith(
      status: result.status,
      approvedAt: result.approvedAt,
      trialEndsAt: result.trialEndsAt,
      chargeStartsAt: result.chargeStartsAt,
      rejectReason: result.rejectReason,
      rejectedItems: result.rejectedItems,
    );
    _persistDraft();
    return result.status;
  }

  // ════════════════════════════════════════════════════════════
  // Resubmit + Refund (after rejection)
  // ════════════════════════════════════════════════════════════

  /// After the user re-uploads all rejected items → submit again for admin review.
  Future<void> resubmit() async {
    await _repo.resubmit(items: state.rejectedItems);
    state = state.copyWith(
      status: VerifyStatus.awaitingApproval,
      clearReject: true,
    );
    _persistDraft();
  }

  Future<void> requestRefund() async {
    final id = state.submissionId;
    if (id == null) {
      throw StateError('Chưa có submission để refund');
    }
    final result = await _repo.requestRefund(id);
    state = state.copyWith(
      status: VerifyStatus.refunded,
      refundProcessed: true,
      refundedAmount: result.refundAmount,
    );
    _persistDraft();
  }

  // ════════════════════════════════════════════════════════════
  // Dev helpers
  // ════════════════════════════════════════════════════════════

  /// Reset the entire flow to the initial state (for debug + after refund).
  void resetFlow() {
    state = const VerifyFlowState();
    _persistDraft();
  }

  /// Wipe the in-progress draft from memory AND disk. Called on logout /
  /// account switch so a selected plan or KYC images never carry over to
  /// another user. Unlike [resetFlow] this removes the key entirely.
  Future<void> clearDraft() async {
    state = const VerifyFlowState();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.verifyDraftKey);
    } catch (_) {
      // Best-effort: in-memory state is already cleared above.
    }
  }

  /// Persist draft to local storage so the flow can resume after app restart.
  /// Stamped with the owner's user id so a draft is never restored into a
  /// different account (see [_restoreDraft]).
  void _persistDraft() {
    final ownerUserId = _ref.read(currentUserProvider)?.id;
    SharedPreferences.getInstance().then((prefs) {
      final payload = jsonEncode({
        ...state.toJson(),
        'ownerUserId': ownerUserId,
      });
      prefs.setString(AppConstants.verifyDraftKey, payload);
    });
  }
}

/// Convenience provider: lists KYC items for the checklist on the Rejected
/// screen (each item is approved/rejected/notSubmitted).
final kycItemsStatusProvider = Provider<List<KycItemStatus>>((ref) {
  final s = ref.watch(verifyFlowControllerProvider);
  return RejectableItem.values.map((item) {
    final isRejected = s.rejectedItems.contains(item);
    final hasUpload = switch (item) {
      RejectableItem.cccdFront => s.cccdFront != null,
      RejectableItem.cccdBack => s.cccdBack != null,
      RejectableItem.selfie => s.selfie != null,
    };
    return KycItemStatus(
      item: item,
      isRejected: isRejected,
      isApproved: hasUpload && !isRejected,
    );
  }).toList();
});

class KycItemStatus {
  final RejectableItem item;
  final bool isRejected;
  final bool isApproved;

  const KycItemStatus({
    required this.item,
    required this.isRejected,
    required this.isApproved,
  });
}
