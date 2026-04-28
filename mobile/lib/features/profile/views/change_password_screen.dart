import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/widgets/loading_widget.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7 — chưa có token sẵn
const _jadeMidLight = Color(0xFF1B7E94);

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final (success, message) = await ref
        .read(authProvider.notifier)
        .changePassword(
          _currentPwController.text,
          _newPwController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      AppSnackBar.success(context, 'Đổi mật khẩu thành công');
      context.pop();
    } else {
      AppSnackBar.error(context, message);
    }
  }

  /// Password strength: 0-4 based on criteria met
  int _strength(String pw) {
    if (pw.isEmpty) { return 0; }
    int score = 0;
    if (pw.length >= 8) { score++; }
    if (RegExp(r'[A-Z]').hasMatch(pw) &&
        RegExp(r'[a-z]').hasMatch(pw)) { score++; }
    if (RegExp(r'[0-9]').hasMatch(pw)) { score++; }
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pw)) { score++; }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final strengthLevel = _strength(_newPwController.text);

    return Scaffold(
      body: Column(
        children: [
          // ── Custom gradient header ──────────────────────────
          _buildHeader(context, topPad, isDark),

          // ── Scrollable form body ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Form card ──────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(
                            AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                                alpha: isDark ? 0.30 : 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Mật khẩu hiện tại
                          _buildLabel('Mật khẩu hiện tại'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _currentPwController,
                            obscureText: !_showCurrent,
                            decoration: _pwDecoration(
                              context: context,
                              hintText:
                                  'Nhập mật khẩu hiện tại',
                              visible: _showCurrent,
                              onToggle: () => setState(() =>
                                  _showCurrent = !_showCurrent),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Vui lòng nhập mật khẩu hiện tại';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Mật khẩu mới
                          _buildLabel('Mật khẩu mới'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _newPwController,
                            obscureText: !_showNew,
                            onChanged: (_) => setState(() {}),
                            decoration: _pwDecoration(
                              context: context,
                              hintText: 'Nhập mật khẩu mới',
                              visible: _showNew,
                              onToggle: () => setState(
                                  () => _showNew = !_showNew),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Vui lòng nhập mật khẩu mới';
                              }
                              if (v.length < 8) {
                                return 'Mật khẩu cần ít nhất 8 ký tự';
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(v)) {
                                return 'Mật khẩu cần có ít nhất 1 chữ hoa';
                              }
                              if (!RegExp(r'[a-z]').hasMatch(v)) {
                                return 'Mật khẩu cần có ít nhất 1 chữ thường';
                              }
                              if (!RegExp(r'[0-9]').hasMatch(v)) {
                                return 'Mật khẩu cần có ít nhất 1 số';
                              }
                              if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]')
                                  .hasMatch(v)) {
                                return 'Mật khẩu cần có ít nhất 1 ký tự đặc biệt';
                              }
                              return null;
                            },
                          ),

                          // Strength indicator
                          const SizedBox(height: 10),
                          _StrengthBar(
                              strength: strengthLevel,
                              password:
                                  _newPwController.text),

                          const SizedBox(height: 20),

                          // Xác nhận mật khẩu mới
                          _buildLabel('Xác nhận mật khẩu mới'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPwController,
                            obscureText: !_showConfirm,
                            decoration: _pwDecoration(
                              context: context,
                              hintText:
                                  'Nhập lại mật khẩu mới',
                              visible: _showConfirm,
                              onToggle: () => setState(() =>
                                  _showConfirm = !_showConfirm),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Vui lòng xác nhận mật khẩu';
                              }
                              if (v != _newPwController.text) {
                                return 'Mật khẩu không khớp';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Hint row
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: colors.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Mật khẩu cần ít nhất 8 ký tự, bao gồm '
                                  'chữ hoa, chữ thường, số và ký tự đặc biệt',
                                  style:
                                      GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.04, end: 0),

                    const SizedBox(height: 28),

                    // ── Submit button ──────────────────────
                    _GradientButton(
                      onPressed: _isLoading ? null : _submit,
                      isLoading: _isLoading,
                      label: 'Đổi mật khẩu',
                    )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.06, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double topPad, bool isDark) {
    final headerGradient = isDark
        ? const [AppColors.darkBg, AppColors.darkBorder]
        : const [AppColors.jade500, _jadeMidLight];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPad + 12,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.4, -1),
          end: const Alignment(0.6, 1),
          colors: headerGradient,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Back row + title
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Bảo mật tài khoản',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Large lock icon in header
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                curve: Curves.elasticOut,
                duration: 500.ms,
              ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04, end: 0);
  }

  Widget _buildLabel(String text) {
    final colors = context.colors;
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    );
  }

  InputDecoration _pwDecoration({
    required BuildContext context,
    required String hintText,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hintText,
      hintStyle:
          GoogleFonts.beVietnamPro(color: colors.textTertiary),
      prefixIcon: Icon(
        Icons.lock_outline_rounded,
        color: colors.textSecondary,
        size: 20,
      ),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          visible
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          color: colors.textTertiary,
          size: 20,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
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
        borderSide: BorderSide(
            color: colors.brand, width: 1.5),
      ),
    );
  }
}

// ─── Password Strength Bar ────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  final int strength; // 0-4
  final String password;

  const _StrengthBar({
    required this.strength,
    required this.password,
  });

  Color _segmentColor(BuildContext context, int index) {
    final colors = context.colors;
    if (password.isEmpty || strength == 0) {
      return colors.borderDefault;
    }
    if (index >= strength) return colors.borderDefault;
    switch (strength) {
      case 1:
        return colors.error; // weak
      case 2:
        return colors.warning; // ok
      case 3:
        return colors.brand; // good
      case 4:
        return colors.success; // strong
      default:
        return colors.borderDefault;
    }
  }

  String get _label {
    if (password.isEmpty) return '';
    switch (strength) {
      case 1:
        return 'Yếu';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Khá tốt';
      case 4:
        return 'Mạnh';
      default:
        return '';
    }
  }

  Color _labelColor(BuildContext context) {
    final colors = context.colors;
    switch (strength) {
      case 1:
        return colors.error;
      case 2:
        return colors.warning;
      case 3:
        return colors.brand;
      case 4:
        return colors.success;
      default:
        return colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: _segmentColor(context, i),
                  borderRadius:
                      BorderRadius.circular(AppRadius.full),
                ),
              ),
            );
          }),
        ),
        if (password.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _labelColor(context),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Gradient Button ─────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : LinearGradient(
                  colors: [colors.brand, AppColors.jade300],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: onPressed == null ? colors.textTertiary : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}
