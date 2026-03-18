import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/room_provider.dart';

class RoomPriceScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomPriceScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomPriceScreen> createState() => _RoomPriceScreenState();
}

class _RoomPriceScreenState extends ConsumerState<RoomPriceScreen> {
  final _weekdayCtrl = TextEditingController();
  final _fridayCtrl = TextEditingController();
  final _saturdayCtrl = TextEditingController();
  final _holidayCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrice());
  }

  void _loadPrice() {
    final room = ref.read(roomDetailProvider(widget.roomId)).valueOrNull;
    if (room?.price != null) {
      _weekdayCtrl.text = room!.price!.weekdayPrice.toInt().toString();
      _fridayCtrl.text = room.price!.fridayPrice.toInt().toString();
      _saturdayCtrl.text = room.price!.saturdayPrice.toInt().toString();
      _holidayCtrl.text = room.price!.holidayPrice.toInt().toString();
    }
  }

  @override
  void dispose() {
    _weekdayCtrl.dispose();
    _fridayCtrl.dispose();
    _saturdayCtrl.dispose();
    _holidayCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final result = await RoomRepository().upsertPrice(widget.roomId, {
      'weekdayPrice':
          double.tryParse(_weekdayCtrl.text.replaceAll('.', '').trim()) ?? 0,
      'fridayPrice':
          double.tryParse(_fridayCtrl.text.replaceAll('.', '').trim()) ?? 0,
      'saturdayPrice':
          double.tryParse(_saturdayCtrl.text.replaceAll('.', '').trim()) ?? 0,
      'holidayPrice':
          double.tryParse(_holidayCtrl.text.replaceAll('.', '').trim()) ?? 0,
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      ref.invalidate(roomDetailProvider(widget.roomId));
      AppSnackBar.success(context, 'Cập nhật giá thành công');
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cập nhật giá phòng',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    Icon(Icons.price_change_outlined,
                        color: colors.primary, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bảng giá phòng',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                          Text(
                            'Nhập giá tính bằng VNĐ / đêm',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: colors.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.lg),

              // Price cards
              _PriceCard(
                controller: _weekdayCtrl,
                label: 'Ngày thường',
                subLabel: 'Thứ 2 – Thứ 5',
                icon: Icons.wb_sunny_outlined,
                color: const Color(0xFF1976D2),
                index: 0,
              ),
              const SizedBox(height: AppSpacing.md),
              _PriceCard(
                controller: _fridayCtrl,
                label: 'Thứ Sáu',
                subLabel: 'Cuối tuần bắt đầu',
                icon: Icons.weekend_outlined,
                color: const Color(0xFF7B1FA2),
                index: 1,
              ),
              const SizedBox(height: AppSpacing.md),
              _PriceCard(
                controller: _saturdayCtrl,
                label: 'Thứ Bảy',
                subLabel: 'Cao điểm cuối tuần',
                icon: Icons.star_outline_rounded,
                color: const Color(0xFFE65100),
                index: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              _PriceCard(
                controller: _holidayCtrl,
                label: 'Lễ / Tết / Đặc biệt',
                subLabel: 'Ngày nghỉ lễ',
                icon: Icons.celebration_outlined,
                color: AppColors.error,
                index: 3,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Save button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSaving
                    ? const Center(
                        child: SizedBox(
                          height: 52,
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)),
                        ),
                      )
                    : FilledButton.icon(
                        key: const ValueKey('save-btn'),
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          'Lưu bảng giá',
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String subLabel;
  final IconData icon;
  final Color color;
  final int index;

  const _PriceCard({
    required this.controller,
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  subLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 130,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
              ),
              decoration: InputDecoration(
                suffixText: 'đ',
                suffixStyle: GoogleFonts.nunito(
                    color: color, fontWeight: FontWeight.w700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: color, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                isDense: true,
              ),
              validator: (v) {
                if (v?.isEmpty == true) return 'Nhập giá';
                if (double.tryParse(v!) == null) return 'Không hợp lệ';
                return null;
              },
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }
}
