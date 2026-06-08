import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/phone_input.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/staff_controller.dart';
import '../data/models/staff_invite.dart';

/// Public screen — không yêu cầu login. Có 2 entry:
/// 1. Deep link `https://halong24h.com/staff/accept?token=xxx` → token prefilled
/// 2. User mở app → bấm "Tôi có mã nhân viên" → nhập short code thủ công
class InviteAcceptScreen extends ConsumerStatefulWidget {
  /// Token đầy đủ (64 hex) hoặc short code (HL-XXXXXX) — nếu null thì user nhập tay.
  final String? initialToken;

  const InviteAcceptScreen({super.key, this.initialToken});

  @override
  ConsumerState<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends ConsumerState<InviteAcceptScreen> {
  final _tokenCtrl = TextEditingController();

  StaffInvitePreview? _preview;
  String? _verifiedToken;
  bool _verifying = false;
  bool _accepting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      _tokenCtrl.text = widget.initialToken!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyToken();
      });
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mã mời');
      return;
    }

    setState(() {
      _verifying = true;
      _errorMessage = null;
    });

    final repo = ref.read(staffRepositoryProvider);
    final result = await repo.verifyInvite(token);

    if (!mounted) return;

    if (result.success && result.data != null) {
      setState(() {
        _verifying = false;
        _preview = result.data;
        _verifiedToken = token;
      });
    } else {
      setState(() {
        _verifying = false;
        _errorMessage = result.message;
      });
    }
  }

  Future<void> _acceptWithGoogle() async {
    if (_verifiedToken == null) return;
    setState(() {
      _accepting = true;
      _errorMessage = null;
    });

    final (idToken, gErr) =
        await ref.read(authProvider.notifier).getGoogleIdToken();

    if (!mounted) return;
    if (idToken == null) {
      setState(() {
        _accepting = false;
        if (gErr != null) _errorMessage = gErr;
      });
      return;
    }

    final repo = ref.read(staffRepositoryProvider);
    final outcome = await repo.acceptWithGoogle(
      token: _verifiedToken!,
      idToken: idToken,
    );

    if (!mounted) return;
    _handleAcceptOutcome(outcome);
  }

  Future<void> _acceptWithPassword({
    required String name,
    required String password,
    String? phone,
  }) async {
    if (_verifiedToken == null) return;
    setState(() {
      _accepting = true;
      _errorMessage = null;
    });

    final repo = ref.read(staffRepositoryProvider);
    final outcome = await repo.acceptWithPassword(
      token: _verifiedToken!,
      name: name,
      password: password,
      phone: phone,
    );

    if (!mounted) return;
    _handleAcceptOutcome(outcome);
  }

  void _handleAcceptOutcome(AcceptInviteOutcome outcome) {
    switch (outcome) {
      case AcceptInviteSuccess(:final user):
        ref.read(authProvider.notifier).applyExternalLogin(user);
        AppSnackBar.success(context, 'Chấp nhận lời mời thành công');
      case AcceptInviteFailure(:final message):
        setState(() {
          _accepting = false;
          _errorMessage = message;
        });
    }
  }

  Future<void> _openPasswordSheet() async {
    if (_preview == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _PasswordSheet(
        email: _preview!.email,
        onSubmit: ({required name, required password, phone}) async {
          Navigator.pop(sheetContext);
          await _acceptWithPassword(
            name: name,
            password: password,
            phone: phone,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Chấp nhận lời mời',
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _preview == null ? _buildEnterToken() : _buildPreview(),
        ),
      ),
    );
  }

  // ── State 1: nhập mã ────────────────────────────────────────────────────────
  Widget _buildEnterToken() {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Nhập mã mời từ chủ homestay',
          style: GoogleFonts.beVietnamPro(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Mã có dạng HL-XXXXXX, được gửi trong email mời.',
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _tokenCtrl,
          enabled: !_verifying,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
          ],
          style: GoogleFonts.firaCode(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            letterSpacing: 1.5,
          ),
          decoration: InputDecoration(
            labelText: 'Mã mời',
            hintText: 'HL-XXXXXX',
            prefixIcon: const Icon(Icons.qr_code_2_rounded),
            errorText: _errorMessage,
          ),
          onSubmitted: (_) => _verifyToken(),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _verifying ? null : _verifyToken,
          style: FilledButton.styleFrom(
            backgroundColor: colors.brand,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _verifying
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Tiếp tục'),
        ),
      ],
    );
  }

  // ── State 2: confirm + chọn cách đăng ký ────────────────────────────────────
  Widget _buildPreview() {
    final colors = context.colors;
    final preview = _preview!;
    final dateFmt = DateFormat('dd/MM/yyyy');

    if (!preview.canAccept) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.error_outline_rounded,
          message: 'Lời mời không khả dụng',
          subMessage: 'Trạng thái: ${preview.status.label}',
          onAction: () => setState(() {
            _preview = null;
            _verifiedToken = null;
          }),
          actionLabel: 'Nhập mã khác',
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _OwnerCard(preview: preview),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Hết hạn ${dateFmt.format(preview.expiresAt)}',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: colors.error,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          FilledButton.icon(
            onPressed: _accepting ? null : _acceptWithGoogle,
            style: FilledButton.styleFrom(
              backgroundColor: colors.brand,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _accepting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.g_mobiledata_rounded, size: 24),
            label: Text(
              _accepting ? 'Đang xử lý…' : 'Đăng nhập với Google',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _accepting ? null : _openPasswordSheet,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: colors.brand),
            ),
            icon: Icon(Icons.email_outlined, color: colors.brand),
            label: Text(
              'Đăng ký bằng email/mật khẩu',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.brand,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Email Google bạn dùng phải khớp với email được mời (${preview.email}).',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  final StaffInvitePreview preview;
  const _OwnerCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child:
                preview.ownerAvatar != null && preview.ownerAvatar!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: preview.ownerAvatar!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        memCacheWidth: 160,
                        placeholder: (_, __) => _avatarPlaceholder(colors),
                        errorWidget: (_, __, ___) => _avatarPlaceholder(colors),
                      )
                    : _avatarPlaceholder(colors),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            preview.ownerName.isEmpty ? 'Chủ homestay' : preview.ownerName,
            style: GoogleFonts.beVietnamPro(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          if (preview.homestayName != null &&
              preview.homestayName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              preview.homestayName!,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Mời bạn làm nhân viên',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.brand,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            preview.email,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(AppColorScheme colors) => Container(
        width: 80,
        height: 80,
        color: colors.bgCanvas,
        child: Icon(Icons.person, size: 40, color: colors.textSecondary),
      );
}

// ── Sheet: Đăng ký bằng email/password ────────────────────────────────────────

typedef _PasswordSubmit = Future<void> Function({
  required String name,
  required String password,
  String? phone,
});

class _PasswordSheet extends StatefulWidget {
  final String email;
  final _PasswordSubmit onSubmit;

  const _PasswordSheet({required this.email, required this.onSubmit});

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      name: _nameCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Đăng ký với ${widget.email}',
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập họ tên'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon:
                      Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (v.length < 8) return 'Tối thiểu 8 ký tự';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: PhoneInput.formatters,
              validator: PhoneInput.validateOptional,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại (tuỳ chọn)',
                hintText: '0xxxxxxxxx',
                prefixIcon: Icon(Icons.phone_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Hoàn tất đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}
