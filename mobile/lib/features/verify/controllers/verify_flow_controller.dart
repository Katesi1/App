import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import '../data/services/iap_service.dart';

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

final paymentHistoryProvider =
    FutureProvider<PaymentHistoryPage>((ref) async {
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
    ref.read(iapServiceProvider),
  ),
);

class VerifyFlowController extends StateNotifier<VerifyFlowState> {
  final VerifyRepository _repo;
  final IAPService _iap;
  static const _draftKey = 'verify_flow_draft_v1';

  VerifyFlowController(this._repo, this._iap) : super(const VerifyFlowState()) {
    _restoreDraft();
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
      final raw = prefs.getString(_draftKey);
      if (raw == null || raw.isEmpty) {
        return;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
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

  /// Create a payment session (opens QR / bank info / card form).
  Future<PaymentSession> initiatePayment(PaymentMethod method) async {
    final plan = state.selectedPlan;
    if (plan == null) {
      throw StateError('Chưa chọn plan');
    }
    final total = PlanPriceCalculator.total(plan, state.billingCycle);
    final session = await _repo.initiatePayment(
      planId: plan.id,
      billingCycle: state.billingCycle,
      method: method,
      rooms: plan.rooms,
      totalAmount: total,
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

  // ════════════════════════════════════════════════════════════
  // Apple In-App Purchase (iOS only — Guideline 3.1.1)
  // ════════════════════════════════════════════════════════════

  /// Fetch products from StoreKit using the IDs in [AppleProductIds.all].
  /// Returns the matched products + any IDs missing from App Store Connect
  /// (helpful during sandbox setup — they show up in `notFoundIDs`).
  Future<ProductDetailsResponse> queryAppleProducts() async {
    if (!await _iap.isAvailable()) {
      throw const VerifyApiException(
        'In-App Purchase chưa sẵn sàng trên thiết bị này.',
      );
    }
    return _iap.queryProducts(AppleProductIds.all);
  }

  /// Start an Apple IAP purchase for the currently-selected plan + cycle.
  /// Returns when StoreKit accepts the request (the purchase outcome arrives
  /// asynchronously via [listenAppleStoreKit]). Throws if no plan is selected
  /// or the product isn't available in App Store Connect.
  ///
  /// Sets `state.applePurchasePending` so the UI can disable the CTA + show
  /// a spinner; the stream handler clears it on success/error/cancel.
  Future<void> buyApplePlanForSelection() async {
    final plan = state.selectedPlan;
    if (plan == null) {
      throw StateError('Chưa chọn plan');
    }
    final productId = AppleProductIds.forPlan(plan.tier, state.billingCycle);
    if (productId == null) {
      throw const VerifyApiException(
        'Gói Enterprise không hỗ trợ thanh toán trong app — vui lòng liên hệ.',
      );
    }
    final response = await _iap.queryProducts({productId});
    if (response.productDetails.isEmpty) {
      throw VerifyApiException(
        'Không tìm thấy sản phẩm "$productId" trên App Store Connect.',
      );
    }
    state =
        state.copyWith(applePurchasePending: true, clearAppleError: true);
    await _iap.buySubscription(response.productDetails.first);
  }

  /// Trigger "Restore Purchases" (required by Apple). The restored entries
  /// arrive via [listenAppleStoreKit] just like a fresh purchase.
  Future<void> restoreApplePurchases() {
    state =
        state.copyWith(applePurchasePending: true, clearAppleError: true);
    return _iap.restorePurchases();
  }

  /// Clear `applePurchaseError` after the UI has displayed it. Called from
  /// the snackbar `onVisible` so consecutive errors retrigger the snackbar.
  void clearAppleError() {
    if (state.applePurchaseError == null) return;
    state = state.copyWith(clearAppleError: true);
  }

  /// Subscribe to StoreKit's purchase stream. Call once at app start or from
  /// the payment screen `initState`. Returns the subscription so the caller
  /// can cancel it.
  ///
  /// For each delivered purchase:
  ///  - `pendingCompletePurchase == true` → send the receipt to backend; on
  ///    backend success, mark as approved + complete the StoreKit transaction
  ///  - on error → surface to UI; DO NOT complete (StoreKit will redeliver)
  ///  - cancelled by user → no-op
  StreamSubscription<List<PurchaseDetails>> listenAppleStoreKit({
    void Function(String message)? onError,
    void Function()? onSuccess,
  }) {
    return _iap.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases) {
          switch (purchase.status) {
            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              try {
                final result = await _repo.verifyAppleReceipt(
                  productId: purchase.productID,
                  purchaseId: purchase.purchaseID ?? '',
                  receiptData:
                      purchase.verificationData.serverVerificationData,
                );
                // `paymentStatus = paid` so any code mirroring the VNPay flow
                // (e.g. polling UIs) sees the same state for Apple purchases.
                state = state.copyWith(
                  status: result.status,
                  trialEndsAt: result.expiresAt,
                  paymentStatus: PaymentStatus.paid,
                  applePurchasePending: false,
                  clearAppleError: true,
                );
                _persistDraft();
                if (purchase.pendingCompletePurchase) {
                  await _iap.completePurchase(purchase);
                }
                onSuccess?.call();
              } catch (e) {
                final msg = e.toString().replaceAll('Exception: ', '');
                state = state.copyWith(
                  applePurchasePending: false,
                  applePurchaseError: msg,
                );
                onError?.call(msg);
              }
              break;
            case PurchaseStatus.error:
              final msg =
                  purchase.error?.message ?? 'Thanh toán Apple thất bại.';
              state = state.copyWith(
                applePurchasePending: false,
                applePurchaseError: msg,
              );
              if (purchase.pendingCompletePurchase) {
                await _iap.completePurchase(purchase);
              }
              onError?.call(msg);
              break;
            case PurchaseStatus.canceled:
              state = state.copyWith(
                applePurchasePending: false,
                clearAppleError: true,
              );
              if (purchase.pendingCompletePurchase) {
                await _iap.completePurchase(purchase);
              }
              break;
            case PurchaseStatus.pending:
              // Waiting on Apple — no UI change yet (CTA stays disabled).
              break;
          }
        }
      },
    );
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

  /// Persist draft to local storage so the flow can resume after app restart.
  void _persistDraft() {
    SharedPreferences.getInstance().then((prefs) {
      final payload = jsonEncode(state.toJson());
      prefs.setString(_draftKey, payload);
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
