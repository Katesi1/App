import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_store_compliance.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_session.dart';
import '../data/models/plan.dart';
import '../data/models/verify_enums.dart';
import 'widgets/payment_dialogs.dart';
import 'widgets/verify_format.dart';

class SubscriptionDetailScreen extends ConsumerStatefulWidget {
  const SubscriptionDetailScreen({super.key});

  @override
  ConsumerState<SubscriptionDetailScreen> createState() =>
      _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState
    extends ConsumerState<SubscriptionDetailScreen> {
  bool _renewing = false;

  Future<void> _handleRenew() async {
    final method = await showModalBottomSheet<PaymentMethod>(
      context: context,
      backgroundColor: context.colors.bgSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => const _RenewMethodSheet(),
    );
    if (method == null || !mounted) return;

    setState(() => _renewing = true);
    try {
      final session = await ref
          .read(verifyFlowControllerProvider.notifier)
          .initiateRenewal(method);
      if (!mounted) return;
      _openSessionDialog(session, method);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tạo phiên gia hạn thất bại: '
              '${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: context.colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _renewing = false);
    }
  }

  void _openSessionDialog(PaymentSession session, PaymentMethod method) {
    switch (method) {
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
          builder: (_) => BankTransferDialog(session: session),
        );
        break;
      case PaymentMethod.card:
        break;
    }
    // Refresh history after the user closes the dialog (assumption: webhook
    // has or will update status). Don't poll here to keep logic simple.
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ref.invalidate(paymentHistoryProvider);
        // Reload the full paginated list if the user has /verify/payment-history open.
        ref.invalidate(paymentHistoryListProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final plan = state.selectedPlan;
    final total =
        plan == null ? 0 : PlanPriceCalculator.total(plan, state.billingCycle);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết gói đăng ký')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'Thông tin gói hiện tại, chu kỳ thanh toán và các mốc trial.',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailItem(
            label: 'Tên gói',
            value: plan?.tier.displayName ?? 'Chưa chọn',
          ),
          _DetailItem(
            label: 'Chu kỳ',
            value: state.billingCycle == BillingCycle.yearly
                ? 'Hàng năm'
                : 'Hàng tháng',
          ),
          // On iOS, the source of truth for price + renewal is Apple
          // (Settings > Apple ID > Subscriptions). We hide the VND amount to
          // avoid mismatch with the locale price the user paid via StoreKit.
          if (!usesAppleIAP)
            _DetailItem(
              label: 'Chi phí',
              value: VerifyFormat.priceVND(total),
            ),
          if (state.trialEndsAt != null)
            _DetailItem(
              label: 'Trial đến',
              value: VerifyFormat.dateVN(state.trialEndsAt!),
            ),
          if (state.chargeStartsAt != null)
            _DetailItem(
              label: 'Bắt đầu thu phí',
              value: VerifyFormat.dateVN(state.chargeStartsAt!),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (usesAppleIAP) ...[
            // Apple subscription lifecycle:
            //  - Buy first time          → "Chọn gói + Mua qua App Store"
            //  - Auto-renewal            → Apple handles automatically (no UI needed)
            //  - Upgrade / Downgrade     → "Đổi gói" → select-plan → IAP (Apple prorates)
            //  - Cancel / Change card    → "Quản lý đăng ký trên App Store"
            //                              (REQUIRED by Apple Guideline 3.1.2(a) —
            //                              deep link to iOS Settings, the only way
            //                              to cancel or change payment method)
            //  - Restore (new device)    → "Khôi phục đăng ký đã mua"
            //                              (REQUIRED by Apple — re-fires the
            //                              purchase stream with `restored` events)
            if (plan == null) ...[
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => context.push('/verify/select-plan'),
                  icon:
                      const Icon(Icons.workspace_premium_outlined, size: 18),
                  label: const Text('Chọn gói + Mua qua App Store'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ] else ...[
              // User has an active plan — let them upgrade/downgrade to a
              // different tier. Apple shows the IAP sheet and handles
              // proration automatically when the new tier is in the same
              // subscription group as the current one.
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => context.push('/verify/select-plan'),
                  icon: const Icon(Icons.upgrade_rounded, size: 18),
                  label: const Text('Đổi gói (nâng cấp/hạ cấp)'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(appleManageSubscriptionsUrl);
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Huỷ đăng ký / Đổi thẻ thanh toán'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ref
                        .read(verifyFlowControllerProvider.notifier)
                        .restoreApplePurchases();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Đang khôi phục đăng ký. Đăng ký hợp lệ sẽ tự kích hoạt.',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: context.colors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Khôi phục đăng ký đã mua'),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _renewing || plan == null ? null : _handleRenew,
                icon: _renewing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.autorenew, size: 18),
                label: Text(
                  _renewing
                      ? 'Đang tạo phiên...'
                      : 'Gia hạn ngay (${VerifyFormat.priceVND(total)})',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/verify/payment-history'),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Lịch sử thanh toán'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewMethodSheet extends StatelessWidget {
  const _RenewMethodSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn phương thức gia hạn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hệ thống dùng plan + chu kỳ hiện tại của bạn.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _MethodOption(
            icon: Icons.qr_code_2,
            title: 'VNPay QR',
            subtitle: 'Quét QR bằng app ngân hàng · Tức thời',
            onTap: () => Navigator.of(context).pop(PaymentMethod.vnpayQR),
          ),
          const SizedBox(height: 8),
          _MethodOption(
            icon: Icons.account_balance,
            title: 'Chuyển khoản',
            subtitle: 'STK + nội dung CK · 5–30 phút',
            onTap: () => Navigator.of(context).pop(PaymentMethod.bankTransfer),
          ),
        ],
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border.all(color: colors.borderDefault),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.bgSurfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: colors.brandLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}
