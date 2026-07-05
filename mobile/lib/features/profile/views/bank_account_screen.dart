import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/bank_controller.dart';
import '../data/models/bank_account.dart';
import '../data/vn_banks.dart';

/// OWNER cấu hình tài khoản ngân hàng nhận tiền cọc. Mọi thay đổi phải chờ
/// admin DUYỆT mới dùng để sinh VietQR. Endpoint: GET/PUT `/users/me/bank`.
class BankAccountScreen extends ConsumerStatefulWidget {
  const BankAccountScreen({super.key});

  @override
  ConsumerState<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends ConsumerState<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  VnBank? _selectedBank;
  bool? _editing; // null = chưa quyết định; true = form; false = xem trạng thái
  bool _submitting = false;

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  /// Vào chế độ nhập, prefill từ tài khoản hiện có (nếu sửa/gửi lại).
  void _startEdit(BankInfo? prefill) {
    _accountNumberController.text = prefill?.bankAccountNumber ?? '';
    _accountNameController.text = prefill?.bankAccountName ?? '';
    _selectedBank = bankByBin(prefill?.bankBin) ??
        ((prefill?.bankBin.isNotEmpty ?? false)
            ? VnBank(
                bin: prefill!.bankBin,
                shortName: prefill.bankName ?? prefill.bankBin,
                name: prefill.bankName ?? '',
              )
            : null);
    setState(() => _editing = true);
  }

