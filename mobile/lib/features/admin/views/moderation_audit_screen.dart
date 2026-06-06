import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Lịch sử hệ thống — moderation, báo cáo vi phạm, audit admin.
/// UI demo, chờ `GET /admin/audit-log`.
class ModerationAuditScreen extends StatelessWidget {
  const ModerationAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 20,
              right: 20,
              bottom: 24,
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
                            'Báo cáo vi phạm, moderation và audit admin',
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: const [
                _SummaryNote(),
                SizedBox(height: AppSpacing.sm),
                _AuditTile(
                  category: 'Báo cáo',
                  action: 'user_172 tố cáo tin đăng spam phòng giả',
                  detail: 'Đối tượng: room_548 · Mức: Cao',
                  at: '06/06/2026 14:30',
                  by: 'Hệ thống',
                ),
                _AuditTile(
                  category: 'Xử lý',
                  action: 'admin_01 ẩn bài đăng room_548',
                  detail: 'Lý do: Sai sự thật · Từ report_001',
                  at: '06/05/2026 21:15',
                  by: 'admin_01',
                ),
                _AuditTile(
                  category: 'Moderation',
                  action: 'Khóa user_999',
                  detail: 'Lý do: Spam tin nhắn lặp lại',
                  at: '05/05/2026 18:40',
                  by: 'admin_01',
                ),
                _AuditTile(
                  category: 'Báo cáo',
                  action: 'user_816 tố cáo nội dung không phù hợp',
                  detail: 'Đối tượng: room_312 · Mức: Trung bình',
                  at: '05/05/2026 09:15',
                  by: 'Hệ thống',
                ),
                _AuditTile(
                  category: 'Xử lý',
                  action: 'moderator_03 bỏ qua report_004',
                  detail: 'Không đủ căn cứ xác minh',
                  at: '05/05/2026 10:20',
                  by: 'moderator_03',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryNote extends StatelessWidget {
  const _SummaryNote();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        'Ghi lại ai báo cáo vi phạm, admin xử lý thế nào, và các hành động '
        'moderation khác. Khác với Thông báo (booking/thanh toán cho chủ & sale).',
        style: TextStyle(color: colors.textSecondary, height: 1.4),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final String category;
  final String action;
  final String detail;
  final String at;
  final String by;

  const _AuditTile({
    required this.category,
    required this.action,
    required this.detail,
    required this.at,
    required this.by,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final badgeColor = switch (category) {
      'Báo cáo' => colors.error,
      'Xử lý' => colors.success,
      _ => colors.brand,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                at,
                style: TextStyle(fontSize: 11, color: colors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            action,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(detail, style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            'Bởi: $by',
            style: TextStyle(fontSize: 12, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}
