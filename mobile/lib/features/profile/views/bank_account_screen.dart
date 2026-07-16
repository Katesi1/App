import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/bank_account_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/bank_controller.dart';

/// Màn "Tài khoản nhận tiền" của OWNER (BE §3.3). Tạo/sửa phải qua ADMIN
/// duyệt mới có hiệu lực. Render 4 trạng thái: none / pending / approved /
/// rejected.
class BankAccountScreen extends ConsumerStatefulWidget {
  const BankAccountScreen({super.key});

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _binCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();

  bool _editing = false;
  bool _prefilled = false;
  bool _submitting = false;

  @override
  void dispose() {
    _binCtrl.dispose();
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  void _prefill(BankStatusResult data) {
    final d = data.pending ?? data.current;
    if (d != null) {
      _binCtrl.text = d.bankBin;
      _nameCtrl.text = d.bankName ?? '';
      _numberCtrl.text = d.bankAccountNumber;
      _holderCtrl.text = d.bankAccountName;
    }
    // `none` → mở form ngay; các trạng thái khác → hiện thẻ hiển thị trước.
    _editing = data.isNone;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final detail = BankDetail(
      bankBin: _binCtrl.text.trim(),
      bankName: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      bankAccountNumber: _numberCtrl.text.trim(),
      bankAccountName: _holderCtrl.text.trim(),
    );
    final (ok, message) =
        await ref.read(bankActionsProvider.notifier).submit(detail);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      setState(() => _editing = false);
      AppSnackBar.success(context, message);
    } else {
      AppSnackBar.error(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(bankStatusProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(title: const Text('Tài khoản nhận tiền')),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(bankStatusProvider),
        ),
        data: (data) {
          if (!_prefilled) {
            _prefilled = true;
            _prefill(data);
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _StatusBanner(data: data),
              const SizedBox(height: AppSpacing.md),
              if (!_editing) ...[
                _AccountCard(
                  detail: data.pending ?? data.current,
                  isPending: data.isPending,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(_editButtonLabel(data)),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ] else
                _buildForm(context, data),
            ],
          );
        },
      ),
    );
  }

  String _editButtonLabel(BankStatusResult data) {
    if (data.isRejected) return 'Gửi lại';
    if (data.isPending) return 'Sửa thông tin đã gửi';
    return 'Sửa tài khoản';
  }

  Widget _buildForm(BuildContext context, BankStatusResult data) {
    final colors = context.colors;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nhập thông tin tài khoản ngân hàng nhận tiền cọc từ khách. '
            'Thông tin sẽ được quản trị viên duyệt trước khi có hiệu lực.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _field(
            context,
            controller: _binCtrl,
            label: 'Mã ngân hàng (BIN NAPAS) *',
            hint: '6 chữ số, vd 970436',
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.length != 6) return 'BIN phải đúng 6 chữ số';
              return null;
            },
          ),
          _field(
            context,
            controller: _nameCtrl,
            label: 'Tên ngân hàng',
            hint: 'Tuỳ chọn, vd Vietcombank',
          ),
          _field(
            context,
            controller: _numberCtrl,
            label: 'Số tài khoản *',
            hint: '6–20 chữ số',
            keyboardType: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(20),
            ],
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.length < 6 || s.length > 20) {
                return 'Số tài khoản 6–20 chữ số';
              }
              return null;
            },
          ),
          _field(
            context,
            controller: _holderCtrl,
            label: 'Chủ tài khoản *',
            hint: 'VD NGUYEN VAN A',
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              if ((v?.trim() ?? '').isEmpty) return 'Nhập tên chủ tài khoản';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: colors.brand,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Gửi duyệt'),
          ),
          if (!data.isNone) ...[
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed:
                  _submitting ? null : () => setState(() => _editing = false),
              child: const Text('Huỷ'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        textCapitalization: textCapitalization,
        validator: validator,
        style: GoogleFonts.beVietnamPro(
          fontSize: 15,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: colors.bgSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colors.borderDefault),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: colors.borderDefault),
          ),
        ),
      ),
    );
  }
}

/// Banner trạng thái theo `bankStatus`.
class _StatusBanner extends StatelessWidget {
  final BankStatusResult data;

  const _StatusBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg, icon, text) = switch (data.status) {
      'pending' => (
          colors.warningBg,
          colors.warning,
          Icons.hourglass_top_rounded,
          'Đang chờ quản trị viên duyệt. Tài khoản chưa có hiệu lực.',
        ),
      'approved' => (
          colors.successBg,
          colors.success,
          Icons.verified_rounded,
          'Đã duyệt — đang dùng để nhận tiền cọc từ khách.',
        ),
      'rejected' => (
          colors.errorBg,
          colors.error,
          Icons.error_outline_rounded,
          data.rejectReason?.trim().isNotEmpty == true
              ? 'Bị từ chối: ${data.rejectReason}'
              : 'Tài khoản bị từ chối. Vui lòng gửi lại.',
        ),
      _ => (
          colors.bgSurfaceContainer,
          colors.textSecondary,
          Icons.account_balance_outlined,
          'Chưa có tài khoản nhận tiền. Thêm để nhận cọc từ khách.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ hiển thị thông tin tài khoản (current hoặc pending).
class _AccountCard extends StatelessWidget {
  final BankDetail? detail;
  final bool isPending;

  const _AccountCard({required this.detail, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (detail == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPending ? 'THÔNG TIN ĐANG CHỜ DUYỆT' : 'TÀI KHOẢN ĐANG DÙNG',
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _row(
              context,
              'Ngân hàng',
              detail!.bankName?.isNotEmpty == true
                  ? '${detail!.bankName} (${detail!.bankBin})'
                  : detail!.bankBin),
          _row(context, 'Số tài khoản', detail!.bankAccountNumber),
          _row(context, 'Chủ tài khoản', detail!.bankAccountName),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: colors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
