import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/booking_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/pull_to_refresh.dart';
import '../../chat/controllers/chat_controller.dart';
import '../controllers/booking_controller.dart';
import '../utils/guest_flow_filter.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String id;

  const BookingDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(bookingDetailProvider(id));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: const Text('Chi tiết booking'),
      ),
      floatingActionButton: async.maybeWhen(
        data: (_) => _ChatWithGuestButton(bookingId: id),
        orElse: () => null,
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (booking) => _BookingActionBar(booking: booking),
        orElse: () => null,
      ),
      body: RefreshIndicator(
        color: colors.brand,
        onRefresh: () async => ref.invalidate(bookingDetailProvider(id)),
        child: async.when(
          loading: () => const LoadingWidget(),
          error: (error, _) => RefreshableMessage(
            child: ErrorStateWidget(
              message: error.toString().replaceAll('Exception: ', ''),
              onRetry: () => ref.invalidate(bookingDetailProvider(id)),
            ),
          ),
          data: (booking) => _BookingDetailBody(booking: booking),
        ),
      ),
    );
  }
}

/// Thanh hành động theo trạng thái booking (OWNER/SALE):
/// - HOLD → "Ghi nhận thu cọc" (`/paid`, BE tự chuyển CONFIRMED).
/// - CONFIRMED → "Nhận phòng & hoàn tất" (`/checkin` → COMPLETED).
/// Trạng thái khác → không hiện (SizedBox.shrink).
class _BookingActionBar extends ConsumerStatefulWidget {
  final BookingModel booking;

  const _BookingActionBar({required this.booking});

  @override
  ConsumerState<_BookingActionBar> createState() => _BookingActionBarState();
}

class _BookingActionBarState extends ConsumerState<_BookingActionBar> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.booking.status;
    final (label, icon, onTap) = switch (status) {
      BookingStatus.hold => (
          'Ghi nhận thu cọc',
          Icons.payments_outlined,
          _markPaid,
        ),
      BookingStatus.confirmed => (
          'Nhận phòng & hoàn tất',
          Icons.login_rounded,
          _checkin,
        ),
      _ => (null, null, null),
    };

    if (label == null) return const SizedBox.shrink();

    final colors = context.colors;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: _busy ? null : onTap,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: colors.brand,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.beVietnamPro(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markPaid() async {
    final amount = await _showAmountSheet(
      title: 'Ghi nhận thu cọc',
      subtitle: 'Bỏ trống để hệ thống ghi nhận cọc mặc định (50%). '
          'Đơn đang giữ chỗ sẽ tự chuyển sang đã xác nhận.',
      actionLabel: 'Ghi nhận',
    );
    if (amount == null) return; // Huỷ dialog
    await _run(() => ref
        .read(bookingActionsProvider.notifier)
        .markPaid(widget.booking.id, amount: amount.value));
  }

  Future<void> _checkin() async {
    final amount = await _showAmountSheet(
      title: 'Nhận phòng & hoàn tất',
      subtitle: 'Xác nhận khách đã nhận phòng và thu nốt tiền. Bỏ trống để '
          'thu cho đủ tổng tiền. Đơn sẽ chuyển sang Hoàn tất.',
      actionLabel: 'Hoàn tất',
    );
    if (amount == null) return;
    await _run(() => ref
        .read(bookingActionsProvider.notifier)
        .checkin(widget.booking.id, amount: amount.value));
  }

  Future<void> _run(Future<bool> Function() action) async {
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      AppSnackBar.success(context, 'Cập nhật booking thành công');
    } else {
      final err = ref.read(bookingActionsProvider).error;
      AppSnackBar.error(
        context,
        err?.toString().replaceAll('Exception: ', '') ?? 'Có lỗi xảy ra',
      );
    }
  }

  /// Trả `null` khi user huỷ; `(value: null)` khi xác nhận bỏ trống số tiền;
  /// `(value: n)` khi nhập số tiền cụ thể.
  Future<({int? value})?> _showAmountSheet({
    required String title,
    required String subtitle,
    required String actionLabel,
  }) {
    return showDialog<({int? value})>(
      context: context,
      builder: (_) => _AmountDialog(
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
      ),
    );
  }
}

