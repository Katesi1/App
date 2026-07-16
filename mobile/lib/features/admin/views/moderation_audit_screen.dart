import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/audit_log_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pagination_bar.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../controllers/audit_log_controller.dart';

/// Lịch sử hệ thống — nhật ký moderation & hành động admin.
/// Ghép real API `GET /admin/audit-log` (chỉ ADMIN).
class ModerationAuditScreen extends ConsumerStatefulWidget {
  const ModerationAuditScreen({super.key});

  @override
  ConsumerState<ModerationAuditScreen> createState() =>
      _ModerationAuditScreenState();
}

class _ModerationAuditScreenState
    extends ConsumerState<ModerationAuditScreen> {
  static const _filters = <({String label, String? targetType})>[
    (label: 'Tất cả', targetType: null),
    (label: 'Người dùng', targetType: 'user'),
    (label: 'Cơ sở', targetType: 'property'),
    (label: 'Booking', targetType: 'booking'),
    (label: 'KYC', targetType: 'kyc'),
    (label: 'Khiếu nại', targetType: 'dispute'),
    (label: 'Gói', targetType: 'subscription'),
    (label: 'Đánh giá', targetType: 'review'),
  ];

  String? _targetType;
  String _search = '';
  int _page = 1;

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  AuditLogQuery get _query =>
      (targetType: _targetType, search: _search.isEmpty ? null : _search, page: _page);

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _search = value.trim();
        _page = 1;
      });
    });
  }

  void _onFilterChanged(String? targetType) {
    if (_targetType == targetType) return;
    setState(() {
      _targetType = targetType;
      _page = 1;
    });
  }

  void _goToPage(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pageAsync = ref.watch(auditLogProvider(_query));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: Column(
        children: [
          _Header(
            subtitle: pageAsync.maybeWhen(
              data: (p) => '${p.total} hành động được ghi nhận',
              orElse: () => 'Moderation & audit admin',
            ),
          ),
          _SearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            colors: colors,
          ),
          _FilterChips(
            filters: _filters,
            current: _targetType,
            onChanged: _onFilterChanged,
          ),
          Expanded(
            child: RefreshIndicator(
              color: colors.brand,
              onRefresh: () async => ref.invalidate(auditLogProvider(_query)),
              child: pageAsync.when(
                loading: () =>
                    const SkeletonList(skeleton: _AuditCardSkeleton()),
                error: (e, _) => RefreshableMessage(
                  child: ErrorStateWidget(
                    message: e.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.invalidate(auditLogProvider(_query)),
                  ),
                ),
                data: (result) {
                  if (result.items.isEmpty) {
                    return const RefreshableMessage(
                      child: EmptyStateWidget(
                        icon: Icons.history_rounded,
                        message: 'Chưa có hoạt động nào',
                        subMessage:
                            'Các hành động moderation của admin sẽ hiển thị ở đây.',
                      ),
                    );
                  }
                  return _AuditList(
                    result: result,
                    onPrevious: result.page > 1
                        ? () => _goToPage(result.page - 1)
                        : null,
                    onNext: result.page < result.totalPages
                        ? () => _goToPage(result.page + 1)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String subtitle;

  const _Header({required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      'Lịch sử hệ thống',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
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
    );
  }
}

// ─── Search ──────────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AppColorScheme colors;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Tìm theo đối tượng, lý do...',
          hintStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: colors.textTertiary,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: colors.textTertiary,
          ),
          filled: true,
          fillColor: colors.bgSurface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide(color: colors.borderDefault),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide(color: colors.borderDefault),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide(color: colors.brand, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─── Filter chips ────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final List<({String label, String? targetType})> filters;
  final String? current;
  final ValueChanged<String?> onChanged;

  const _FilterChips({
    required this.filters,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: filters.map((f) {
          final active = current == f.targetType;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () => onChanged(f.targetType),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active ? colors.brand : colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: active ? colors.brand : colors.borderDefault,
                  ),
                ),
                child: Text(
                  f.label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? colors.textOnPrimary : colors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── List ────────────────────────────────────────────────────────────────────
class _AuditList extends StatelessWidget {
  final AuditLogPage result;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _AuditList({
    required this.result,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final showPagination = result.totalPages > 1;
    final itemCount = result.items.length + (showPagination ? 1 : 0);

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        if (showPagination && i == result.items.length) {
          return AppPaginationBar(
            currentPage: result.page - 1,
            totalPages: result.totalPages,
            onPrevious: onPrevious,
            onNext: onNext,
          );
        }
        return _AuditCard(entry: result.items[i]);
      },
    );
  }
}

// ─── Card ────────────────────────────────────────────────────────────────────
class _AuditCard extends StatelessWidget {
  final AuditLogEntry entry;

  const _AuditCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final catColor = entry.categoryColor;
    final reason = entry.reason;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _iconFor(entry.category),
                  size: 20,
                  color: catColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CategoryBadge(
                          label: entry.categoryLabel,
                          color: catColor,
                        ),
                        const Spacer(),
                        Text(
                          _relativeTime(entry.createdAt),
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.actionLabel,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetaRow(
            icon: Icons.person_outline_rounded,
            text: entry.actorName,
            colors: colors,
          ),
          if (entry.targetLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            _MetaRow(
              icon: Icons.adjust_rounded,
              text: entry.targetLabel,
              colors: colors,
            ),
          ],
          if (reason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: colors.bgSurfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Lý do: $reason',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                _absoluteTime(entry.createdAt),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: colors.textTertiary,
                ),
              ),
              const Spacer(),
              if (entry.ipAddress != null && entry.ipAddress!.isNotEmpty) ...[
                Icon(
                  Icons.dns_rounded,
                  size: 11,
                  color: colors.textTertiary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 3),
                Text(
                  entry.ipAddress!,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: colors.textTertiary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String category) => switch (category) {
        'user' => Icons.manage_accounts_rounded,
        'property' => Icons.apartment_rounded,
        'subscription' => Icons.workspace_premium_rounded,
        'review' => Icons.star_rounded,
        'kyc' => Icons.verified_user_rounded,
        'dispute' => Icons.gavel_rounded,
        'booking' => Icons.event_note_rounded,
        'payment' => Icons.account_balance_rounded,
        _ => Icons.history_rounded,
      };
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final AppColorScheme colors;

  const _MetaRow({
    required this.icon,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: colors.textTertiary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────
class _AuditCardSkeleton extends StatelessWidget {
  const _AuditCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: colors.bgSurfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(70, 16),
                const SizedBox(height: 8),
                bar(double.infinity, 14),
                const SizedBox(height: 8),
                bar(140, 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Time formatting ─────────────────────────────────────────────────────────
String _two(int n) => n.toString().padLeft(2, '0');

String _absoluteTime(DateTime? t) {
  if (t == null) return '';
  return '${_two(t.day)}/${_two(t.month)}/${t.year} '
      '${_two(t.hour)}:${_two(t.minute)}';
}

String _relativeTime(DateTime? t) {
  if (t == null) return '';
  final diff = DateTime.now().difference(t);
  if (diff.isNegative || diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
  return _absoluteTime(t);
}
