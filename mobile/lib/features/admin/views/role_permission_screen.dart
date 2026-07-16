import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../controllers/permission_controller.dart';

/// Danh sách SALE hệ thống → tap mở màn editor phân quyền per-user.
///
/// Thay thế thiết kế cũ (role-based, lưu SharedPreferences) bằng per-user ghép
/// API thật `GET /users?scope=system` + `GET/PUT /permissions/:userId`.
class RolePermissionScreen extends ConsumerStatefulWidget {
  const RolePermissionScreen({super.key});

  @override
  ConsumerState<RolePermissionScreen> createState() =>
      _RolePermissionScreenState();
}

class _RolePermissionScreenState extends ConsumerState<RolePermissionScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  List<UserModel> _filter(List<UserModel> users) {
    if (_query.isEmpty) return users;
    return users.where((u) {
      final name = u.name.toLowerCase();
      final email = (u.email ?? '').toLowerCase();
      final phone = u.phone.toLowerCase();
      return name.contains(_query) ||
          email.contains(_query) ||
          phone.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final listAsync = ref.watch(systemSaleListProvider);

    return Scaffold(
      backgroundColor: colors.bgSurfaceContainer,
      body: Column(
        children: [
          _Header(count: listAsync.valueOrNull?.length),
          _SearchField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
          ),
          Expanded(
            child: RefreshIndicator(
              color: colors.brand,
              onRefresh: () async {
                ref.invalidate(systemSaleListProvider);
                await ref.read(systemSaleListProvider.future);
              },
              child: listAsync.when(
                data: (users) {
                  final filtered = _filter(users);
                  if (filtered.isEmpty) {
                    return RefreshableMessage(
                      child: EmptyStateWidget(
                        icon: Icons.badge_outlined,
                        message: _query.isEmpty
                            ? 'Chưa có SALE hệ thống nào'
                            : 'Không tìm thấy kết quả',
                        subMessage: _query.isEmpty
                            ? 'SALE hệ thống sẽ hiển thị ở đây để cấp quyền'
                            : 'Thử từ khoá khác',
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final user = filtered[i];
                      return _SaleCard(user: user)
                          .animate()
                          .fadeIn(duration: 220.ms, delay: (i * 35).ms)
                          .slideY(
                            begin: 0.05,
                            end: 0,
                            duration: 220.ms,
                            delay: (i * 35).ms,
                          );
                    },
                  );
                },
                loading: () => const SkeletonList(
                  skeleton: UserCardSkeleton(),
                  count: 6,
                ),
                error: (e, _) => RefreshableMessage(
                  child: ErrorStateWidget(
                    message: e.toString().replaceAll('Exception: ', ''),
                    onRetry: () => ref.invalidate(systemSaleListProvider),
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

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int? count;

  const _Header({this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.jade900, AppColors.jade500],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20,
          right: 20,
          bottom: 18,
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
                        'Phân quyền SALE',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        count == null
                            ? 'SALE hệ thống'
                            : '$count SALE hệ thống',
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
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.bgSurfaceContainer,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên, email, SĐT',
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
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colors.borderDefault),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colors.borderDefault),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colors.brand),
          ),
        ),
      ),
    );
  }
}

// ── SALE card ─────────────────────────────────────────────────────────────────

class _SaleCard extends StatelessWidget {
  final UserModel user;

  const _SaleCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = user.name.isNotEmpty ? user.name : 'Chưa đặt tên';
    final email = user.email ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.push(
            '/admin/role-permissions/${user.id}'
            '?name=${Uri.encodeComponent(name)}',
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(isActive: user.isActive),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email.isNotEmpty ? email : user.phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textTertiary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.slate400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Đã khoá',
        style: GoogleFonts.beVietnamPro(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
