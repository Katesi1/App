import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../profile/data/models/bank_account.dart';
import '../../profile/data/vn_banks.dart';
import '../controllers/admin_bank_controller.dart';
import '../data/models/admin_bank_account.dart';

/// ADMIN queue — duyệt tài khoản nhận tiền (VietQR) của OWNER.
///
/// 4 tab: Chờ duyệt (default) / Đã duyệt / Từ chối / Tất cả.
class AdminBankListScreen extends ConsumerWidget {
  const AdminBankListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final filter = ref.watch(bankQueueFilterProvider);
    final listAsync = ref.watch(filteredBankAccountsProvider);
    final pendingCount = ref.watch(pendingBankCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duyệt tài khoản ngân hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            Text(
              '$pendingCount yêu cầu đang chờ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _FilterTabs(
            current: filter,
            pendingCount: pendingCount,
            onChanged: (f) =>
                ref.read(bankQueueFilterProvider.notifier).state = f,
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(bankQueueProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return _EmptyState(filter: filter);
                }
                return RefreshIndicator(
                  color: colors.brand,
                  onRefresh: () async => ref.invalidate(bankQueueProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _AccountCard(
                      account: list[i],
                      onTap: () => context.push(
                        '/admin/bank-accounts/${list[i].id}',
                        extra: list[i],
                      ),
                    )
                        .animate(delay: (40 * i).ms)
                        .fadeIn(duration: 240.ms)
                        .slideY(begin: 0.04, end: 0),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final BankQueueFilter current;
  final int pendingCount;
  final ValueChanged<BankQueueFilter> onChanged;

  const _FilterTabs({
    required this.current,
    required this.pendingCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 10),
      color: context.colors.bgSurface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in BankQueueFilter.values) ...[
              _FilterChip(
                label: f.label,
                count: f == BankQueueFilter.pending ? pendingCount : null,
                isActive: current == f,
                onTap: () => onChanged(f),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;

  /// Badge count — `null` ẩn badge (chip chỉ có label).
  final int? count;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.brand : colors.bgSurfaceContainer,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? colors.brand : colors.borderDefault,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.darkBg : colors.textPrimary,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.darkBg.withValues(alpha: 0.15)
                      : colors.borderDefault,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.darkBg : colors.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AdminBankAccount account;
  final VoidCallback onTap;

  const _AccountCard({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final a = account;
    final info = a.displayInfo;
    final bank = bankByBin(info?.bankBin);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border.all(
            color: a.isPending ? colors.brand : colors.borderDefault,
            width: a.isPending ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(name: a.name, url: a.avatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name.isEmpty ? 'Chủ homestay' : a.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.phone ?? a.email ?? '—',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusPill(status: account.status),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: colors.borderSubtle),
            const SizedBox(height: 10),
            Row(
              children: [
                if (bank != null) ...[
                  _BankLogo(url: bank.logoUrl, size: 28),
                  const SizedBox(width: 10),
                ] else ...[
                  Icon(Icons.account_balance_rounded,
                      size: 20, color: colors.textSecondary),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info?.bankName ??
                            bank?.shortName ??
                            'Chưa có tài khoản',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (info != null)
                        Text(
                          '${info.bankAccountNumber}  ·  ${info.bankAccountName}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: colors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? url;
  const _Avatar({required this.name, this.url});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: url!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          memCacheWidth: 120,
          placeholder: (_, __) => _fallback(colors),
          errorWidget: (_, __, ___) => _fallback(colors),
        ),
      );
    }
    return _fallback(colors);
  }

  Widget _fallback(AppColorScheme colors) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.brand.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'O',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.brand,
          ),
        ),
      );
}

class _BankLogo extends StatelessWidget {
  final String url;
  final double size;
  const _BankLogo({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        memCacheWidth: 120,
        placeholder: (_, __) => _fallback(context),
        errorWidget: (_, __, ___) => _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: context.colors.bgSurfaceContainer,
        child: Icon(Icons.account_balance_rounded,
            size: size * 0.55, color: context.colors.textTertiary),
      );
}

class _StatusPill extends StatelessWidget {
  final BankApprovalStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, fg, bg) = switch (status) {
      BankApprovalStatus.approved => (
          'Đã duyệt',
          colors.success,
          AppColors.successBgDark
        ),
      BankApprovalStatus.rejected => (
          'Từ chối',
          colors.error,
          AppColors.errorBgDark
        ),
      BankApprovalStatus.pending => (
          'Chờ duyệt',
          colors.brandSecondary,
          AppColors.goldBg
        ),
      BankApprovalStatus.none => (
          'Chưa có',
          colors.textTertiary,
          colors.bgSurfaceContainer
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: fg,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final BankQueueFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, label) = switch (filter) {
      BankQueueFilter.pending => (
          Icons.inbox_outlined,
          'Không có yêu cầu chờ duyệt'
        ),
      BankQueueFilter.approved => (
          Icons.check_circle_outline,
          'Chưa có tài khoản đã duyệt'
        ),
      BankQueueFilter.rejected => (
          Icons.cancel_outlined,
          'Chưa có tài khoản bị từ chối'
        ),
      BankQueueFilter.all => (Icons.inbox_outlined, 'Chưa có yêu cầu nào'),
    };
    return ListView(
      // ListView để RefreshIndicator kéo được cả khi rỗng.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(icon, size: 48, color: colors.textTertiary),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
