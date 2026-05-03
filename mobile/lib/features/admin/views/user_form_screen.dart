import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/phone_input.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/user_controller.dart';

// ─── Màn hình xem + quản lý nhân viên ────────────────────────────────────────
// - userId != null → xem thông tin, gán vai trò, kích hoạt/vô hiệu hoá
// - userId == null → tạo nhân viên mới (chỉ cần tên, SĐT, vai trò)
class UserFormScreen extends ConsumerStatefulWidget {
  final String? userId;
  const UserFormScreen({super.key, this.userId});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  // Create form
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  // Shared state (2=SALE, 1=OWNER)
  int _role = 2;
  bool _isActive = true;
  bool _isLoading = false;

  // Loaded user data (edit mode)
  String _userName = '';
  String _userPhone = '';
  String _userEmail = '';

  bool get _isEdit => widget.userId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final result =
        await ref.read(userRepositoryProvider).getUser(widget.userId!);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success && result.data != null) {
      final u = result.data!;
      setState(() {
        _userName = u.name;
        _userPhone = u.phone;
        _userEmail = u.email ?? '';
        _role = u.role;
        _isActive = u.isActive;
      });
    } else {
      if (mounted) AppSnackBar.error(context, result.message);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    final ok = await ref.read(userActionsProvider.notifier).update(
      widget.userId!,
      {'role': _role, 'isActive': _isActive},
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      AppSnackBar.success(context, 'Đã cập nhật thành công');
      context.pop();
    } else {
      final err = ref.read(userActionsProvider);
      AppSnackBar.error(
        context,
        err.hasError ? err.error.toString() : 'Có lỗi xảy ra',
      );
    }
  }

  Future<void> _createStaff() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(userActionsProvider.notifier).create({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'role': _role,
    });
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      AppSnackBar.success(context, 'Tạo tài khoản thành công');
      context.pop();
    } else {
      final err = ref.read(userActionsProvider);
      AppSnackBar.error(
        context,
        err.hasError ? err.error.toString() : 'Có lỗi xảy ra',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _isEdit && _userName.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết nhân viên')),
        body: const LoadingWidget(),
      );
    }
    return _isEdit ? _buildDetailView() : _buildCreateView();
  }

  // ── Detail view (xem thông tin + gán vai trò) ──────────────────────────────
  Widget _buildDetailView() {
    final colors = context.colors;
    final roleColor = AppHelpers.roleColor(_role);
    return Scaffold(
      backgroundColor: colors.bgCanvas,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header với avatar ──────────────────
          SliverToBoxAdapter(
            child: _buildProfileHeader(roleColor),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Thông tin cá nhân (read-only) ────────
                  _SectionTitle('Thông tin tài khoản'),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Họ tên',
                        value: _userName.isNotEmpty ? _userName : '-',
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Số điện thoại',
                        value: _userPhone.isNotEmpty ? _userPhone : '-',
                      ),
                      if (_userEmail.isNotEmpty) ...[
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _userEmail,
                        ),
                      ],
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.06, end: 0),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Gán vai trò ──────────────────────────
                  _SectionTitle('Vai trò'),
                  const SizedBox(height: 4),
                  Text(
                    'Chỉ có thể gán vai trò Sale hoặc Chủ nhà',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _RoleCard(
                        label: 'Sale',
                        value: 2,
                        icon: Icons.headset_mic_outlined,
                        color: colors.brand,
                        selected: _role == 2,
                        onTap: () => setState(() => _role = 2),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _RoleCard(
                        label: 'Chủ nhà',
                        value: 1,
                        icon: Icons.home_outlined,
                        color: colors.warning,
                        selected: _role == 1,
                        onTap: () => setState(() => _role = 1),
                      ),
                    ],
                  ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Trạng thái tài khoản ─────────────────
                  _SectionTitle('Trạng thái tài khoản'),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isActive
                                    ? colors.success
                                    : colors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isActive
                                        ? 'Tài khoản đang hoạt động'
                                        : 'Tài khoản đã vô hiệu hoá',
                                    style: GoogleFonts.beVietnamPro(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _isActive
                                        ? 'Nhân viên có thể đăng nhập và sử dụng'
                                        : 'Nhân viên không thể đăng nhập',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              activeTrackColor: colors.success,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Save button ──────────────────────────
                  _SaveButton(
                    isLoading: _isLoading,
                    label: 'Lưu thay đổi',
                    onTap: _saveChanges,
                  ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Color roleColor) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.jade900, AppColors.jade300],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: topPadding + 8),
          // Back button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Chi tiết nhân viên',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _userName.isNotEmpty ? _userName : '-',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              AppHelpers.roleLabel(_role),
              style: GoogleFonts.beVietnamPro(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Create view (tạo nhân viên mới) ───────────────────────────────────────
  Widget _buildCreateView() {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: Text(
          'Thêm nhân viên',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Form fields ──────────────────────────────
              _InfoCard(
                children: [
                  _FormField(
                    controller: _nameCtrl,
                    label: 'Họ tên *',
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Nhập họ tên' : null,
                  ),
                  const _Divider(),
                  _FormField(
                    controller: _phoneCtrl,
                    label: 'Số điện thoại *',
                    hintText: '0xxxxxxxxx (10 số)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: PhoneInput.formatters,
                    validator: PhoneInput.validate,
                  ),
                  const _Divider(),
                  _FormField(
                    controller: _passwordCtrl,
                    label: 'Mật khẩu *',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Nhập mật khẩu';
                      if (v!.length < 6) {
                        return 'Mật khẩu tối thiểu 6 ký tự';
                      }
                      return null;
                    },
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.xl),

              // ── Role selector ────────────────────────────
              _SectionTitle('Vai trò *'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _RoleCard(
                    label: 'Sale',
                    value: 2,
                    icon: Icons.headset_mic_outlined,
                    color: colors.brand,
                    selected: _role == 2,
                    onTap: () => setState(() => _role = 2),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _RoleCard(
                    label: 'Chủ nhà',
                    value: 1,
                    icon: Icons.home_outlined,
                    color: colors.warning,
                    selected: _role == 1,
                    onTap: () => setState(() => _role = 1),
                  ),
                ],
              ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.xl),

              _SaveButton(
                isLoading: _isLoading,
                label: 'Tạo tài khoản',
                onTap: _createStaff,
              ).animate(delay: 200.ms).fadeIn(duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        value == '-' ? colors.textTertiary : colors.textPrimary,
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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.inputFormatters,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: colors.brand),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          counterText: '',
          labelStyle: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: colors.textSecondary,
          ),
        ),
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        validator: validator,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Divider(height: 1, color: colors.borderDefault, indent: 52);
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : colors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? color : colors.borderDefault,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.30 : 0.03),
                      blurRadius: 4,
                    ),
                  ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? color.withValues(alpha: 0.15)
                      : colors.bgSurfaceContainer,
                ),
                child: Icon(
                  icon,
                  color: selected ? color : colors.textTertiary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: selected ? color : colors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback onTap;

  const _SaveButton({
    required this.isLoading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: isLoading
          ? Center(
              child: CircularProgressIndicator(color: colors.brand),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.brandLight, colors.brand],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: colors.brand.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
