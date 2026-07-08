import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../profile/data/models/bank_account.dart';
import '../../profile/data/vn_banks.dart';
import '../controllers/admin_bank_controller.dart';
import '../data/models/admin_bank_account.dart';

/// Chi tiết 1 yêu cầu tài khoản nhận tiền + hành động duyệt / từ chối.
///
/// Nhận [account] qua `extra` từ list (không có endpoint detail riêng). Nếu
/// mở trực tiếp (hot reload) mà thiếu → tra lại trong [bankQueueProvider].
class AdminBankDetailScreen extends ConsumerWidget {
  final String accountId;
  final AdminBankAccount? account;

  const AdminBankDetailScreen({
    super.key,
    required this.accountId,
    this.account,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    // Ưu tiên object truyền qua extra; fallback tra trong queue đang tải.
    final resolved = account ??
        ref.watch(bankQueueProvider).valueOrNull?.items.firstWhere(
              (a) => a.id == accountId,
              orElse: () => const AdminBankAccount(
                id: '',
                name: '',
                status: BankApprovalStatus.none,
              ),
            );

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: Text(
          'Chi tiết yêu cầu',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: (resolved == null || resolved.id.isEmpty)
          ? _NotFound(onBack: () => context.pop())
          : _Body(account: resolved),
    );
  }
}

class _Body extends ConsumerWidget {
  final AdminBankAccount account;
  const _Body({required this.account});

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duyệt tài khoản?'),
        content: Text(
          'Tài khoản nhận tiền của "${account.name}" sẽ được áp dụng ngay '
          'và dùng để sinh mã VietQR cho khách chuyển cọc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await ref.read(adminBankActionsProvider.notifier).approve(
          account.id,
        );
    if (!context.mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Đã duyệt tài khoản nhận tiền');
      context.pop();
    } else {
      final err = ref.read(adminBankActionsProvider).error;
      AppSnackBar.error(context, err?.toString() ?? 'Duyệt thất bại');
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );
    if (reason == null || !context.mounted) return;

    final ok = await ref.read(adminBankActionsProvider.notifier).reject(
          account.id,
          reason: reason,
        );
    if (!context.mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Đã từ chối yêu cầu');
      context.pop();
    } else {
      final err = ref.read(adminBankActionsProvider).error;
      AppSnackBar.error(context, err?.toString() ?? 'Từ chối thất bại');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(adminBankActionsProvider).isLoading;
    final a = account;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _OwnerHeader(account: a),
            const SizedBox(height: 16),
            _StatusBanner(status: a.status, reason: a.rejectReason),
            const SizedBox(height: 20),
            if (a.pending != null) ...[
              const _SectionLabel('TÀI KHOẢN ĐỀ NGHỊ'),
              const SizedBox(height: 8),
              _BankCard(info: a.pending!, highlight: true),
            ],
            if (a.current != null) ...[
              const SizedBox(height: 16),
              _SectionLabel(
                a.pending != null
                    ? 'TÀI KHOẢN ĐANG DÙNG'
                    : 'TÀI KHOẢN ĐÃ DUYỆT',
              ),
              const SizedBox(height: 8),
              _BankCard(info: a.current!, highlight: false),
            ],
            if (a.pending == null && a.current == null)
              Text(
                'Chưa có thông tin tài khoản.',
                style: TextStyle(color: context.colors.textTertiary),
              ),
            const SizedBox(height: 100),
          ],
        ),
        if (a.isPending)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ActionBar(
              busy: busy,
              onApprove: () => _approve(context, ref),
              onReject: () => _reject(context, ref),
            ),
          ),
      ],
    );
  }
}

// ─── Owner header ────────────────────────────────────────────────────────────

class _OwnerHeader extends StatelessWidget {
  final AdminBankAccount account;
  const _OwnerHeader({required this.account});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final a = account;
    return Row(
      children: [
        _Avatar(name: a.name, url: a.avatar),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.name.isEmpty ? 'Chủ homestay' : a.name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [a.phone, a.email].whereType<String>().join('  ·  '),
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? url;
  const _Avatar({required this.name, this.url});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          memCacheWidth: 144,
          placeholder: (_, __) => _fallback(colors),
          errorWidget: (_, __, ___) => _fallback(colors),
        ),
      );
    }
    return _fallback(colors);
  }

  Widget _fallback(AppColorScheme colors) => Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.brand.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'O',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.brand,
          ),
        ),
      );
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
          'Đang chờ duyệt',
          'Kiểm tra thông tin tài khoản trước khi duyệt hoặc từ chối.',
        ),
      BankApprovalStatus.approved => (
          AppColors.emerald,
          Icons.verified_rounded,
          'Đã duyệt',
          'Tài khoản đang được dùng để sinh mã VietQR nhận cọc.',
        ),
      BankApprovalStatus.rejected => (
          AppColors.coral,
          Icons.error_outline_rounded,
          'Đã từ chối',
          reason?.isNotEmpty == true
              ? 'Lý do: ${reason!}'
              : 'Yêu cầu đã bị từ chối.',
        ),
      BankApprovalStatus.none => (
          AppColors.info,
          Icons.info_outline_rounded,
          'Chưa cấu hình',
          'Chủ homestay chưa gửi tài khoản nhận tiền.',
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
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

// ─── Bank card ───────────────────────────────────────────────────────────────

class _BankCard extends StatelessWidget {
  final BankInfo info;
  final bool highlight;
  const _BankCard({required this.info, required this.highlight});

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
        border: Border.all(
          color: highlight ? colors.brand : colors.borderDefault,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (bank != null) ...[
                _BankLogo(url: bank.logoUrl, size: 40),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  info.bankName ?? bank?.shortName ?? 'Ngân hàng',
                  style: TextStyle(
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
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
        Expanded(
          child: SelectableText(
            v,
            style: TextStyle(
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

class _BankLogo extends StatelessWidget {
  final String url;
  final double size;
  const _BankLogo({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: CachedNetworkImage(
        imageUrl: url,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: context.colors.textTertiary,
      ),
    );
  }
}

// ─── Action bar ──────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ActionBar({
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(top: BorderSide(color: colors.borderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: busy ? null : onReject,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Từ chối',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: busy ? null : onApprove,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: colors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Duyệt',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reject reason dialog ────────────────────────────────────────────────────

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lý do từ chối'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: Tên chủ tài khoản không khớp CCCD...',
          ),
          validator: (v) {
            final s = v?.trim() ?? '';
            if (s.length < 5) return 'Lý do tối thiểu 5 ký tự';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.error,
          ),
          child: const Text('Từ chối'),
        ),
      ],
    );
  }
}

// ─── Not found ───────────────────────────────────────────────────────────────

class _NotFound extends StatelessWidget {
  final VoidCallback onBack;
  const _NotFound({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      message: 'Không tìm thấy yêu cầu',
      actionLabel: 'Quay lại',
      onAction: onBack,
    );
  }
}
