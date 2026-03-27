import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  /// null = chưa chọn, user phải chọn trước khi sang form
  UserRole? _selectedRole;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await ref.read(authProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _selectedRole!.value,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
    }
  }

  Future<void> _registerWithGoogle() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn loại tài khoản trước'),
          backgroundColor: AppColors.amber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref
        .read(authProvider.notifier)
        .signInWithGoogle(role: _selectedRole!.value);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sm)),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Ocean gradient header ────────────────────────────
            _buildHeader(),

            // ── Body ─────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tạo tài khoản',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chọn loại tài khoản và điền thông tin',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Role selection ─────────────────────────────
                  _RoleSelector(
                    selectedRole: _selectedRole,
                    onChanged: (role) =>
                        setState(() => _selectedRole = role),
                  ),

                  const SizedBox(height: 24),

                  // ── Form (hiện khi đã chọn role) ──────────────
                  if (_selectedRole != null) ...[
                    _buildForm(),
                    const SizedBox(height: 20),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildGoogleButton(),
                  ],

                  const SizedBox(height: 24),

                  // ── Link về login ──────────────────────────────
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text(
                            'Đăng nhập',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.oceanMid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 32,
        left: 28,
        right: 28,
        bottom: 40,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.4, -1),
          end: Alignment(0.4, 1),
          colors: [AppColors.oceanDeep, AppColors.ocean],
        ),
      ),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -70,
            bottom: -100,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.go('/login'),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                  children: const [
                    TextSpan(text: 'Halong'),
                    TextSpan(
                      text: '24h',
                      style: TextStyle(color: AppColors.gold),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1, end: 0),
              const SizedBox(height: 6),
              Text(
                'Đăng ký tài khoản mới',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Họ tên
          _FieldLabel('HỌ VÀ TÊN'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.beVietnamPro(fontSize: 15),
            decoration: _inputDecoration(
              hint: 'Nguyễn Văn A',
              icon: Icons.person_outline_rounded,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nhập họ tên';
              if (v.trim().length < 2) return 'Tối thiểu 2 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Số điện thoại
          _FieldLabel('SỐ ĐIỆN THOẠI'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.beVietnamPro(fontSize: 15),
            decoration: _inputDecoration(
              hint: '0912345678',
              icon: Icons.phone_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nhập số điện thoại';
              final phone = v.trim();
              if (!RegExp(r'^0\d{9,10}$').hasMatch(phone)) {
                return 'Số điện thoại không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Mật khẩu
          _FieldLabel('MẬT KHẨU'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.beVietnamPro(fontSize: 15),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.slate,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Nhập mật khẩu';
              if (v.length < 6) return 'Tối thiểu 6 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Xác nhận mật khẩu
          _FieldLabel('XÁC NHẬN MẬT KHẨU'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordCtrl,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _register(),
            style: GoogleFonts.beVietnamPro(fontSize: 15),
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.slate,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Nhập lại mật khẩu';
              if (v != _passwordCtrl.text) return 'Mật khẩu không khớp';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Register button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      height: 52,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.ocean,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('register-btn'),
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.oceanMid, AppColors.ocean],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ocean.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _register,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Center(
                            child: Text(
                              'Đăng ký',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'hoặc',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: AppColors.slate,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _registerWithGoogle,
      icon: SvgPicture.asset(
        'assets/images/google_logo.svg',
        width: 20,
        height: 20,
      ),
      label: Text(
        'Đăng ký bằng Google',
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.slate),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide:
            const BorderSide(color: AppColors.oceanMid, width: 1.5),
      ),
    );
  }
}

// ─── Role Selector ──────────────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
  final UserRole? selectedRole;
  final ValueChanged<UserRole> onChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleCard(
            role: UserRole.customer,
            icon: Icons.luggage_outlined,
            title: 'Khách hàng',
            subtitle: 'Tìm & đặt phòng',
            isSelected: selectedRole == UserRole.customer,
            onTap: () => onChanged(UserRole.customer),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleCard(
            role: UserRole.staff,
            icon: Icons.apartment_outlined,
            title: 'Nhân viên',
            subtitle: 'Quản lý homestay',
            isSelected: selectedRole == UserRole.staff,
            onTap: () => onChanged(UserRole.staff),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.ocean : AppColors.border;
    final bgColor = isSelected
        ? AppColors.ocean.withValues(alpha: 0.05)
        : AppColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.ocean.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.ocean : AppColors.slate,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.ocean : AppColors.navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                color: AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.ocean : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.ocean : AppColors.slate,
                  width: isSelected ? 0 : 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Field Label ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
        letterSpacing: 0.5,
      ),
    );
  }
}
