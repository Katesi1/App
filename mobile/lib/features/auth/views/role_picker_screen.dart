import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';

/// OAuth provider — quyết định endpoint BE gọi sau khi user chọn role.
enum SocialProvider { google, apple }

/// Args truyền qua `state.extra` khi push `/auth/role-picker` từ login flow.
class RolePickerArgs {
  final String idToken;
  final GoogleProfile profile;
  final SocialProvider provider;

  const RolePickerArgs({
    required this.idToken,
    required this.profile,
    this.provider = SocialProvider.google,
  });
}

class RolePickerScreen extends ConsumerStatefulWidget {
  final RolePickerArgs args;

  const RolePickerScreen({super.key, required this.args});

  @override
  ConsumerState<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends ConsumerState<RolePickerScreen> {
  bool _isLoading = false;
  UserRole? _submittingRole;

  Future<void> _onPickRole(UserRole role) async {
    setState(() {
      _isLoading = true;
      _submittingRole = role;
    });

    final notifier = ref.read(authProvider.notifier);
    final outcome = switch (widget.args.provider) {
      SocialProvider.google => await notifier.completeGoogleSignInWithRole(
          idToken: widget.args.idToken,
          role: role.value,
        ),
      SocialProvider.apple => await notifier.completeAppleSignInWithRole(
          idToken: widget.args.idToken,
          role: role.value,
          email: widget.args.profile.email.isEmpty
              ? null
              : widget.args.profile.email,
          name: widget.args.profile.name.isEmpty
              ? null
              : widget.args.profile.name,
        ),
    };

    if (!mounted) return;

    switch (outcome) {
      case GoogleSignInSuccess():
        // Auth state đã update → router redirect /dashboard
        return;
      case GoogleSignInFailure(:final message):
        setState(() {
          _isLoading = false;
          _submittingRole = null;
        });
        _showError(message);
      case GoogleSignInNeedsRole():
        // Không nên xảy ra ở bước này (đã gửi role), nhưng safe.
        setState(() {
          _isLoading = false;
          _submittingRole = null;
        });
        _showError('Phản hồi từ máy chủ không hợp lệ. Vui lòng thử lại.');
      case GoogleSignInCancelled():
        setState(() {
          _isLoading = false;
          _submittingRole = null;
        });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.colors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final profile = widget.args.profile;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isLoading
            ? null
            : IconButton(
                icon: Icon(Icons.close_rounded, color: colors.textPrimary),
                onPressed: () => context.pop(),
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chào ${profile.name.isEmpty ? 'bạn' : profile.name}!',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Bạn muốn dùng Halong24h với vai trò nào?',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GoogleAvatar(profile: profile),
              const SizedBox(height: AppSpacing.xl),
              _RoleOption(
                icon: Icons.home_work_rounded,
                title: 'Tôi là chủ homestay',
                subtitle:
                    'Quản lý phòng, giữ booking cho khách & theo dõi doanh thu '
                    '(cần xác minh CCCD).',
                color: AppColors.jade500,
                isLoading: _submittingRole == UserRole.owner,
                disabled: _isLoading && _submittingRole != UserRole.owner,
                onTap: () => _onPickRole(UserRole.owner),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
              const Spacer(),
              Text(
                'Là nhân viên? Đợi chủ homestay gửi email mời, '
                'không cần chọn ở đây.',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleAvatar extends StatelessWidget {
  final GoogleProfile profile;

  const _GoogleAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: profile.avatar != null && profile.avatar!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: profile.avatar!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    memCacheWidth: 96,
                    placeholder: (_, __) => Container(
                      width: 48,
                      height: 48,
                      color: colors.bgCanvas,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: colors.bgCanvas,
                      child: Icon(Icons.person, color: colors.textTertiary),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: colors.bgCanvas,
                    child: Icon(Icons.person, color: colors.textTertiary),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.email,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Đăng nhập qua Google',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: colors.textTertiary,
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

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final bool disabled;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Material(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: colors.textTertiary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: color,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
