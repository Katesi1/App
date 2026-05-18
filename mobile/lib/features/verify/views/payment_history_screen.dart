import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/verify_flow_controller.dart';
import '../data/models/payment_history_item.dart';
import '../data/models/verify_enums.dart';
import 'widgets/verify_format.dart';

/// Payment + renewal history for OWNER. Reached from:
/// - `/profile` → "Subscription" → "Payment history"
/// - `/verify/subscription-detail` → "View history" CTA
///
/// Cursor-based pagination (see `api-payments-frontend-spec.md` §7.3):
/// - First page auto-fetches when `paymentHistoryListProvider` mounts
/// - Scrolling near the bottom → auto-triggers `loadMore()` (200px threshold)
/// - `state.hasMore == false` → hide the "loading" footer
class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = ref.read(paymentHistoryListProvider);
    if (!state.hasMore || state.isLoadingMore) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(paymentHistoryListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(paymentHistoryListProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: const Text('Lịch sử thanh toán'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoadingFirstPage
                ? null
                : () => ref.read(paymentHistoryListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(PaymentHistoryListState state) {
    if (state.isLoadingFirstPage && state.items.isEmpty) {
      return const Center(child: LoadingWidget());
    }
    if (state.error != null && state.items.isEmpty) {
      return ErrorStateWidget(
        message: state.error!,
        onRetry: () => ref.read(paymentHistoryListProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        message: 'Chưa có giao dịch nào',
        subMessage:
            'Sau khi thanh toán đăng ký lần đầu, các giao dịch sẽ xuất hiện ở đây.',
      );
    }

    final paid = state.items.where((i) =>
        i.status == PaymentStatus.paid && i.kind != PaymentHistoryKind.refund);
    final totalPaid = paid.fold<int>(0, (sum, i) => sum + i.amount);

    return RefreshIndicator(
      onRefresh: () => ref.read(paymentHistoryListProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        // +1 header, +1 footer cho loadMore/error pill
        itemCount: state.items.length + 2,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          if (index == 0) {
            return _SummaryHeader(
              totalPaid: totalPaid,
              transactionCount: paid.length,
            );
          }
          if (index == state.items.length + 1) {
            return _Footer(state: state);
          }
          return _PaymentHistoryRow(item: state.items[index - 1]);
        },
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  final PaymentHistoryListState state;
  const _Footer({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (state.error != null && state.items.isNotEmpty) {
      // loadMore failed — show retry without replacing the existing list.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton.icon(
            onPressed: () =>
                ref.read(paymentHistoryListProvider.notifier).loadMore(),
            icon: Icon(Icons.refresh, size: 16, color: colors.error),
            label: Text(
              'Tải thêm thất bại — thử lại',
              style: TextStyle(color: colors.error),
            ),
          ),
        ),
      );
    }
    if (!state.hasMore && state.items.length > 5) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'Đã hiển thị tất cả ${state.items.length} giao dịch',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textTertiary,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _SummaryHeader extends StatelessWidget {
  final int totalPaid;
  final int transactionCount;

  const _SummaryHeader({
    required this.totalPaid,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TỔNG ĐÃ THANH TOÁN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  VerifyFormat.priceVND(totalPaid),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.textBrand,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$transactionCount giao dịch',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  final PaymentHistoryItem item;

  const _PaymentHistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetail(context, item),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.bgSurface,
          border: Border.all(color: context.colors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KindIcon(kind: item.kind, status: item.status),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.kind.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        // Backend §7.4: refund rows have a positive `amount` —
                        // FE adds the minus sign + coral colour so the user
                        // sees the negative direction.
                        item.isRefund
                            ? '-${VerifyFormat.priceVND(item.amount)}'
                            : VerifyFormat.priceVND(item.amount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: item.isRefund
                              ? AppColors.coral700
                              : context.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.planLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusPill(status: item.status),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          VerifyFormat.dateVN(item.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, PaymentHistoryItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.bgSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _DetailSheet(item: item),
    );
  }
}

class _KindIcon extends StatelessWidget {
  final PaymentHistoryKind kind;
  final PaymentStatus status;

  const _KindIcon({required this.kind, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = switch (kind) {
      PaymentHistoryKind.subscription => Icons.workspace_premium,
      PaymentHistoryKind.renew => Icons.autorenew,
      PaymentHistoryKind.upgrade => Icons.upgrade,
      PaymentHistoryKind.refund => Icons.undo,
    };
    final tint =
        status == PaymentStatus.paid && kind != PaymentHistoryKind.refund
            ? colors.success
            : kind == PaymentHistoryKind.refund
                ? AppColors.coral700
                : colors.textTertiary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: tint),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final PaymentStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, bg, fg) = switch (status) {
      PaymentStatus.paid => (
          'Đã thanh toán',
          AppColors.successBgDark,
          colors.success
        ),
      PaymentStatus.pending => (
          'Đang xử lý',
          colors.bgSurfaceContainer,
          colors.textSecondary
        ),
      PaymentStatus.failed => (
          'Thất bại',
          AppColors.coral50,
          AppColors.coral700
        ),
      PaymentStatus.expired => (
          'Hết hạn',
          AppColors.coral50,
          AppColors.coral700
        ),
      PaymentStatus.refunded => (
          'Đã hoàn tiền',
          AppColors.coral50,
          AppColors.coral700
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final PaymentHistoryItem item;

  const _DetailSheet({required this.item});

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
          Row(
            children: [
              _KindIcon(kind: item.kind, status: item.status),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.kind.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      item.planLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: item.status),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _detailRow(context,
              label: 'Số tiền',
              value: '${item.isRefund ? '-' : ''}'
                  '${VerifyFormat.priceVND(item.amount)}',
              valueColor:
                  item.isRefund ? AppColors.coral700 : colors.textBrand),
          _detailRow(context,
              label: 'Phương thức', value: item.method.displayName),
          _detailRow(context,
              label: 'Thời gian tạo',
              value:
                  '${VerifyFormat.dateVN(item.createdAt)} · ${VerifyFormat.time(item.createdAt)}'),
          if (item.settledAt != null)
            _detailRow(context,
                label: 'Hoàn tất',
                value:
                    '${VerifyFormat.dateVN(item.settledAt!)} · ${VerifyFormat.time(item.settledAt!)}'),
          if (item.referenceCode != null)
            _detailRow(context,
                label: 'Mã giao dịch', value: item.referenceCode!),
          if (item.invoiceNumber != null)
            _detailRow(context, label: 'Hoá đơn', value: item.invoiceNumber!),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
