import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../rooms/controllers/room_controller.dart';
import '../controllers/booking_controller.dart';

class HoldRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const HoldRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<HoldRoomScreen> createState() => _HoldRoomScreenState();
}

class _HoldRoomScreenState extends ConsumerState<HoldRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _checkinDate;
  DateTime? _checkoutDate;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _depositCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _nights => (_checkinDate != null && _checkoutDate != null)
      ? _checkoutDate!.difference(_checkinDate!).inDays
      : 0;

  Future<void> _pickDate(bool isCheckin) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckin
          ? (_checkinDate ?? now.add(const Duration(days: 1)))
          : (_checkoutDate ??
              (_checkinDate ?? now).add(const Duration(days: 1))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckin) {
        _checkinDate = picked;
        if (_checkoutDate != null && !_checkoutDate!.isAfter(picked)) {
          _checkoutDate = picked.add(const Duration(days: 1));
        }
      } else {
        _checkoutDate = picked;
      }
    });
  }

  Future<void> _holdRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_checkinDate == null || _checkoutDate == null) {
      AppSnackBar.error(context, 'Vui lòng chọn ngày check-in và check-out');
      return;
    }

    final success = await ref.read(bookingActionsProvider.notifier).hold({
      'roomId': widget.roomId,
      'checkinDate': _checkinDate!.toIso8601String(),
      'checkoutDate': _checkoutDate!.toIso8601String(),
      if (_customerNameCtrl.text.trim().isNotEmpty)
        'customerName': _customerNameCtrl.text.trim(),
      if (_customerPhoneCtrl.text.trim().isNotEmpty)
        'customerPhone': _customerPhoneCtrl.text.trim(),
      if (_depositCtrl.text.trim().isNotEmpty)
        'depositAmount':
            double.tryParse(_depositCtrl.text.replaceAll('.', '').trim()),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    });

    if (!mounted) return;

    if (success) {
      AppSnackBar.success(context, 'Giữ phòng thành công! (30 phút)');
      context.pop();
    } else {
      final errState = ref.read(bookingActionsProvider);
      AppSnackBar.error(
        context,
        errState.hasError ? errState.error.toString() : 'Có lỗi xảy ra',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final isLoading = ref.watch(bookingActionsProvider).isLoading;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giữ phòng'),
      ),
      body: roomAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (room) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Room info card ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                        color: colors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.bed_outlined,
                            color: colors.primary, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name,
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: colors.onSurface,
                              ),
                            ),
                            if (room.homestay != null)
                              Text(
                                room.homestay!.name,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  color:
                                      colors.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        room.priceDisplay,
                        style: GoogleFonts.beVietnamPro(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: AppSpacing.lg),

                // ── Date picker ────────────────────────────────────
                Text(
                  'Ngày lưu trú *',
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Check-in',
                        icon: Icons.login_rounded,
                        date: _checkinDate,
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: colors.onSurface.withValues(alpha: 0.3),
                          size: 20),
                    ),
                    Expanded(
                      child: _DateButton(
                        label: 'Check-out',
                        icon: Icons.logout_rounded,
                        date: _checkoutDate,
                        onTap: () => _pickDate(false),
                      ),
                    ),
                  ],
                ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

                // Night count + estimated price
                if (_nights > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.nights_stay_outlined,
                            size: 16, color: colors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$_nights đêm',
                          style: GoogleFonts.beVietnamPro(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (room.price != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '≈ ${_estimateTotal(room.price!.weekdayPrice, _nights)}đ',
                            style: GoogleFonts.beVietnamPro(
                              color: colors.primary.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // ── Customer info ──────────────────────────────────
                Text(
                  'Thông tin khách hàng',
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                TextFormField(
                  controller: _customerNameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Tên khách hàng',
                    prefixIcon: Icon(Icons.person_outline_rounded,
                        color: colors.primary),
                  ),
                ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _customerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại khách',
                    prefixIcon:
                        Icon(Icons.phone_outlined, color: colors.primary),
                  ),
                ).animate(delay: 120.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _depositCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Tiền cọc (đ)',
                    prefixIcon:
                        Icon(Icons.payments_outlined, color: colors.primary),
                  ),
                ).animate(delay: 140.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú',
                    prefixIcon:
                        Icon(Icons.notes_rounded, color: colors.primary),
                    alignLabelWithHint: true,
                  ),
                ).animate(delay: 160.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: AppSpacing.md),

                // ── Notice banner ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Phòng sẽ được giữ trong 30 phút. Sau đó tự động huỷ nếu chưa xác nhận.',
                          style: GoogleFonts.beVietnamPro(
                            color: AppColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

                const SizedBox(height: AppSpacing.xl),

                // ── Submit button ──────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            height: 52,
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary)),
                          ),
                        )
                      : FilledButton.icon(
                          key: const ValueKey('hold-btn'),
                          onPressed: _holdRoom,
                          icon: const Icon(Icons.lock_clock_rounded),
                          label: Text(
                            'Giữ phòng 30 phút',
                            style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                          ),
                        ),
                ).animate(delay: 300.ms).fadeIn(duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _estimateTotal(double pricePerNight, int nights) {
    final total = pricePerNight * nights;
    if (total >= 1000000) return '${(total / 1000000).toStringAsFixed(1)}tr';
    return '${(total / 1000).toStringAsFixed(0)}k';
  }
}

// ─── Date Button ──────────────────────────────────────────────────────────────
class _DateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.icon,
    this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasDate = date != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasDate
                ? colors.primary
                : colors.outline.withValues(alpha: 0.4),
            width: hasDate ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color:
              hasDate ? colors.primary.withValues(alpha: 0.05) : colors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 13,
                    color: hasDate
                        ? colors.primary
                        : colors.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11,
                    color: hasDate
                        ? colors.primary
                        : colors.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasDate ? DateFormat('dd/MM/yyyy').format(date!) : 'Chọn ngày',
              style: GoogleFonts.beVietnamPro(
                fontWeight: hasDate ? FontWeight.w700 : FontWeight.w400,
                color: hasDate
                    ? colors.primary
                    : colors.onSurface.withValues(alpha: 0.35),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
