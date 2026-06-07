import 'dart:io';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/cccd_upload.dart';
import '../data/models/ocr_result.dart';
import '../data/models/payment_history_item.dart';
import '../data/models/payment_quote.dart';
import '../data/models/payment_session.dart';
import '../data/models/plan.dart';
import '../data/models/selfie_upload.dart';
import '../data/models/verify_enums.dart';
import '../data/models/verify_state.dart';
import '../data/repositories/verify_repository.dart';
import '../data/repositories/verify_repository_impl.dart';

export '../data/repositories/verify_repository.dart' show VerifyApiException;

final verifyRepositoryProvider = Provider<VerifyRepository>(
  (ref) => VerifyRepositoryImpl(),
);

final verifyPlansProvider = FutureProvider<List<Plan>>((ref) async {
  return ref.read(verifyRepositoryProvider).fetchPlans();
});

/// Params cho `POST /payments/quote` — auto-refetch khi đổi plan/cycle.
typedef PaymentQuoteParams = ({String planId, BillingCycle cycle, int rooms});

final paymentQuoteProvider = FutureProvider.autoDispose
    .family<PaymentQuote, PaymentQuoteParams>((ref, params) async {
  final repo = ref.read(verifyRepositoryProvider);

  Plan? catalogPlan;
  try {
    final plans = await ref.read(verifyPlansProvider.future);
    catalogPlan = plans.where((p) => p.id == params.planId).firstOrNull;
  } catch (_) {}

  try {
    return await repo.fetchPaymentQuote(
      planId: params.planId,
      billingCycle: params.cycle,
      rooms: params.rooms,
    );
  } on VerifyApiException catch (e) {
    if (e.isSubscriptionFrozen) rethrow;
    if (catalogPlan != null && catalogPlan.hasFixedPrice) {
      return PaymentQuote.fromCatalog(catalogPlan, params.cycle);
    }
    rethrow;
  } catch (_) {
    if (catalogPlan != null && catalogPlan.hasFixedPrice) {
      return PaymentQuote.fromCatalog(catalogPlan, params.cycle);
    }
    throw const VerifyApiException(
      'Không tải được báo giá. Kiểm tra kết nối và thử lại.',
    );
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

  /// Đồng bộ trạng thái KYC + payment pending từ backend.
  ///
  /// Payment pending: source of truth là `GET /payments/active`, không đọc draft.
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
      await syncActivePaymentFromApi();
      _persistDraft();
    } catch (_) {
      // Hydrate fail không nên crash flow — user vẫn có thể start lại từ đầu.
    }
  }

  /// `GET /payments/active` — source of truth cho phiên pending (QR + bankInfo).
  ///
  /// Cập nhật runtime cache trong state; trả `null` nếu BE không có session pending.
  Future<PaymentSession?> syncActivePaymentFromApi() async {
    try {
      final active = await _repo.fetchActivePaymentSession();
      if (active == null || !DateTime.now().isBefore(active.expiresAt)) {
        state = state.copyWith(clearPaymentSession: true);
        return null;
      }
      state = state.copyWith(
        paymentSession: active,
        paymentStatus: PaymentStatus.pending,
        status: VerifyStatus.paymentPending,
      );
      return active;
    } on VerifyApiException {
      rethrow;
    } catch (_) {
      state = state.copyWith(clearPaymentSession: true);
      return null;
    }
  }

  /// Xoá runtime cache payment (sau khi BE confirm paid/expired/cancel).
  void clearPaymentSessionCache() {
    state = state.copyWith(clearPaymentSession: true);
  }

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null || raw.isEmpty) {
        return;
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      state = VerifyFlowState.fromJson(json).copyWith(
        clearPaymentSession: true,
      );
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
  void selectPlan(Plan plan, BillingCycle cycle, {PaymentQuote? quote}) {
    final planChanged =
        state.selectedPlan?.id != plan.id || state.billingCycle != cycle;
    state = state.copyWith(
      selectedPlan: plan,
      billingCycle: cycle,
      paymentQuote: quote,
      expectedRooms: plan.rooms > 0 ? plan.rooms : state.expectedRooms,
      clearPaymentQuote: quote == null,
      clearPaymentSession: planChanged,
    );
    _persistDraft();
  }

  void setPaymentQuote(PaymentQuote quote) {
    state = state.copyWith(paymentQuote: quote);
    _persistDraft();
  }

  void setBillingCycle(BillingCycle cycle) {
    state = state.copyWith(billingCycle: cycle);
    _persistDraft();
  }

  // ════════════════════════════════════════════════════════════
  // Payment — Step 6
  // ════════════════════════════════════════════════════════════

  int _quoteRooms(Plan plan) => plan.rooms > 0 ? plan.rooms : 1;

  /// Luôn lấy báo giá mới từ BE trước khi thanh toán — không dùng catalog
  /// fallback (`isCatalogFallback`) để gửi `totalAmount`.
  Future<PaymentQuote> ensureFreshQuote() async {
    final plan = state.selectedPlan;
    if (plan == null) {
      throw const VerifyApiException('Chưa chọn gói thanh toán.');
    }
    final quote = await _repo.fetchPaymentQuote(
      planId: plan.id,
      billingCycle: state.billingCycle,
      rooms: _quoteRooms(plan),
    );
    state = state.copyWith(paymentQuote: quote);
    _persistDraft();
    return quote;
  }

  Future<PaymentSession> _createPaymentSession(
    PaymentMethod method,
    PaymentQuote quote,
  ) =>
      _repo.initiatePayment(
        planId: quote.planId,
        billingCycle: quote.cycle,
        method: method,
        rooms: quote.rooms,
        totalAmount: quote.totalAmount,
      );

  /// Tạo payment session (mở QR / bank info / card form).
  ///
  /// Option A: `POST /payments/initiate` yêu cầu admin đã duyệt KYC
  /// (`user.kycStatus = approved`). Không tự submit KYC tại đây.
  Future<PaymentSession> initiatePayment(PaymentMethod method) async {
    final plan = state.selectedPlan;
    if (plan == null) {
      throw StateError('Chưa chọn plan');
    }

    PaymentQuote quote;
    try {
      quote = await ensureFreshQuote();
    } on VerifyApiException {
      rethrow;
    } catch (_) {
      throw const VerifyApiException(
        'Không lấy được báo giá từ máy chủ. Kiểm tra mạng và thử lại.',
      );
    }

    PaymentSession session;
    try {
      session = await _createPaymentSession(method, quote);
    } on VerifyApiException catch (e) {
      if (!e.isAmountMismatch) rethrow;
      quote = await ensureFreshQuote();
      session = await _createPaymentSession(method, quote);
    }

    state = state.copyWith(
      paymentSession: session,
      paymentQuote: quote,
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

  /// Poll trạng thái payment (tiered interval, TTL theo `expiresAt`).
  Future<PaymentStatus> checkPaymentStatus() async {
    final session = state.paymentSession;
    if (session == null) return PaymentStatus.pending;

    final status = await _repo.checkPaymentStatus(session.sessionId);
    if (status == PaymentStatus.pending) {
      state = state.copyWith(paymentStatus: status);
    } else {
      state = state.copyWith(clearPaymentSession: true, paymentStatus: status);
    }
    return status;
  }

  /// Huỷ phiên thanh toán pending — gọi khi user chọn "Đóng phiên".
  /// "Đóng và đợi" không gọi method này.
  Future<void> cancelPayment() async {
    final session = state.paymentSession;
    if (session == null) return;
    await cancelPaymentById(session.sessionId);
  }

  /// Huỷ session theo id (409 paymentPending → huỷ session cũ trước khi tạo mới).
  Future<void> cancelPaymentById(String sessionId) async {
    try {
      await _repo.cancelPayment(sessionId);
    } on VerifyApiException {
      try {
        final status = await _repo.checkPaymentStatus(sessionId);
        if (state.paymentSession?.sessionId == sessionId) {
          state = state.copyWith(paymentStatus: status);
          _persistDraft();
        }
      } catch (_) {}
      rethrow;
    }

    if (state.paymentSession?.sessionId == sessionId) {
      state = state.copyWith(clearPaymentSession: true);
      try {
        final snap = await _repo.getKycStatus();
        state = state.copyWith(status: snap.status);
      } catch (_) {}
      _persistDraft();
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
