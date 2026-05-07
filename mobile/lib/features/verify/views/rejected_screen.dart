import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/status_strip.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/verify_enums.dart';
import 'widgets/verify_format.dart';

/// Screen 8 — Rejected (admin reject toàn bộ hoặc một phần).
class RejectedScreen extends ConsumerWidget {
  const RejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(verifyFlowControllerProvider);
    final items = ref.watch(kycItemsStatusProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      // User landed ở đây qua `pushReplacement` từ pending → stack rỗng,
      // cần explicit exit. AppBar X dismiss → /home (router auto-redirect
      // sang /dashboard nếu là management user).
      appBar: AppBar(
        backgroundColor: colors.bgCanvas,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            color: colors.textSecondary,
            tooltip: 'Đóng',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _RoseBanner()
                .animate()
                .slideY(begin: -0.4, end: 0, duration: 360.ms),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (state.rejectReason != null)
                    _ReasonCard(reason: state.rejectReason!)
                        .animate(delay: 120.ms)
                        .fadeIn(duration: 320.ms)
                        .slideY(begin: 0.06, end: 0),
                  const SizedBox(height: AppSpacing.md),
                  if (state.refundProcessed)
                    StatusStrip(
                      icon: Icons.check_circle,
                      label:
                          'Đã hoàn ${VerifyFormat.priceVND(state.refundedAmount ?? 0)}',
                      subtitle:
                          'Tiền sẽ về phương thức thanh toán gốc trong 3-7 ngày làm việc.',
                      variant: StatusStripVariant.success,
                    )
                  else
                    const StatusStrip(
                      icon: Icons.shield_outlined,
                      label: 'Tiền của bạn an toàn',
                      subtitle:
                          'Thanh toán tạm giữ. Bổ sung và được duyệt → trial bắt đầu. Hoặc yêu cầu hoàn 100%.',
                      variant: StatusStripVariant.brand,
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _NeedFixCard(items: items),
                  // Sau khi refund xong → bottom action bar bị ẩn → cần
                  // secondary CTA "Về trang chủ" để user thoát.
                  if (state.refundProcessed) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.borderDefault),
                          foregroundColor: colors.textSecondary,
                        ),
                        onPressed: () => context.go('/home'),
                        child: const Text('Về trang chủ'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!state.refundProcessed)
              _ActionBar(
                onRefund: () => _confirmRefund(context, ref),
                onResubmit: () {
                  final firstRejected = state.rejectedItems.firstOrNull;
                  if (firstRejected == null) return;
                  switch (firstRejected) {
                    case RejectableItem.cccdFront:
                      context.push('/verify/cccd-front?resubmit=1');
                      break;
                    case RejectableItem.cccdBack:
                      context.push('/verify/cccd-back?resubmit=1');
                      break;
                    case RejectableItem.selfie:
                      context.push('/verify/selfie?resubmit=1');
                      break;
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRefund(BuildContext context, WidgetRef ref) async {
    final colors = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.bgSurfaceElevated,
        title: const Text('Hoàn tiền 100%?'),
        content: const Text(
          'Hồ sơ verify sẽ bị huỷ và bạn cần đăng ký lại nếu muốn dùng. '
          'Tiền sẽ được hoàn vào phương thức thanh toán gốc trong 3-7 ngày làm việc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hoàn tiền'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(verifyFlowControllerProvider.notifier).requestRefund();
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _RoseBanner extends StatelessWidget {
  const _RoseBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorBg,
        border: Border(
          bottom: BorderSide(color: colors.error.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.close, size: 20, color: colors.error),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hồ sơ chưa được duyệt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cần bổ sung thông tin theo lý do bên dưới',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  final String reason;
  const _ReasonCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LÝ DO TỪ ADMIN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$reason"',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: colors.borderSubtle),
          const SizedBox(height: 8),
          Text(
            '— Admin Halong24h · ${VerifyFormat.time(DateTime.now())}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedFixCard extends StatelessWidget {
  final List<KycItemStatus> items;
  const _NeedFixCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 6),
            child: Text(
              'CẦN BỔ SUNG',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: colors.textTertiary,
              ),
            ),
          ),
          ...items.map((s) => _ItemRow(status: s)),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final KycItemStatus status;
  const _ItemRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRejected = status.isRejected;

    return InkWell(
      onTap: isRejected
          ? () {
              switch (status.item) {
                case RejectableItem.cccdFront:
                  context.push('/verify/cccd-front?resubmit=1');
                  break;
                case RejectableItem.cccdBack:
                  context.push('/verify/cccd-back?resubmit=1');
                  break;
                case RejectableItem.selfie:
                  context.push('/verify/selfie?resubmit=1');
                  break;
              }
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: (isRejected ? colors.error : colors.success)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isRejected ? Icons.close : Icons.check,
                size: 14,
                color: isRejected ? colors.error : colors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status.item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Text(
              isRejected ? 'Cần chụp lại' : 'Đã duyệt',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isRejected ? colors.error : colors.success,
              ),
            ),
            const SizedBox(width: 6),
            if (isRejected)
              Icon(Icons.chevron_right, size: 18, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final VoidCallback onRefund;
  final VoidCallback onResubmit;

  const _ActionBar({required this.onRefund, required this.onResubmit});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.borderDefault),
                  foregroundColor: colors.textPrimary,
                  backgroundColor: colors.borderDefault,
                ),
                onPressed: onRefund,
                child: const Text('Yêu cầu hoàn tiền'),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: onResubmit,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Bổ sung ngay'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
