import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/vnd_input_formatter.dart';
import '../../../data/models/booking_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/mark_paid_dialog.dart';
import '../../../shared/widgets/section_label.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';

/// Chi tiết một booking — khối tiền (đọc thẳng từ BookingDto), ảnh bill cọc
/// khách gửi, và các thao tác owner: xác nhận, ghi nhận thanh toán, xác nhận
/// nhận phòng + thu nốt tiền (§5.3, §5.5, §5.6). Mở qua `/bookings/:id`
/// (list card tap + deeplink FCM booking_*).
class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _actionLoading = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingDetailProvider(widget.bookingId));
    final canManage = ref.watch(
      currentUserProvider.select((u) => u?.canEdit ?? false),
    );
    // Chỉ quản lý cấp hệ thống (ADMIN / SALE hệ thống) thấy chủ homestay + sale.
    final showOwner = ref.watch(
      currentUserProvider.select((u) => u?.isSystemManager ?? false),
    );

    return AppScaffold(
      title: 'Chi tiết booking',
      showBottomNav: false,
      showDefaultActions: false,
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () =>
              ref.invalidate(bookingDetailProvider(widget.bookingId)),
        ),
        data: (booking) => _content(booking, canManage, showOwner),
      ),
    );
  }

  Widget _content(BookingModel booking, bool canManage, bool showOwner) {
    final colors = context.colors;
    return RefreshIndicator(
      onRefresh: () async =>
          ref.invalidate(bookingDetailProvider(widget.bookingId)),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxl),
        children: [
          _HeaderCard(booking: booking, showOwner: showOwner),
          const SizedBox(height: AppSpacing.md),
          _MoneyCard(booking: booking),
          if (booking.priceBreakdown != null) ...[
            const SizedBox(height: AppSpacing.md),
            _BreakdownCard(breakdown: booking.priceBreakdown!),
          ],
          if (booking.depositProofUrl != null &&
              booking.depositProofUrl!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _DepositProofCard(url: booking.depositProofUrl!),
          ],
          const SizedBox(height: AppSpacing.lg),
          // Nhắn tin với khách (hội thoại theo booking — realtime).
          OutlinedButton.icon(
            onPressed: () =>
                context.push('/conversations/by-booking/${booking.id}'),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text('Nhắn tin với khách',
                style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.brand,
              side: BorderSide(color: colors.brand),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: AppSpacing.md),
            _actions(booking),
          ],
        ],
      ),
    );
  }

  Widget _actions(BookingModel booking) {
    final colors = context.colors;
    if (_actionLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final children = <Widget>[];

    // HOLD → huỷ / xác nhận.
    if (booking.status == BookingStatus.hold) {
      children.add(Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Huỷ',
                  style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton(
              onPressed: _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: colors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Xác nhận',
                  style: GoogleFonts.beVietnamPro(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ));
    }

    // Ghi nhận thanh toán (cọc/đủ tiền) — chưa thu & booking còn hiệu lực.
    if (!booking.isPaid &&
        booking.status != BookingStatus.cancelled &&
        booking.status != BookingStatus.noShow &&
        booking.status != BookingStatus.completed) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.sm));
      }
      children.add(SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: _markPaid,
          icon: const Icon(Icons.payments_rounded, size: 18),
          label: Text('Ghi nhận thanh toán',
              style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ));
    }

    // Xác nhận nhận phòng + thu nốt tiền → COMPLETED (§5.5). Chỉ khi CONFIRMED
    // và chưa check-in.
    if (booking.canCheckin) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.sm));
      }
      children.add(SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _checkin(booking),
          icon: const Icon(Icons.login_rounded, size: 18),
          label: Text('Xác nhận nhận phòng + thu nốt tiền',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          style: FilledButton.styleFrom(
            backgroundColor: colors.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ));
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    await _run(
      () => ref.read(bookingActionsProvider.notifier).confirm(widget.bookingId),
      success: 'Xác nhận booking thành công',
      failure: 'Không thể xác nhận, thử lại sau',
    );
  }

  Future<void> _cancel() async {
    final colors = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xác nhận huỷ',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn huỷ booking này?',
            style: GoogleFonts.beVietnamPro()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: colors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Huỷ booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => ref.read(bookingActionsProvider.notifier).cancel(widget.bookingId),
      success: 'Đã huỷ booking',
      failure: 'Không thể huỷ, thử lại sau',
    );
  }

  Future<void> _markPaid() async {
    final booking =
        ref.read(bookingDetailProvider(widget.bookingId)).valueOrNull;
    if (booking == null) return;
    final result = await MarkPaidDialog.show(context, booking);
    if (result == null || !mounted) return;
    await _run(
      () => ref
          .read(bookingActionsProvider.notifier)
          .markPaid(widget.bookingId, amount: result.amount),
      success: 'Đã ghi nhận thanh toán',
      failure: 'Không thể ghi nhận, thử lại sau',
    );
  }

  Future<void> _checkin(BookingModel booking) async {
    final amount = await _CheckinDialog.show(context, booking);
    // `null` = huỷ dialog; _CheckinAmount(null) = xác nhận, để BE thu cho đủ.
    if (amount == null || !mounted) return;
    await _run(
      () => ref
          .read(bookingActionsProvider.notifier)
          .checkin(widget.bookingId, amount: amount.value),
      success: 'Đã xác nhận nhận phòng, booking hoàn tất',
      failure: 'Không thể xác nhận nhận phòng, thử lại sau',
    );
  }

  /// Bọc 1 action: bật loading, gọi, hiện snackbar theo kết quả.
  Future<void> _run(
    Future<bool> Function() action, {
    required String success,
    required String failure,
  }) async {
    setState(() => _actionLoading = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _actionLoading = false);
    if (ok) {
      AppSnackBar.success(context, success);
    } else {
      final err = ref.read(bookingActionsProvider).error;
      AppSnackBar.error(context, err?.toString() ?? failure);
    }
  }
}

