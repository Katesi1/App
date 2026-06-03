import 'dart:io';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final verifyRepositoryProvider = Provider<VerifyRepository>(
  (ref) => VerifyRepositoryImpl(),
);

final verifyPlansProvider = FutureProvider<List<Plan>>((ref) async {
  return ref.read(verifyRepositoryProvider).fetchPlans();
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

/// Controller cho toàn flow verify + subscription.
///
/// State được persist qua [_persistDraft] — khi user close app giữa flow,
/// next launch sẽ resume từ step cuối. (Mock: log only — chưa wire
/// SharedPreferences vì spec yêu cầu chỉ làm design + logic.)
final verifyFlowControllerProvider =
    StateNotifierProvider<VerifyFlowController, VerifyFlowState>(
  (ref) => VerifyFlowController(ref.read(verifyRepositoryProvider)),
);

class VerifyFlowController extends StateNotifier<VerifyFlowState> {
  final VerifyRepository _repo;
  static const _draftKey = 'verify_flow_draft_v1';

  VerifyFlowController(this._repo) : super(const VerifyFlowState()) {
    _restoreDraft();
  }

  // ════════════════════════════════════════════════════════════
  // Hydrate — load state từ backend khi vào lại flow
  // ════════════════════════════════════════════════════════════

  /// Đồng bộ trạng thái KYC với backend (`GET /kyc/status`).
  ///
  /// Gọi khi user mở app lại / vào paywall modal — để resume đúng step
  /// thay vì luôn bắt đầu từ CCCD trước. Idempotent, an toàn để gọi nhiều lần.
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
      // Hydrate fail không nên crash flow — user vẫn có thể start lại từ đầu.
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
      // Không block flow nếu parse lỗi draft cũ.
    }
  }

  // ════════════════════════════════════════════════════════════
  // KYC — Step 1, 2, 3
  // ════════════════════════════════════════════════════════════

  /// Step 1: Upload CCCD mặt trước.
  ///
  /// `ocrResult` là dữ liệu đã extract trên device (xem [CCCDScannerScreen]).
  /// Có thể null nếu user chọn ảnh từ gallery.
  Future<CCCDUpload> uploadCCCDFront(
    File image, {
    OCRResult? ocrResult,
  }) async {
    final result = await _repo.uploadCCCDFront(image, ocrResult: ocrResult);
    state = state.copyWith(cccdFront: result, status: VerifyStatus.draft);
    _persistDraft();
    return result;
  }

  /// Step 2: Upload CCCD mặt sau.
  ///
  /// `ocrResult` từ QR code mặt sau (chính xác 100% nếu CCCD chip mới).
  Future<CCCDUpload> uploadCCCDBack(
    File image, {
    OCRResult? ocrResult,
  }) async {
    final result = await _repo.uploadCCCDBack(image, ocrResult: ocrResult);
    // Merge data trước (OCR text) + sau (QR machine-readable). Field nào QR
    // có → ưu tiên QR vì chính xác hơn (xem `OCRResult.mergeWith`).
    final merged = state.cccdFront?.copyWith(
      ocrResult: state.cccdFront?.ocrResult?.mergeWith(result.ocrResult),
    );
    state = state.copyWith(cccdBack: result, cccdFront: merged);
    _persistDraft();
    return result;
  }

  /// Step 3: Upload selfie.
  ///
  /// **Không auto-reject theo `faceMatchScore`**. Lý do:
  /// - Backend chưa wire FPT.AI → score luôn `null/0` → reject nhầm
  /// - Score 0.7-0.85 hay rơi vào user thật do ánh sáng/góc/kính → hard
  ///   cutoff ở client = chặn nhầm khách hàng
  /// - Admin nhìn cả CCCD + selfie + score trong queue → quyết định cuối
  ///   cùng (xem [KYCApprovalDetailScreen])
  ///
  /// `faceMatchScore` và `isValid` từ backend chỉ là **hint hiển thị cho
  /// admin** trong queue, không phải gate ở client.
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
  // `expectedRooms` derive từ `plan.rooms` trong `selectPlan()` —
  // user không tự nhập số phòng nữa (model mới: tier-based, mỗi tier ứng
  // số phòng cố định).

  /// Pick plan + cycle. `expectedRooms` auto-derive từ `plan.rooms` (giữ
  /// trong state cho payment + admin queue). Enterprise: rooms = -1 → giữ
  /// nguyên giá trị cũ (không override).
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

  /// Tạo payment session (mở QR / bank info / card form).
  ///
  /// Backend yêu cầu KYC submission phải tồn tại trước khi tạo payment
  /// (`POST /kyc/submit` trước `POST /payments/initiate`). Nếu chưa có
  /// [submissionId], tự động submit KYC để lấy ID, sau đó tạo payment.
  Future<PaymentSession> initiatePayment(PaymentMethod method) async {
    final plan = state.selectedPlan;
    if (plan == null) {
      throw StateError('Chưa chọn plan');
    }

    if (state.submissionId == null) {
      try {
        final result = await _repo.submitForApproval();
        state = state.copyWith(submissionId: result.submissionId);
        _persistDraft();
      } catch (_) {
        // Có thể đã submit trước đó (409) — lấy submissionId từ /kyc/status.
        try {
          final snap = await _repo.getKycStatus();
          if (snap.submissionId != null) {
            state = state.copyWith(submissionId: snap.submissionId);
            _persistDraft();
          }
        } catch (_) {}
      }
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

  /// Tạo phiên gia hạn subscription (renew). Backend dùng plan + cycle
  /// hiện tại của user, app chỉ cần gửi method.
  Future<PaymentSession> initiateRenewal(PaymentMethod method) async {
    final session = await _repo.renewSubscription(method: method);
    state = state.copyWith(
      paymentSession: session,
      paymentStatus: PaymentStatus.pending,
    );
    _persistDraft();
    return session;
  }

  /// Poll trạng thái payment (màn thanh toán gọi mỗi 3s).
  Future<PaymentStatus> checkPaymentStatus() async {
    final session = state.paymentSession;
    if (session == null) return PaymentStatus.pending;

    final status = await _repo.checkPaymentStatus(session.sessionId);
    state = state.copyWith(paymentStatus: status);
    _persistDraft();
    return status;
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

  /// Polling provider (Screen 6 gọi mỗi 30s).
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
  // Resubmit + Refund (sau khi reject)
  // ════════════════════════════════════════════════════════════

  /// Sau khi user re-upload hết các item bị reject → submit lại để admin duyệt.
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

  /// Reset toàn flow về state ban đầu (dùng cho debug + sau khi refund).
  void resetFlow() {
    state = const VerifyFlowState();
    _persistDraft();
  }

  /// Persist draft xuống local storage để resume flow sau khi app restart.
  void _persistDraft() {
    SharedPreferences.getInstance().then((prefs) {
      final payload = jsonEncode(state.toJson());
      prefs.setString(_draftKey, payload);
    }).catchError((_) {});
  }
}

/// Convenience provider: liệt kê các item KYC để hiển thị checklist trên
/// Rejected screen (mỗi item có status approved/rejected/notSubmitted).
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
