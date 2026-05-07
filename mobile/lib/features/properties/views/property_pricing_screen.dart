import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/vnd_input_formatter.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../rooms/controllers/room_controller.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7
const _jadeMidLight = Color(0xFF1B7E94);

class PropertyPricingScreen extends ConsumerStatefulWidget {
  final String homestayId;

  const PropertyPricingScreen({super.key, required this.homestayId});

  @override
  ConsumerState<PropertyPricingScreen> createState() =>
      _PropertyPricingScreenState();
}

class _PropertyPricingScreenState extends ConsumerState<PropertyPricingScreen> {
  final _weekdayCtrl = TextEditingController();
  final _weekendCtrl = TextEditingController();
  final _holidayCtrl = TextEditingController();
  final _adultSurchargeCtrl = TextEditingController();
  final _childSurchargeCtrl = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _weekdayCtrl.dispose();
    _weekendCtrl.dispose();
    _holidayCtrl.dispose();
    _adultSurchargeCtrl.dispose();
    _childSurchargeCtrl.dispose();
    super.dispose();
  }

  void _initFromRoom() {
    if (_initialized) return;
    final room = ref.read(roomDetailProvider(widget.homestayId)).valueOrNull;
    if (room == null) return;
    _initialized = true;
    _weekdayCtrl.text = _fmtVnd(room.price?.weekdayPrice);
    _weekendCtrl.text = _fmtVnd(room.price?.saturdayPrice);
    _holidayCtrl.text = _fmtVnd(room.price?.holidayPrice);
    _adultSurchargeCtrl.text = _fmtVnd(room.adultSurcharge);
    _childSurchargeCtrl.text = _fmtVnd(room.childSurcharge);
  }

  String _fmtVnd(double? v) {
    if (v == null || v == 0) return '';
    final digits = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  int _parseVnd(String text) => int.tryParse(text.replaceAll('.', '')) ?? 0;

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    final data = <String, dynamic>{};
    if (_weekdayCtrl.text.isNotEmpty) {
      data['weekdayPrice'] = _parseVnd(_weekdayCtrl.text);
    }
    if (_weekendCtrl.text.isNotEmpty) {
      data['weekendPrice'] = _parseVnd(_weekendCtrl.text);
    }
    if (_holidayCtrl.text.isNotEmpty) {
      data['holidayPrice'] = _parseVnd(_holidayCtrl.text);
    }
    if (_adultSurchargeCtrl.text.isNotEmpty) {
      data['adultSurcharge'] = _parseVnd(_adultSurchargeCtrl.text);
    }
    if (_childSurchargeCtrl.text.isNotEmpty) {
      data['childSurcharge'] = _parseVnd(_childSurchargeCtrl.text);
    }

    final ok = await ref
        .read(roomActionsProvider.notifier)
        .upsertPrice(widget.homestayId, data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      AppSnackBar.success(context, 'Đã lưu bảng giá');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(context, 'Có lỗi xảy ra');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final roomAsync = ref.watch(roomDetailProvider(widget.homestayId));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colors.bgCanvas,
        appBar: AppBar(title: const Text('Bảng giá')),
        body: roomAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorStateWidget(
            message: e.toString().replaceAll('Exception: ', ''),
            onRetry: () =>
                ref.invalidate(roomDetailProvider(widget.homestayId)),
          ),
          data: (_) {
            _initFromRoom();
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _section(context, 'GIÁ PHÒNG'),
                const SizedBox(height: AppSpacing.sm),
                _field(
                    context, _weekdayCtrl, 'Giá ngày thường (T2-T6)', 'đ/đêm'),
                const SizedBox(height: AppSpacing.md),
                _field(context, _weekendCtrl, 'Giá cuối tuần (T7-CN)', 'đ/đêm'),
                const SizedBox(height: AppSpacing.md),
                _field(context, _holidayCtrl, 'Giá ngày lễ', 'đ/đêm'),
                const SizedBox(height: AppSpacing.xl),
                _section(context, 'PHỤ THU'),
                const SizedBox(height: AppSpacing.sm),
                _field(context, _adultSurchargeCtrl, 'Phụ thu người lớn',
                    'đ/người'),
                const SizedBox(height: AppSpacing.md),
                _field(
                    context, _childSurchargeCtrl, 'Phụ thu trẻ em', 'đ/người'),
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          },
        ),
        bottomNavigationBar: _saveBtn(context),
      ),
    );
  }

  Widget _section(BuildContext context, String t) {
    final colors = context.colors;
    return Text(t,
        style: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          letterSpacing: 1.2,
        ));
  }

  Widget _field(BuildContext context, TextEditingController c, String label,
      String suffix) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [VndInputFormatter()],
          style:
              GoogleFonts.beVietnamPro(fontSize: 14, color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: colors.textSecondary.withValues(alpha: 0.6)),
            suffixText: suffix,
            suffixStyle: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _saveBtn(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark
        ? const [AppColors.darkBg, AppColors.darkBorder]
        : const [AppColors.jade500, _jadeMidLight];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Lưu',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      )),
            ),
          ),
        ),
      ),
    );
  }
}