// ─── Header card ───────────────────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final BookingModel booking;

  /// Hiển thị chủ homestay + nhân viên tạo booking — chỉ cho quản lý cấp hệ
  /// thống (ADMIN / SALE hệ thống). Xem [UserModel.isSystemManager].
  final bool showOwner;
  const _HeaderCard({required this.booking, this.showOwner = false});

  Color _statusColor(AppColorScheme colors) {
    switch (booking.status) {
      case BookingStatus.hold:
        return colors.warning;
      case BookingStatus.confirmed:
        return colors.success;
      case BookingStatus.cancelled:
        return colors.error;
      case BookingStatus.completed:
        return colors.brand;
      case BookingStatus.noShow:
        return colors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final statusColor = _statusColor(colors);
    final fmt = DateFormat('dd/MM/yyyy');

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.propertyName,
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  booking.status.label,
                  style: GoogleFonts.beVietnamPro(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _row(colors, Icons.date_range_rounded,
              '${fmt.format(booking.checkinDate)} → ${fmt.format(booking.checkoutDate)}  (${booking.nights} đêm)'),
          _row(colors, Icons.people_outline_rounded,
              '${booking.guestCount} khách'),
          if (booking.customerName != null)
            _row(colors, Icons.person_outline_rounded, booking.customerName!),
          if (booking.customerPhone != null)
            _row(colors, Icons.phone_outlined, booking.customerPhone!),
          // Chủ homestay + nhân viên phụ trách — chỉ cho quản lý cấp hệ thống.
          if (showOwner && booking.hasOwnerInfo)
            _row(
              colors,
              Icons.person_pin_rounded,
              booking.ownerPhone != null && booking.ownerPhone!.isNotEmpty
                  ? 'Chủ: ${booking.ownerName} · ${booking.ownerPhone}'
                  : 'Chủ: ${booking.ownerName}',
            ),
          if (showOwner && booking.hasSaleInfo)
            _row(
                colors, Icons.badge_outlined, 'Nhân viên: ${booking.saleName}'),
          if (booking.checkedInAt != null)
            _row(colors, Icons.login_rounded,
                'Nhận phòng lúc ${DateFormat('dd/MM HH:mm').format(booking.checkedInAt!.toLocal())}'),
        ],
      ),
    );
  }

  Widget _row(AppColorScheme colors, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.5,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Money card ────────────────────────────────────────────────────────────
class _MoneyCard extends StatelessWidget {
  final BookingModel booking;
  const _MoneyCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final b = booking;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(label: 'Thanh toán'),
          const SizedBox(height: AppSpacing.sm),
          _line(
            colors,
            'Tổng tiền',
            b.hasPrice ? AppHelpers.formatVnd(b.totalAmount!) : 'Chưa chốt giá',
            emphasize: true,
            muted: !b.hasPrice,
          ),
          if (b.depositAmount != null && b.depositAmount! > 0)
            _line(colors, 'Cần cọc', AppHelpers.formatVnd(b.depositAmount!)),
          _line(colors, 'Đã thu', AppHelpers.formatVnd(b.paidAmount ?? 0),
              valueColor: (b.paidAmount ?? 0) > 0 ? colors.success : null),
          if (b.remainingAmount != null)
            _line(colors, 'Còn lại', AppHelpers.formatVnd(b.remainingAmount!),
                valueColor:
                    b.remainingAmount! > 0 ? colors.warning : colors.success),
        ],
      ),
    );
  }

  Widget _line(
    AppColorScheme colors,
    String label,
    String value, {
    bool emphasize = false,
    bool muted = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13.5,
              color: colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: emphasize ? 16 : 14,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              color: muted
                  ? colors.textTertiary
                  : (valueColor ?? colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Price breakdown card ──────────────────────────────────────────────────
class _BreakdownCard extends StatelessWidget {
  final BookingPriceBreakdown breakdown;
  const _BreakdownCard({required this.breakdown});

  static String _typeLabel(String type) => switch (type) {
        'weekend' => 'Cuối tuần',
        'holiday' => 'Ngày lễ',
        _ => 'Ngày thường',
      };

  static String _fmtDate(String raw) {
    final d = DateTime.tryParse(raw);
    return d != null ? DateFormat('dd/MM').format(d) : raw;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bd = breakdown;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label: 'Chi tiết giá (${bd.nights} đêm)'),
          const SizedBox(height: AppSpacing.sm),
          ...bd.lineItems.map(
            (it) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_fmtDate(it.date)} · ${_typeLabel(it.type)}',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13, color: colors.textSecondary),
                  ),
                  Text(
                    AppHelpers.formatVnd(it.amount),
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          if (bd.surchargeTotal > 0) ...[
            const Divider(height: AppSpacing.md),
            _sub(colors, 'Tiền phòng', AppHelpers.formatVnd(bd.roomTotal)),
            _sub(
              colors,
              'Phụ thu${_surchargeNote(bd)}',
              AppHelpers.formatVnd(bd.surchargeTotal),
            ),
          ],
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary)),
              Text(
                AppHelpers.formatVnd(bd.total),
                style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.brand),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _surchargeNote(BookingPriceBreakdown bd) {
    final parts = <String>[];
    if (bd.extraAdults > 0) parts.add('${bd.extraAdults} người lớn');
    if (bd.extraChildren > 0) parts.add('${bd.extraChildren} trẻ em');
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }

  Widget _sub(AppColorScheme colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13, color: colors.textSecondary)),
          Text(value,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13, color: colors.textPrimary)),
        ],
      ),
    );
  }
}

