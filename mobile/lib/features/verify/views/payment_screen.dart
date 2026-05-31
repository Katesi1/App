import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/monitoring/analytics_service.dart';
import '../../../core/utils/app_store_compliance.dart';
import '../../../shared/widgets/status_strip.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/payment_dialogs.dart';
import 'widgets/payment_method_tile.dart';
import 'widgets/verify_app_bar.dart';
import 'widgets/verify_format.dart';

/// 3 non-IAP payment methods (Android only — VNPay / Pays2 bank / card).
/// iOS forces Apple In-App Purchase per Guideline 3.1.1 — see [usesAppleIAP].
const _kAvailableMethods = <PaymentMethod>[
  PaymentMethod.vnpayQR,
  PaymentMethod.bankTransfer,
  PaymentMethod.card,
];

/// Screen 5 — Payment.
///
/// On iOS: Apple StoreKit IAP — no method selection, single "Mua qua App
/// Store" CTA. Backend verifies the receipt at `/payments/apple/verify`.
///
/// On Android: VNPay QR / bank transfer / card via Pays2 gateway — original
/// flow (create session → show dialog → poll status → submit for approval).
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _selected = PaymentMethod.vnpayQR;
  bool _processing = false;
  Timer? _pollTimer;
  int _pollCount = 0;

  // iOS only — StoreKit purchase stream subscription + cached product info.
  StreamSubscription<List<PurchaseDetails>>? _iapSub;
  ProductDetails? _appleProduct;
  String? _appleProductError;
  bool _loadingAppleProduct = false;

  @override
  void initState() {
    super.initState();
    if (usesAppleIAP) {
      _initApple();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _iapSub?.cancel();
    super.dispose();
  }

  /// iOS: fetch product price from App Store Connect + subscribe to the
  /// StoreKit purchase stream. The stream catches `purchased`, `restored`,
  /// `error`, and `cancelled` events.
  Future<void> _initApple() async {
    setState(() => _loadingAppleProduct = true);
    try {
      final plan = ref.read(verifyFlowControllerProvider).selectedPlan;
      final cycle = ref.read(verifyFlowControllerProvider).billingCycle;
      if (plan == null) return;
      final productId = AppleProductIds.forPlan(plan.tier, cycle);
      if (productId == null) {
        setState(() {
          _appleProductError =
              'Gói Enterprise không hỗ trợ thanh toán trong app. Vui lòng liên hệ.';
          _loadingAppleProduct = false;
        });
        return;
      }
      final response = await ref
          .read(verifyFlowControllerProvider.notifier)
          .queryAppleProducts();
      final match = response.productDetails
          .where((p) => p.id == productId)
          .cast<ProductDetails?>()
          .firstWhere((_) => true, orElse: () => null);
      if (!mounted) return;
      setState(() {
        _appleProduct = match;
        _appleProductError = match == null
            ? 'Không tìm thấy sản phẩm trên App Store. Vui lòng thử lại.'
            : null;
        _loadingAppleProduct = false;
      });

      _iapSub = ref
          .read(verifyFlowControllerProvider.notifier)
          .listenAppleStoreKit(
            onSuccess: () {
              if (!mounted) return;
              setState(() => _processing = false);
              // KYC is decoupled from purchase. If admin already approved
              // (user buying separately) → go to subscription detail. If not
              // yet approved → /verify/pending shows the waiting state.
              final status =
                  ref.read(verifyFlowControllerProvider).status;
              final target = status == VerifyStatus.approved
                  ? '/verify/subscription-detail'
                  : '/verify/pending';
              context.pushReplacement(target);
            },
            onError: (msg) {
              if (!mounted) return;
              setState(() => _processing = false);
              _showError(msg);
            },
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _appleProductError = e.toString().replaceAll('Exception: ', '');
        _loadingAppleProduct = false;
      });
    }
  }

  Future<void> _handlePayApple() async {
    setState(() => _processing = true);
    AnalyticsService.logEvent('verify_payment_submit', params: const {
      'method': 'apple_iap',
    });
    try {
      await ref
          .read(verifyFlowControllerProvider.notifier)
          .buyApplePlanForSelection();
      // Result arrives via _iapSub.onSuccess / onError.
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _handleRestoreApple() async {
    try {
      await ref
          .read(verifyFlowControllerProvider.notifier)
          .restoreApplePurchases();
      _showInfo(
        'Đang khôi phục đăng ký. Nếu bạn đã mua trước đó, app sẽ tự kích hoạt.',
      );
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _handlePay() async {
    AnalyticsService.logEvent('verify_payment_submit', params: {
      'method': _selected.name,
    });
    setState(() => _processing = true);
    try {
      final session = await ref
          .read(verifyFlowControllerProvider.notifier)
          .initiatePayment(_selected);
      AnalyticsService.logEvent('verify_payment_session_created', params: {
        'method': _selected.name,
        'amount': session.totalAmount,
      });

      if (!mounted) return;

      switch (_selected) {
        case PaymentMethod.vnpayQR:
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => VNPayQRDialog(session: session),
          );
          break;
        case PaymentMethod.bankTransfer:
          showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (_) => BankTransferDialog(session: session),
          );
          break;
        case PaymentMethod.card:
          break;
      }
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      _showError('Khởi tạo thanh toán thất bại: $msg');
      AnalyticsService.logEvent('verify_payment_session_failed', params: {
        'method': _selected.name,
      });
      setState(() => _processing = false);
    }
  }

  int get _maxPollCount => switch (_selected) {
        PaymentMethod.vnpayQR => 20,
        PaymentMethod.bankTransfer => 600,
        PaymentMethod.card => 20,
      };

  void _startPolling() {
    _pollTimer?.cancel();
    _pollCount = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollCount++;
      if (_pollCount > _maxPollCount) {
        timer.cancel();
        if (mounted) {
          setState(() => _processing = false);
          if (_selected == PaymentMethod.bankTransfer) {
            _showInfo(
              'Vẫn đang đối soát chuyển khoản. Bạn có thể đóng app — '
              'hệ thống sẽ tự xác nhận khi nhận được tiền.',
            );
          } else {
            _showError(
              'Chưa nhận được xác nhận từ VNPay sau 60 giây. '
              'Nếu bạn đã thanh toán, vui lòng liên hệ hỗ trợ.',
            );
          }
        }
        return;
      }
      try {
        final status = await ref
            .read(verifyFlowControllerProvider.notifier)
            .checkPaymentStatus();
        if (status == PaymentStatus.paid) {
          timer.cancel();
          if (!mounted) return;
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          // KYC decoupled from purchase: if admin already approved → go to
          // subscription detail (user bought separately). Else → pending.
          final verifyStatus =
              ref.read(verifyFlowControllerProvider).status;
          final target = verifyStatus == VerifyStatus.approved
              ? '/verify/subscription-detail'
              : '/verify/pending';
          context.pushReplacement(target);
        } else if (status == PaymentStatus.failed ||
            status == PaymentStatus.expired) {
          timer.cancel();
          if (mounted) {
            setState(() => _processing = false);
            _showError('Thanh toán thất bại');
          }
        }
      } catch (_) {
        // silent retry
      }
    });
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 4),
        backgroundColor: context.colors.brand,
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.colors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final plan = state.selectedPlan;

    if (plan == null) {
      return Scaffold(
        appBar: const VerifyAppBar(
          overline: 'NÂNG GÓI · SUBSCRIPTION',
          title: 'Thanh toán',
        ),
        body:
            const Center(child: Text('Chưa chọn plan — quay lại bước trước.')),
      );
    }

    if (usesAppleIAP) {
      return _buildAppleIAP(plan, state.billingCycle);
    }

    final total = PlanPriceCalculator.total(plan, state.billingCycle);
    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: const VerifyAppBar(
        overline: 'NÂNG GÓI · SUBSCRIPTION',
        title: 'Thanh toán',
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              120,
            ),
            children: [
              OrderSummaryCard(
                plan: plan,
                cycle: state.billingCycle,
              ).animate().fadeIn(duration: 320.ms),
              const SizedBox(height: AppSpacing.md),
              Text(
                'PHƯƠNG THỨC THANH TOÁN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              ...PaymentMethod.values.asMap().entries.map((e) {
                final method = e.value;
                final isAvailable = _kAvailableMethods.contains(method);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PaymentMethodTile(
                    method: method,
                    isSelected: _selected == method,
                    isComingSoon: !isAvailable,
                    onTap: () {
                      if (!isAvailable) return;
                      setState(() => _selected = method);
                    },
                  )
                      .animate(delay: (60 * e.key).ms)
                      .fadeIn(duration: 240.ms)
                      .slideY(begin: 0.05, end: 0),
                );
              }),
              const SizedBox(height: AppSpacing.md),
              const StatusStrip(
                icon: Icons.lock_outline,
                label: 'Hoàn tiền 100% trong 14 ngày',
                subtitle:
                    'Nếu không hài lòng, yêu cầu hoàn tiền trong vòng 14 ngày kể từ thanh toán.',
                variant: StatusStripVariant.brand,
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                MediaQuery.of(context).padding.bottom + AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border(top: BorderSide(color: colors.borderDefault)),
              ),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _processing ? null : _handlePay,
                  icon: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.darkBg),
                        )
                      : const Icon(Icons.lock_outline, size: 18),
                  label: Text(
                    _processing
                        ? 'Đang xử lý...'
                        : 'Thanh toán an toàn ${VerifyFormat.priceVND(total)}',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// iOS-only payment surface: single Apple IAP method + Restore Purchases
  /// link. No VNPay / bank / Pays2 options (Apple Guideline 3.1.1).
  Widget _buildAppleIAP(Plan plan, BillingCycle cycle) {
    final colors = context.colors;
    final priceLabel = _appleProduct?.price ??
        (_loadingAppleProduct ? 'Đang tải giá...' : '');
    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: const VerifyAppBar(
        overline: 'NÂNG GÓI · SUBSCRIPTION',
        title: 'Thanh toán',
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              140,
            ),
            children: [
              OrderSummaryCard(plan: plan, cycle: cycle)
                  .animate()
                  .fadeIn(duration: 320.ms),
              const SizedBox(height: AppSpacing.md),
              Text(
                'PHƯƠNG THỨC THANH TOÁN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              _AppleIAPTile(
                priceLabel: priceLabel,
                productTitle: _appleProduct?.title ?? 'App Store In-App Purchase',
                isLoading: _loadingAppleProduct,
                errorMessage: _appleProductError,
              ),
              const SizedBox(height: AppSpacing.md),
              const StatusStrip(
                icon: Icons.lock_outline,
                label: 'Thanh toán an toàn qua App Store',
                subtitle:
                    'Mọi giao dịch xử lý bởi Apple. Đăng ký tự gia hạn — hủy bất cứ lúc nào trong Cài đặt > Apple ID > Đăng ký.',
                variant: StatusStripVariant.brand,
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton.icon(
                  onPressed: _handleRestoreApple,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Khôi phục đăng ký đã mua'),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                MediaQuery.of(context).padding.bottom + AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border(top: BorderSide(color: colors.borderDefault)),
              ),
              child: SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      (_processing || _appleProduct == null) ? null : _handlePayApple,
                  icon: _processing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.darkBg),
                        )
                      : const Icon(Icons.apple, size: 20),
                  label: Text(
                    _processing
                        ? 'Đang xử lý...'
                        : priceLabel.isEmpty
                            ? 'Mua qua App Store'
                            : 'Mua qua App Store · $priceLabel',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleIAPTile extends StatelessWidget {
  final String priceLabel;
  final String productTitle;
  final bool isLoading;
  final String? errorMessage;

  const _AppleIAPTile({
    required this.priceLabel,
    required this.productTitle,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderBrand),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.bgCanvas,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.apple, size: 22, color: colors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apple In-App Purchase',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  errorMessage ??
                      (isLoading
                          ? 'Đang lấy thông tin sản phẩm từ App Store...'
                          : '$productTitle · Đăng ký tự gia hạn'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: errorMessage != null
                        ? colors.error
                        : colors.textTertiary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (priceLabel.isNotEmpty && errorMessage == null) ...[
            const SizedBox(width: 8),
            Text(
              priceLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
