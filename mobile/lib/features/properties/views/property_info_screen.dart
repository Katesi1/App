import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/number_input_dialog.dart';
import '../../rooms/controllers/room_controller.dart';

class PropertyInfoScreen extends ConsumerStatefulWidget {
  final String homestayId;

  const PropertyInfoScreen({super.key, required this.homestayId});

  @override
  ConsumerState<PropertyInfoScreen> createState() => _PropertyInfoScreenState();
}

class _PropertyInfoScreenState extends ConsumerState<PropertyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionCtrl;
  bool _isLoading = false;

  // Tất cả giá trị load từ API, nullable cho đến khi có data
  int? _bedrooms;
  int? _bathrooms;
  int? _standardGuests;
  int? _maxGuests;
  String? _selectedView;
  String _code = '';

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _descriptionCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _initFromRoom() {
    if (_initialized) return;
    final room = ref.read(roomDetailProvider(widget.homestayId)).valueOrNull;
    if (room == null) return;
    _initialized = true;
    _code = room.code;
    _descriptionCtrl.text = room.description ?? '';
    _bedrooms = room.bedrooms;
    _bathrooms = room.bathrooms;
    _standardGuests = room.standardGuests;
    _maxGuests = room.maxGuests;
    _selectedView = room.view;
  }

  /// Chọn loại phòng → tự điền WC + sức chứa theo tiêu chuẩn.
  /// Owner vẫn có thể chỉnh lại các giá trị bên dưới.
  /// Quy ước: Studio tính như 1 phòng ngủ.
  /// - WC = số phòng ngủ
  /// - Sức chứa tiêu chuẩn = tối đa = số phòng ngủ × 2
  void _selectBedrooms(int bedrooms) {
    setState(() {
      _bedrooms = bedrooms;
      final effective = bedrooms == 0 ? 1 : bedrooms;
      _bathrooms = effective;
      // Sức chứa hiển thị bằng chip 1–20 nên giữ trong dải đó.
      _standardGuests = (effective * 2).clamp(1, 20);
      _maxGuests = (effective * 2).clamp(1, 20);
    });
  }

  /// Nhập số phòng ngủ tuỳ ý khi nhiều hơn dải chip (10+).
  Future<void> _promptCustomBedrooms() async {
    final value = await showNumberInputDialog(
      context,
      title: 'Số phòng ngủ',
      hint: 'Nhập số phòng ngủ (VD: 12)',
      initial: (_bedrooms ?? 0) >= 10 ? _bedrooms : null,
    );
    if (value != null) _selectBedrooms(value);
  }

  /// Nhập số nhà tắm / WC tuỳ ý khi nhiều hơn dải chip (10+).
  Future<void> _promptCustomBathrooms() async {
    final value = await showNumberInputDialog(
      context,
      title: 'Số nhà tắm / WC',
      hint: 'Nhập số nhà tắm / WC (VD: 12)',
      initial: (_bathrooms ?? 0) >= 10 ? _bathrooms : null,
    );
    if (value != null) setState(() => _bathrooms = value);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'description': _descriptionCtrl.text.trim(),
      'bedrooms': _bedrooms,
      'bathrooms': _bathrooms,
      'standardGuests': _standardGuests,
      'maxGuests': _maxGuests,
      'view': _selectedView,
    };

    final ok = await ref
        .read(roomActionsProvider.notifier)
        .update(widget.homestayId, data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      AppSnackBar.success(context, 'Đã lưu thông tin');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(context, 'Có lỗi xảy ra, vui lòng thử lại');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final roomAsync = ref.watch(roomDetailProvider(widget.homestayId));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Thông tin chi tiết')),
        body: roomAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorStateWidget(
            message: e.toString().replaceAll('Exception: ', ''),
            onRetry: () =>
                ref.invalidate(roomDetailProvider(widget.homestayId)),
          ),
          data: (room) {
            _initFromRoom();
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // ── Mã căn (chỉ hiển thị) ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.bgSurfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tag_rounded, size: 18, color: colors.brand),
                        const SizedBox(width: 10),
                        Text('Mã căn: ',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: colors.textSecondary,
                            )),
                        Text(_code,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.textBrand,
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Mô tả ──
                  _label(context, 'Mô tả'),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 4,
                    style: GoogleFonts.beVietnamPro(fontSize: 14),
                    decoration:
                        _inputDecoration(context, 'Mô tả ngắn về phòng...'),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Số phòng ngủ ──
                  _label(context, 'Số phòng ngủ'),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(context, 'Studio', _bedrooms == 0,
                          () => _selectBedrooms(0)),
                      for (var i = 1; i <= 9; i++)
                        _chip(context, '${i}PN', _bedrooms == i,
                            () => _selectBedrooms(i)),
                      _chip(
                          context,
                          (_bedrooms ?? 0) >= 10 ? '${_bedrooms}PN' : '10PN+',
                          (_bedrooms ?? 0) >= 10,
                          _promptCustomBedrooms),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chọn loại phòng sẽ tự điền số WC và sức chứa theo tiêu '
                    'chuẩn — bạn có thể chỉnh lại bên dưới.',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11.5,
                      color: colors.textTertiary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Số nhà tắm / WC ──
                  _label(context, 'Số nhà tắm / WC'),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 1; i <= 9; i++)
                        _chip(context, '$i WC', _bathrooms == i,
                            () => setState(() => _bathrooms = i)),
                      _chip(
                          context,
                          (_bathrooms ?? 0) >= 10 ? '$_bathrooms WC' : '10+',
                          (_bathrooms ?? 0) >= 10,
                          _promptCustomBathrooms),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── View ──
                  _label(context, 'View'),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(context, 'Không có', _selectedView == null,
                          () => setState(() => _selectedView = null)),
                      _chip(context, 'View biển', _selectedView == 'sea',
                          () => setState(() => _selectedView = 'sea')),
                      _chip(context, 'View thành phố', _selectedView == 'city',
                          () => setState(() => _selectedView = 'city')),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Sức chứa tiêu chuẩn ──
                  _label(context, 'Sức chứa tiêu chuẩn (người)'),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 1; i <= 20; i++)
                        _chip(context, '$i', _standardGuests == i,
                            () => setState(() => _standardGuests = i)),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Sức chứa tối đa ──
                  _label(context, 'Sức chứa tối đa (người)'),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 1; i <= 20; i++)
                        _chip(context, '$i', _maxGuests == i,
                            () => setState(() => _maxGuests = i)),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.brandLight, colors.brand],
                  ),
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
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Lưu',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: context.colors.textPrimary,
      ),
    );
  }

  Widget _chip(
      BuildContext context, String label, bool on, VoidCallback onTap) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? colors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: on ? colors.brand : colors.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: on ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.beVietnamPro(
        fontSize: 14,
        color: colors.textTertiary,
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.sm),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
    );
  }
}
