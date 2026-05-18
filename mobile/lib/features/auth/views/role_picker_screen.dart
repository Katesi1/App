import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';

/// OAuth provider — picks which BE endpoint to call after the user selects a role.
enum SocialProvider { google, apple }

/// Args passed via `state.extra` when pushing `/auth/role-picker` from the login flow.
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
        // Auth state is updated; router redirects to /dashboard (and into KYC
        // for OWNERs who haven't completed it yet).
        return;
      case GoogleSignInFailure(:final message):
        setState(() {
          _isLoading = false;
          _submittingRole = null;
        });
        _showError(message);
      case GoogleSignInNeedsRole():
        // Should not happen at this point since we just sent a role.
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
        backgroundColor: AppColors.coral,
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
    final profile = widget.args.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isLoading
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.navy),
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
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Bạn muốn dùng Halong24h với vai trò nào?',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GoogleAvatar(profile: profile),
              const SizedBox(height: AppSpacing.xl),
              _RoleOption(
                icon: Icons.home_work_rounded,
                title: 'Tôi là chủ homestay',
                subtitle:
                    'Đăng phòng, quản lý booking & doanh thu (cần xác minh CCCD).',
                color: AppColors.ocean,
                isLoading: _submittingRole == UserRole.owner,
                disabled: _isLoading && _submittingRole != UserRole.owner,
                onTap: () => _onPickRole(UserRole.owner),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
              const Spacer(),
              Text(
                'Là nhân viên? Đợi chủ homestay gửi email mời, '
                'không cần chọn ở đây.',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: AppColors.muted,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
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
                      color: AppColors.background,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: AppColors.background,
                      child: const Icon(Icons.person, color: AppColors.muted),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: AppColors.background,
                    child: const Icon(Icons.person, color: AppColors.muted),
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
                    color: AppColors.navy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Đăng nhập qua Google',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: AppColors.muted,
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
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Material(
        color: AppColors.surface,
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
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AppColors.muted,
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
