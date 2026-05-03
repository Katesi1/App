import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/phone_input.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/widgets/loading_widget.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7 — chưa có token sẵn
const _jadeMidLight = Color(0xFF1B7E94);

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() =>
      _PersonalInfoScreenState();
}

class _PersonalInfoScreenState
    extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _dobController;

  // 0=MALE, 1=FEMALE, 2=OTHER
  int _gender = 0;
  DateTime? _dateOfBirth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController =
        TextEditingController(text: user?.phone ?? '');
    _emailController =
        TextEditingController(text: user?.email ?? '');
    _gender = user?.gender ?? 0;

    if (user?.dateOfBirth != null &&
        user!.dateOfBirth!.isNotEmpty) {
      try {
        _dateOfBirth = DateTime.parse(user.dateOfBirth!);
        _dobController = TextEditingController(
          text: DateFormat('dd/MM/yyyy').format(_dateOfBirth!),
        );
      } catch (_) {
        _dobController = TextEditingController();
      }
    } else {
      _dobController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final colors = context.colors;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: colors.brand,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobController.text =
            DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'gender': _gender,
    };

    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      data['email'] = email;
    }

    if (_dateOfBirth != null) {
      data['dateOfBirth'] = _dateOfBirth!.toIso8601String();
    }

    final (success, message) =
        await ref.read(authProvider.notifier).updateProfile(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      AppSnackBar.success(context, 'Cập nhật thông tin thành công');
      context.pop();
    } else {
      AppSnackBar.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.isAdmin ?? false;
    final initial = _nameController.text.isNotEmpty
        ? _nameController.text[0].toUpperCase()
        : 'U';

    return Scaffold(
      body: Column(
        children: [
          // ── Custom gradient header ─────────────────────────────
          _buildHeader(context, topPad, initial, isDark),

          // ── Scrollable form body ───────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Group: Thông tin cơ bản ──────────────
                    _GroupCard(
                      isDark: isDark,
                      label: 'THÔNG TIN CƠ BẢN',
                      child: Column(
                        children: [
                          _buildFieldRow(
                            label: 'Họ và tên',
                            field: TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration(
                                context: context,
                                hintText: 'Nhập họ và tên',
                                prefixIcon:
                                    Icons.person_outline_rounded,
                              ),
                              validator: (v) {
                                if (v == null ||
                                    v.trim().isEmpty) {
                                  return 'Vui lòng nhập họ tên';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldRow(
                            label: 'Số điện thoại',
                            field: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: PhoneInput.formatters,
                              decoration: _inputDecoration(
                                context: context,
                                hintText: '0xxxxxxxxx (10 số)',
                                prefixIcon: Icons.phone_outlined,
                              ),
                              validator: PhoneInput.validate,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldRow(
                            label: 'Email',
                            field: TextFormField(
                              controller: _emailController,
                              enabled: isAdmin,
                              keyboardType:
                                  TextInputType.emailAddress,
                              decoration: _inputDecoration(
                                context: context,
                                hintText: isAdmin
                                    ? 'Nhập email'
                                    : _emailController.text.isEmpty
                                        ? 'Chưa có email'
                                        : '',
                                prefixIcon: Icons.email_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.04, end: 0),

                    const SizedBox(height: 16),

                    // ── Group: Cá nhân ────────────────────────
                    _GroupCard(
                      isDark: isDark,
                      label: 'CÁ NHÂN',
                      child: Column(
                        children: [
                          _buildFieldRow(
                            label: 'Giới tính',
                            field: Row(
                              children: [
                                _GenderChip(
                                  label: 'Nam',
                                  isSelected: _gender == 0,
                                  onTap: () => setState(
                                      () => _gender = 0),
                                ),
                                const SizedBox(width: 10),
                                _GenderChip(
                                  label: 'Nữ',
                                  isSelected: _gender == 1,
                                  onTap: () => setState(
                                      () => _gender = 1),
                                ),
                                const SizedBox(width: 10),
                                _GenderChip(
                                  label: 'Khác',
                                  isSelected: _gender == 2,
                                  onTap: () => setState(
                                      () => _gender = 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFieldRow(
                            label: 'Ngày sinh',
                            field: TextFormField(
                              controller: _dobController,
                              readOnly: true,
                              onTap: _pickDate,
                              decoration: _inputDecoration(
                                context: context,
                                hintText: 'Chọn ngày sinh',
                                prefixIcon:
                                    Icons.calendar_today_outlined,
                                suffixIcon:
                                    Icons.chevron_right_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.04, end: 0),

                    const SizedBox(height: 28),

                    // ── Save button ───────────────────────────
                    _GradientButton(
                      onPressed: _isLoading ? null : _save,
                      isLoading: _isLoading,
                      label: 'Lưu thay đổi',
                    )
                        .animate(delay: 200.ms)
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

  Widget _buildHeader(BuildContext context, double topPad,
      String initial, bool isDark) {
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
          // Back row
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
                'Thông tin cá nhân',
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

          // Avatar centered
          _HeaderAvatar(initial: initial),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04, end: 0);
  }

  Widget _buildFieldRow({
    required String label,
    required Widget field,
  }) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String hintText,
    required IconData prefixIcon,
    String? prefixText,
    IconData? suffixIcon,
  }) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hintText,
      hintStyle:
          GoogleFonts.beVietnamPro(color: colors.textTertiary),
      prefixIcon:
          Icon(prefixIcon, color: colors.textSecondary, size: 20),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.beVietnamPro(
        color: colors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: colors.textTertiary, size: 22)
          : null,
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

// ─── Header Avatar ───────────────────────────────────────────────────────────

class _HeaderAvatar extends StatelessWidget {
  final String initial;
  const _HeaderAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Gradient ring
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colors.brand, AppColors.gold500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // White gap
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        // Inner avatar
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.jade500, _jadeMidLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 32,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Group Card ──────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final Widget child;

  const _GroupCard({
    required this.isDark,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
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

// ─── Gender Chip ─────────────────────────────────────────────────────────────

class _GenderChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [colors.brand, AppColors.jade300],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius:
              BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? colors.brand
                : colors.borderDefault,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.w400,
            color: isSelected
                ? Colors.white
                : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
