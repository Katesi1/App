import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../verify/data/models/verify_enums.dart';
import '../../verify/views/widgets/verify_format.dart';
import '../controllers/kyc_approval_controller.dart';
import '../data/models/kyc_submission.dart';

/// Admin queue — list KYC submissions chờ duyệt.
///
/// 4 tabs: Chờ duyệt (default) / Đã duyệt / Bị từ chối / Tất cả.
/// Sort: overdue lên đầu cho tab "Chờ duyệt", oldest first.
class KYCApprovalListScreen extends ConsumerWidget {
  const KYCApprovalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final filter = ref.watch(kycQueueFilterProvider);
    final listAsync = ref.watch(filteredKycSubmissionsProvider);
    final pendingCount = ref.watch(pendingKycCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.jade900, AppColors.jade500],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -50,
                  top: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.jade300.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold500.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duyệt KYC',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '$pendingCount hồ sơ đang chờ duyệt',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _FilterTabs(
            current: filter,
            onChanged: (f) =>
                ref.read(kycQueueFilterProvider.notifier).state = f,
          ),
          Expanded(
            child: listAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return _EmptyState(filter: filter);
                }
                return RefreshIndicator(
                  color: colors.brand,
                  onRefresh: () async => ref.invalidate(kycSubmissionsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SubmissionCard(
                      submission: list[i],
                      onTap: () => context.push(
                        '/admin/kyc/${list[i].id}',
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

class _FilterTabs extends ConsumerWidget {
  final KYCQueueFilter current;
  final ValueChanged<KYCQueueFilter> onChanged;

  const _FilterTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(kycSubmissionsProvider).valueOrNull ?? const [];
    final counts = {
      KYCQueueFilter.pending:
          all.where((s) => s.status == VerifyStatus.awaitingApproval).length,
      KYCQueueFilter.approved:
          all.where((s) => s.status == VerifyStatus.approved).length,
      KYCQueueFilter.rejected:
          all.where((s) => s.status == VerifyStatus.rejected).length,
      KYCQueueFilter.all: all.length,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 10),
      color: context.colors.bgSurface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in KYCQueueFilter.values) ...[
              _FilterChip(
                label: _label(f),
                count: counts[f] ?? 0,
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

  String _label(KYCQueueFilter f) => switch (f) {
        KYCQueueFilter.pending => 'Chờ duyệt',
        KYCQueueFilter.approved => 'Đã duyệt',
        KYCQueueFilter.rejected => 'Từ chối',
        KYCQueueFilter.all => 'Tất cả',
      };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
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
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final KYCSubmission submission;
  final VoidCallback onTap;

  const _SubmissionCard({required this.submission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final s = submission;
    final accent = _accentColor(s, colors);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border.all(
            color: s.isOverdue ? colors.error : colors.borderDefault,
            width: s.isOverdue ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconFor(s), size: 18, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.ownerName,
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
                        '${s.ownerPhone}  ·  CCCD ${s.cccdFront.ocrResult?.cccdNumber ?? "—"}',
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
                _StatusPill(submission: s),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: colors.borderSubtle),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Meta(
                    label: 'GÓI',
                    value: s.planName,
                  ),
                ),
                Expanded(
                  child: _Meta(
                    label: 'PHÒNG',
                    value: '${s.expectedRooms}',
                  ),
                ),
                Expanded(
                  child: _Meta(
                    label: 'TIỀN',
                    value: VerifyFormat.priceShort(s.totalAmount),
                    align: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: colors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  _ageLabel(s),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: s.isOverdue ? colors.error : colors.textTertiary,
                  ),
                ),
                const Spacer(),
                if (s.isPending)
                  Text(
                    'Xem chi tiết →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.brandLight,
                    ),
                  )
                else if (s.handledByAdmin != null)
                  Text(
                    'bởi ${s.handledByAdmin}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColor(KYCSubmission s, AppColorScheme colors) {
    if (s.isApproved) return colors.success;
    if (s.isRejected) return colors.error;
    if (s.isOverdue) return colors.error;
    return colors.brandLight;
  }

  IconData _iconFor(KYCSubmission s) {
    if (s.isApproved) return Icons.check_circle;
    if (s.isRejected) return Icons.cancel;
    if (s.isOverdue) return Icons.warning_amber;
    return Icons.person;
  }

  String _ageLabel(KYCSubmission s) {
    final age = s.age;
    final hours = age.inHours;
    if (s.isPending) {
      if (hours >= 24) return 'Quá hạn ${hours - 24}h';
      if (hours >= 1) return 'Đã chờ ${hours}h';
      return 'Đã chờ ${age.inMinutes} phút';
    }
    final handledAt = s.handledAt ?? s.submittedAt;
    final ago = DateTime.now().difference(handledAt);
    if (ago.inHours >= 24) return 'Xử lý ${ago.inDays} ngày trước';
    if (ago.inHours >= 1) return 'Xử lý ${ago.inHours}h trước';
    return 'Xử lý ${ago.inMinutes} phút trước';
  }
}

class _StatusPill extends StatelessWidget {
  final KYCSubmission submission;
  const _StatusPill({required this.submission});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (label, fg, bg) = switch (submission.status) {
      VerifyStatus.approved => (
          'Đã duyệt',
          colors.success,
          AppColors.successBgDark
        ),
      VerifyStatus.rejected => ('Từ chối', colors.error, AppColors.errorBgDark),
      _ => submission.isOverdue
          ? ('Quá hạn', colors.error, AppColors.errorBgDark)
          : ('Chờ duyệt', colors.brandSecondary, AppColors.goldBg),
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

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  final TextAlign align;

  const _Meta({
    required this.label,
    required this.value,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final crossAxis = align == TextAlign.end
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: crossAxis,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: align,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final KYCQueueFilter filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, label) = switch (filter) {
      KYCQueueFilter.pending => (
          Icons.inbox_outlined,
          'Không có hồ sơ chờ duyệt'
        ),
      KYCQueueFilter.approved => (
          Icons.check_circle_outline,
          'Chưa có hồ sơ đã duyệt'
        ),
      KYCQueueFilter.rejected => (
          Icons.cancel_outlined,
          'Chưa có hồ sơ từ chối'
        ),
      KYCQueueFilter.all => (Icons.inbox_outlined, 'Chưa có hồ sơ nào'),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colors.textTertiary),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