/// Dialog nhập số tiền VND (tuỳ chọn). Bỏ trống → BE dùng mặc định.
class _AmountDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String actionLabel;

  const _AmountDialog({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      title: Text(
        widget.title,
        style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subtitle,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Số tiền (VND) — tuỳ chọn',
              hintText: 'Bỏ trống nếu dùng mặc định',
              suffixText: 'đ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () {
            final raw = _ctrl.text.trim();
            final amount = raw.isEmpty ? null : int.tryParse(raw);
            Navigator.pop(context, (value: amount));
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

/// Nút mở (hoặc tạo) hội thoại với khách của booking này.
class _ChatWithGuestButton extends ConsumerWidget {
  final String bookingId;

  const _ChatWithGuestButton({required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(chatActionsProvider).isLoading;

    return FloatingActionButton.extended(
      onPressed: isLoading ? null : () => _openChat(context, ref),
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.forum_rounded),
      label: const Text('Nhắn với khách'),
    );
  }

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final convId = await ref
        .read(chatActionsProvider.notifier)
        .openBookingConversation(bookingId);
    if (!context.mounted) return;
    if (convId != null) {
      context.push('/chat/$convId');
    } else {
      final error = ref.read(chatActionsProvider).error;
      AppSnackBar.error(
        context,
        error?.toString() ?? 'Không mở được cuộc trò chuyện',
      );
    }
  }
}

class _BookingDetailBody extends StatelessWidget {
  final BookingModel booking;

  const _BookingDetailBody({required this.booking});

  String _relativeDateLabel(DateTime date) {
    final today = GuestFlowFilter.dateOnly(DateTime.now());
    final target = GuestFlowFilter.dateOnly(date);
    final fmt = DateFormat('dd/MM/yyyy');

    if (target == today) {
      return 'Hôm nay (${fmt.format(target)})';
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (target == tomorrow) {
      return 'Ngày mai (${fmt.format(target)})';
    }
    return fmt.format(target);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = AppHelpers.bookingStatusColor(booking.status.value);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                  Expanded(
                    child: Text(
                      booking.propertyName,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      booking.status.label,
                      style: GoogleFonts.beVietnamPro(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${booking.nights} đêm · ${booking.guestCount} khách',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailSection(
          title: 'THÔNG TIN KHÁCH',
          children: [
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Tên khách',
              value: booking.customerName ?? 'Chưa có',
            ),
            if (booking.customerPhone != null)
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: booking.customerPhone!,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailSection(
          title: 'LỊCH LƯU TRÚ',
          children: [
            _InfoRow(
              icon: Icons.login_rounded,
              label: 'Check-in',
              value: _relativeDateLabel(booking.checkinDate),
            ),
            _InfoRow(
              icon: Icons.logout_rounded,
              label: 'Check-out',
              value: _relativeDateLabel(booking.checkoutDate),
            ),
            _InfoRow(
              icon: Icons.nights_stay_outlined,
              label: 'Số đêm',
              value: '${booking.nights} đêm',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailSection(
          title: 'THANH TOÁN & GHI CHÚ',
          children: [
            if (booking.depositAmount != null && booking.depositAmount! > 0)
              _InfoRow(
                icon: Icons.payments_outlined,
                label: 'Tiền cọc',
                value: '${AppHelpers.formatPrice(booking.depositAmount!)}đ',
              ),
            if (booking.saleName != 'N/A')
              _InfoRow(
                icon: Icons.support_agent_outlined,
                label: 'Nhân viên phụ trách',
                value: booking.saleName,
              ),
            if (booking.notes != null && booking.notes!.trim().isNotEmpty)
              _InfoRow(
                icon: Icons.notes_outlined,
                label: 'Ghi chú',
                value: booking.notes!,
              ),
          ],
        ),
        if (booking.status == BookingStatus.cancelled) ...[
          const SizedBox(height: AppSpacing.md),
          _DetailSection(
            title: 'THÔNG TIN HUỶ',
            children: [
              _InfoRow(
                icon: Icons.person_off_outlined,
                label: 'Huỷ bởi',
                value: booking.cancelledByRole == null
                    ? 'Hệ thống'
                    : AppHelpers.roleLabel(booking.cancelledByRole),
              ),
              if (booking.cancelledAt != null)
                _InfoRow(
                  icon: Icons.event_busy_outlined,
                  label: 'Thời điểm huỷ',
                  value: fmt.format(booking.cancelledAt!),
                ),
              if (booking.cancelledReason != null &&
                  booking.cancelledReason!.trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.notes_outlined,
                  label: 'Lý do',
                  value: booking.cancelledReason!,
                ),
            ],
          ),
        ],
        if (booking.status == BookingStatus.hold &&
            booking.holdRemainingSeconds > 0) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: colors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: colors.warning, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Còn ${(booking.holdRemainingSeconds / 60).ceil()} phút giữ phòng',
                    style: GoogleFonts.beVietnamPro(
                      color: colors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (booking.holdExpireAt != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hết hạn giữ: ${fmt.format(booking.holdExpireAt!)}',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: colors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (children.isEmpty) {
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
            title,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
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