  Future<void> _pickBank() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<VnBank>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BankPickerSheet(),
    );
    if (picked != null) {
      setState(() => _selectedBank = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      AppSnackBar.error(context, 'Vui lòng chọn ngân hàng');
      return;
    }

    setState(() => _submitting = true);

    final info = BankInfo(
      bankBin: _selectedBank!.bin,
      bankName: _selectedBank!.shortName,
      bankAccountNumber: _accountNumberController.text.trim(),
      bankAccountName: _accountNameController.text.trim(),
    );

    final result = await ref.read(bankRepositoryProvider).submitBank(info);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.success) {
      ref.invalidate(bankStatusProvider);
      // Đồng bộ badge + gate tạo phòng (bankStatus trong profile).
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      setState(() => _editing = false);
      AppSnackBar.success(context, 'Đã gửi tài khoản, chờ admin duyệt');
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bankAsync = ref.watch(bankStatusProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tài khoản nhận tiền',
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bankStatusProvider);
          await ref.read(bankStatusProvider.future);
        },
        child: bankAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorStateWidget(
            message: e.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.invalidate(bankStatusProvider),
          ),
          data: (result) {
            final editing = _editing ?? result.isNone;
            return editing ? _buildForm(result) : _buildStatusView(result);
          },
        ),
      ),
    );
  }

  // ── View mode: hiển thị trạng thái duyệt ────────────────────────────────
  Widget _buildStatusView(BankStatusResult result) {
    final colors = context.colors;
    final info = result.displayInfo;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(colors: colors),
          const SizedBox(height: 16),
          _StatusBanner(status: result.status, reason: result.rejectReason),
          const SizedBox(height: 16),
          if (info != null) _AccountCard(info: info),
          const SizedBox(height: 24),
          _PrimaryButton(
            label: switch (result.status) {
              BankApprovalStatus.approved => 'Sửa tài khoản',
              BankApprovalStatus.rejected => 'Gửi lại',
              _ => 'Cập nhật tài khoản',
            },
            onPressed:
                result.isPending ? null : () => _startEdit(result.displayInfo),
          ),
          if (result.isPending) ...[
            const SizedBox(height: 10),
            Text(
              'Tài khoản đang chờ duyệt — bạn có thể sửa sau khi admin phản hồi.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: colors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Edit mode: form nhập ────────────────────────────────────────────────
  Widget _buildForm(BankStatusResult result) {
    final colors = context.colors;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBanner(colors: colors),
            if (result.isRejected && result.rejectReason != null) ...[
              const SizedBox(height: 16),
              _StatusBanner(status: result.status, reason: result.rejectReason),
            ],
            const SizedBox(height: 20),

            _Label(text: 'Ngân hàng'),
            const SizedBox(height: 6),
            _BankSelectorTile(bank: _selectedBank, onTap: _pickBank),
            const SizedBox(height: 20),

            _Label(text: 'Số tài khoản'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: _decoration(
                colors,
                hint: '6 – 20 chữ số',
                icon: Icons.credit_card_rounded,
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Vui lòng nhập số tài khoản';
                if (s.length < 6) return 'Số tài khoản tối thiểu 6 chữ số';
                return null;
              },
            ),
            const SizedBox(height: 20),

            _Label(text: 'Tên chủ tài khoản'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _accountNameController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [NoDiacriticsUpperCaseFormatter()],
              decoration: _decoration(
                colors,
                hint: 'NGUYEN VAN A (in hoa, không dấu)',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập tên chủ tài khoản';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            _PrimaryButton(
              label: 'Gửi để duyệt',
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
            // Cho phép huỷ nếu đang sửa 1 tài khoản đã tồn tại.
            if (!result.isNone) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() => _editing = false),
                  child: Text(
                    'Huỷ',
                    style:
                        GoogleFonts.beVietnamPro(color: colors.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(
    AppColorScheme colors, {
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.beVietnamPro(color: colors.textTertiary),
      prefixIcon: Icon(icon, color: colors.textSecondary, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: BorderSide(color: colors.brand, width: 1.5),
      ),
    );
  }
}

/// Bỏ dấu tiếng Việt + ép in hoa (chuẩn tên chủ TK VietQR: A–Z và khoảng trắng).
class NoDiacriticsUpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = removeVietnameseTones(newValue.text)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z ]'), '');
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

/// Bỏ dấu tiếng Việt (giữ nguyên hoa/thường ký tự gốc).
String removeVietnameseTones(String input) {
  const map = <String, String>{
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  var s = input;
  map.forEach((base, chars) {
    for (final c in chars.split('')) {
      s = s.replaceAll(c, base).replaceAll(c.toUpperCase(), base.toUpperCase());
    }
  });
  return s;
}

// ─── Status banner ───────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final BankApprovalStatus status;
  final String? reason;
  const _StatusBanner({required this.status, this.reason});

  @override
  Widget build(BuildContext context) {
    final (color, icon, title, body) = switch (status) {
      BankApprovalStatus.pending => (
          AppColors.amber,
          Icons.hourglass_top_rounded,
          'Đang chờ admin duyệt',
          'Tài khoản sẽ được dùng để nhận cọc ngay khi được duyệt.',
        ),
      BankApprovalStatus.approved => (
          AppColors.emerald,
          Icons.verified_rounded,
          'Đang sử dụng',
          'Tài khoản đã được duyệt và dùng để tạo mã QR nhận cọc.',
        ),
      BankApprovalStatus.rejected => (
          AppColors.coral,
          Icons.error_outline_rounded,
          'Bị từ chối',
          reason?.isNotEmpty == true
              ? reason!
              : 'Thông tin chưa hợp lệ, vui lòng kiểm tra và gửi lại.',
        ),
      BankApprovalStatus.none => (
          AppColors.info,
          Icons.info_outline_rounded,
          'Chưa có tài khoản',
          'Thêm tài khoản để khách có thể chuyển cọc.',
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5,
                    height: 1.4,
                    color: context.colors.textSecondary,
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

// ─── Account card (view mode) ────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final BankInfo info;
  const _AccountCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bank = bankByBin(info.bankBin);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              if (bank != null) ...[
                _BankLogo(bank: bank, size: 40),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  info.bankName ?? bank?.shortName ?? 'Ngân hàng',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _kv(colors, 'Số tài khoản', info.bankAccountNumber),
          const SizedBox(height: 10),
          _kv(colors, 'Chủ tài khoản', info.bankAccountName),
        ],
      ),
    );
  }

  Widget _kv(AppColorScheme colors, String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            k,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Primary button ──────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  const _PrimaryButton({
    required this.label,
    this.loading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: loading
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
    );
  }
}

// ─── Info banner ─────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final AppColorScheme colors;
  const _InfoBanner({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tài khoản dùng để tạo mã QR cho khách chuyển tiền cọc khi đặt '
              'phòng qua website. Mọi thay đổi cần admin duyệt trước khi áp dụng.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5,
                height: 1.45,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Labels ──────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: context.colors.textSecondary,
      ),
    );
  }
}

// ─── Bank selector tile ──────────────────────────────────────────────────────

class _BankSelectorTile extends StatelessWidget {
  final VnBank? bank;
  final VoidCallback onTap;
  const _BankSelectorTile({required this.bank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Row(
          children: [
            if (bank != null) ...[
              _BankLogo(bank: bank!, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank!.shortName,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (bank!.name.isNotEmpty)
                      Text(
                        bank!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11.5,
                          color: colors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              Icon(Icons.account_balance_rounded,
                  size: 20, color: colors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Chọn ngân hàng',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ],
            Icon(Icons.expand_more_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _BankLogo extends StatelessWidget {
  final VnBank bank;
  final double size;
  const _BankLogo({required this.bank, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: bank.logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        memCacheWidth: 120,
        placeholder: (_, __) => _fallback(context),
        errorWidget: (_, __, ___) => _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: context.colors.bgSurfaceContainer,
        child: Icon(Icons.account_balance_rounded,
            size: size * 0.55, color: context.colors.textTertiary),
      );
}

// ─── Bank picker bottom sheet ────────────────────────────────────────────────

class _BankPickerSheet extends StatefulWidget {
  const _BankPickerSheet();

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final q = _query.trim().toLowerCase();
    final banks = q.isEmpty
        ? kVnBanks
        : kVnBanks
            .where((b) =>
                b.shortName.toLowerCase().contains(q) ||
                b.name.toLowerCase().contains(q) ||
                b.bin.contains(q))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm ngân hàng...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: colors.borderDefault),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: banks.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy ngân hàng',
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textTertiary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: banks.length,
                        itemBuilder: (context, i) {
                          final bank = banks[i];
                          return ListTile(
                            leading: _BankLogo(bank: bank, size: 36),
                            title: Text(
                              bank.shortName,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              bank.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: colors.textTertiary,
                              ),
                            ),
                            onTap: () => Navigator.of(context).pop(bank),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