// ─── Deposit proof card ────────────────────────────────────────────────────
class _DepositProofCard extends StatelessWidget {
  final String url;
  const _DepositProofCard({required this.url});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(label: 'Ảnh bill chuyển khoản cọc (khách gửi)'),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _ImageViewerDialog(url: url),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 220,
                memCacheWidth: 800,
                placeholder: (_, __) => Container(
                  height: 220,
                  color: colors.bgSurfaceContainer,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 220,
                  color: colors.bgSurfaceContainer,
                  child: Icon(Icons.broken_image_outlined,
                      color: colors.textTertiary, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chạm để phóng to. Đối chiếu số tiền + nội dung trước khi ghi nhận cọc.',
            style: GoogleFonts.beVietnamPro(
                fontSize: 12, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ImageViewerDialog extends StatelessWidget {
  final String url;
  const _ImageViewerDialog({required this.url});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PhotoView(
            imageProvider: CachedNetworkImageProvider(url),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared card shell ─────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Check-in amount dialog ────────────────────────────────────────────────
/// Kết quả xác nhận check-in. [value] = null → BE thu cho đủ totalAmount;
/// có giá trị → cộng dồn vào paidAmount (§5.5).
class _CheckinAmount {
  final double? value;
  const _CheckinAmount(this.value);
}

class _CheckinDialog extends StatefulWidget {
  final BookingModel booking;
  const _CheckinDialog({required this.booking});

  static Future<_CheckinAmount?> show(
    BuildContext context,
    BookingModel booking,
  ) {
    return showDialog<_CheckinAmount>(
      context: context,
      builder: (_) => _CheckinDialog(booking: booking),
    );
  }

  @override
  State<_CheckinDialog> createState() => _CheckinDialogState();
}

class _CheckinDialogState extends State<_CheckinDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    // Prefill số còn lại — số owner thường thu nốt khi khách nhận phòng.
    final preset = widget.booking.remainingAmount;
    _ctrl = TextEditingController(text: _format(preset));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static String _format(double? value) {
    if (value == null || value <= 0) return '';
    return value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
  }

  double? _parse() {
    final digits = _ctrl.text.replaceAll('.', '').trim();
    if (digits.isEmpty) return null;
    return double.tryParse(digits);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final b = widget.booking;

    return AlertDialog(
      title: const Text('Xác nhận nhận phòng'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số tiền thu thêm khi khách nhận phòng (cộng dồn vào đã thu). '
            'Booking sẽ chuyển sang Hoàn tất.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [VndInputFormatter()],
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Số tiền thu thêm',
              suffixText: '₫',
              border: OutlineInputBorder(),
              isDense: true,
              helperText: 'Để trống = thu cho đủ tổng tiền',
            ),
          ),
          if (b.remainingAmount != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Còn lại: ${AppHelpers.formatVnd(b.remainingAmount!)}',
              style: TextStyle(fontSize: 12, color: colors.textTertiary),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _CheckinAmount(_parse())),
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}
