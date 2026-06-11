import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;
import '../../../core/utils/vnd_input_formatter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/subscription_locked_sheet.dart';
import '../../rooms/controllers/room_controller.dart';
import '../controllers/property_controller.dart';

class PropertyAddScreen extends ConsumerStatefulWidget {
  const PropertyAddScreen({super.key});

  @override
  ConsumerState<PropertyAddScreen> createState() => _PropertyAddScreenState();
}

class _PropertyAddScreenState extends ConsumerState<PropertyAddScreen> {
  final _formKey = GlobalKey<FormState>();

  // Property type (0=VILLA, 1=HOMESTAY, 2=HOTEL)
  int _selectedType = 0;

  final List<File> _pickedImages = [];

  // View (null = none, "sea" = sea view, "city" = city view)
  String? _selectedView;

  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();

  int _bedrooms = 5;
  int _bathrooms = 2;

  final _standardGuestsCtrl = TextEditingController();
  final _maxGuestsCtrl = TextEditingController();

  final _weekdayPriceCtrl = TextEditingController();
  final _weekendPriceCtrl = TextEditingController();
  final _holidayPriceCtrl = TextEditingController();

  final _adultSurchargeCtrl = TextEditingController();
  final _childSurchargeCtrl = TextEditingController();

  final Set<String> _selectedAmenities = {};

  // Pre-filled default rules text.
  final _rulesCtrl = TextEditingController(
    text: 'Check-in sau 14:00, check-out trước 12:00.\n'
        'Không hút thuốc trong phòng.\n'
        'Giữ gìn vệ sinh chung.\n'
        'Không gây tiếng ồn sau 22:00.',
  );
  final _notesCtrl = TextEditingController(
    text: 'Ưu tiên bán cặp cuối tuần (T6-T7, T7-CN).\n'
        'Ngày lễ áp dụng giá lễ, tối thiểu 2 đêm.',
  );

  // Cancellation policy (0=FLEXIBLE, 1=MODERATE, 2=STRICT).
  int _cancellationPolicy = 0;

  bool _isLoading = false;

  // 0=VILLA, 1=HOMESTAY, 2=HOTEL
  static const _typeOptions = [
    (value: 0, label: 'Villa', icon: Icons.villa_rounded),
    (value: 1, label: 'Homestay', icon: Icons.cottage_rounded),
    (value: 2, label: 'Khách sạn', icon: Icons.hotel_rounded),
  ];

  static const _amenityGroups = {
    'Phòng khách': [
      'Điều hòa',
      'Wifi',
      'TV',
      'Karaoke',
      'Loa di động',
    ],
    'Bếp & Ăn uống': [
      'Bếp đầy đủ',
      'Tủ lạnh',
      'Lò vi sóng',
      'Bếp từ',
      'BBQ ngoài trời',
      'Bát đũa',
      'Nước lọc free',
    ],
    'Phòng ngủ & Tắm': [
      'Bồn tắm',
      'Vòi sen',
      'Nước nóng',
      'Máy sấy tóc',
      'Đèn sưởi',
      'Khăn tắm',
      'Dầu gội/Sữa tắm',
    ],
    'Ngoài trời': [
      'Bể bơi',
      'Ban công',
      'View biển',
      'Sân vườn',
      'Sân thượng',
      'Đỗ xe',
    ],
    'Tiện ích chung': [
      'Máy giặt',
      'Bàn là',
      'Tủ quần áo',
      'Két sắt',
      'Thang máy',
    ],
    'Giải trí': [
      'Bida',
      'Bàn bóng bàn',
      'Xích đu',
      'Khu vui chơi trẻ em',
    ],
  };

  // 0=FLEXIBLE, 1=MODERATE, 2=STRICT
  static const _cancellationPolicies = [
    (value: 0, label: 'Linh hoạt', desc: 'Hoàn 100% nếu huỷ trước 1 ngày'),
    (value: 1, label: 'Vừa phải', desc: 'Hoàn 100% nếu huỷ trước 7 ngày'),
    (value: 2, label: 'Nghiêm ngặt', desc: 'Không hoàn tiền sau khi đặt'),
  ];

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _mapLinkCtrl.dispose();
    _rulesCtrl.dispose();
    _notesCtrl.dispose();
    // _bathrooms is an int field, no controller to dispose
    _standardGuestsCtrl.dispose();
    _maxGuestsCtrl.dispose();
    _weekdayPriceCtrl.dispose();
    _weekendPriceCtrl.dispose();
    _holidayPriceCtrl.dispose();
    _adultSurchargeCtrl.dispose();
    _childSurchargeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty && mounted) {
      setState(() {
        for (final img in images) {
          if (_pickedImages.length < 20) {
            _pickedImages.add(File(img.path));
          }
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _nameCtrl.text.trim().isNotEmpty
          ? _nameCtrl.text.trim()
          : '$_selectedType ${_codeCtrl.text.trim()}',
      if (_descriptionCtrl.text.trim().isNotEmpty)
        'description': _descriptionCtrl.text.trim(),
      'type': _selectedType,
      'code': _codeCtrl.text.trim(),
      'bedrooms': _bedrooms,
      'bathrooms': _bathrooms,
      'standardGuests': int.tryParse(_standardGuestsCtrl.text) ?? _bedrooms * 2,
      'maxGuests': int.tryParse(_maxGuestsCtrl.text) ?? _bedrooms * 2,
      'amenities': _selectedAmenities.toList(),
      'cancellationPolicy': _cancellationPolicy,
      if (_selectedView != null) 'view': _selectedView,
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (_rulesCtrl.text.trim().isNotEmpty)
        'rules': _notesCtrl.text.trim().isNotEmpty
            ? '${_rulesCtrl.text.trim()}\n\n--- LƯU Ý ---\n${_notesCtrl.text.trim()}'
            : _rulesCtrl.text.trim(),
      if (_mapLinkCtrl.text.trim().isNotEmpty)
        'mapLink': _mapLinkCtrl.text.trim(),
      if (_weekdayPriceCtrl.text.isNotEmpty)
        'weekdayPrice': _parsePrice(_weekdayPriceCtrl.text),
      if (_weekendPriceCtrl.text.isNotEmpty)
        'weekendPrice': _parsePrice(_weekendPriceCtrl.text),
      if (_holidayPriceCtrl.text.isNotEmpty)
        'holidayPrice': _parsePrice(_holidayPriceCtrl.text),
      if (_adultSurchargeCtrl.text.isNotEmpty)
        'adultSurcharge': _parsePrice(_adultSurchargeCtrl.text),
      if (_childSurchargeCtrl.text.isNotEmpty)
        'childSurcharge': _parsePrice(_childSurchargeCtrl.text),
    };

    final propertyId =
        await ref.read(homestayActionsProvider.notifier).create(data);

    if (!mounted) return;

    if (propertyId != null) {
      // Upload images if any.
      if (_pickedImages.isNotEmpty) {
        final paths = _pickedImages.map((f) => f.path).toList();
        final (imgOk, imgErr) = await ref
            .read(roomActionsProvider.notifier)
            .uploadImages(propertyId, paths);
        if (mounted && !imgOk) {
          AppSnackBar.error(
            context,
            'Tạo phòng OK nhưng upload ảnh thất bại: $imgErr',
          );
        }
      }
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.success(context, 'Tạo phòng thành công');
      context.pop();
    } else {
      setState(() => _isLoading = false);
      final notifier = ref.read(homestayActionsProvider.notifier);
      final err = ref.read(homestayActionsProvider);
      final msg = err.hasError ? err.error.toString() : 'Có lỗi xảy ra';
      // BE 403 subscription.featureLocked → platform-aware sheet (iOS: contact
      // support, no payment wording; Android: route to plan picker).
      if (!SubscriptionLock.maybeHandle(context,
          code: notifier.lastErrorCode, message: msg)) {
        AppSnackBar.error(context, msg);
      }
    }
  }

  double _parsePrice(String text) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0;
  }

  bool _isGroupAllSelected(List<String> items) =>
      items.every((a) => _selectedAmenities.contains(a));

  void _toggleGroup(List<String> items) {
    setState(() {
      if (_isGroupAllSelected(items)) {
        for (final a in items) {
          _selectedAmenities.remove(a);
        }
      } else {
        _selectedAmenities.addAll(items);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm phòng')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('LOẠI HÌNH *'),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      spacing: 8,
                      children: _typeOptions.map((t) {
                        final on = _selectedType == t.value;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedType = t.value),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: on ? colors.brand : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                      color: on
                                          ? colors.brand
                                          : colors.borderDefault),
                                ),
                                child: Column(
                                  children: [
                                    Icon(t.icon,
                                        size: 26,
                                        color: on
                                            ? Colors.white
                                            : colors.textSecondary),
                                    const SizedBox(height: 6),
                                    Text(t.label,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: on
                                              ? Colors.white
                                              : colors.textSecondary,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _Title('ẢNH PHÒNG'),
                        const Spacer(),
                        Text('${_pickedImages.length}/20',
                            style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Text('Ảnh đầu tiên sẽ là ảnh bìa',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ..._pickedImages.asMap().entries.map((e) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  child: Image.file(e.value,
                                      width: 80, height: 80, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _pickedImages.removeAt(e.key)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                          color: colors.error,
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                                if (e.key == 0)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            colors.brand.withValues(alpha: 0.8),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft:
                                              Radius.circular(AppRadius.sm),
                                          bottomRight:
                                              Radius.circular(AppRadius.sm),
                                        ),
                                      ),
                                      child: Text('Ảnh bìa',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.beVietnamPro(
                                              fontSize: 8,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                              ],
                            )),
                        if (_pickedImages.length < 20)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: colors.brand, width: 1.5),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      color: colors.brand, size: 28),
                                  Text('Thêm ảnh',
                                      style: GoogleFonts.beVietnamPro(
                                          fontSize: 10,
                                          color: colors.brand,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('THÔNG TIN CƠ BẢN'),
                    const SizedBox(height: AppSpacing.sm),
                    _Field(
                        ctrl: _codeCtrl,
                        label: 'Mã căn *',
                        hint: 'VD: C3-06',
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Nhập mã căn' : null),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                        ctrl: _nameCtrl,
                        label: 'Tên hiển thị',
                        hint: 'VD: Villa Vịnh Xanh'),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                      ctrl: _descriptionCtrl,
                      label: 'Mô tả',
                      hint: 'Mô tả ngắn về phòng...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('View',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                            label: 'Không có',
                            on: _selectedView == null,
                            onTap: () => setState(() => _selectedView = null)),
                        _Chip(
                            label: 'View biển',
                            on: _selectedView == 'sea',
                            onTap: () => setState(() => _selectedView = 'sea')),
                        _Chip(
                            label: 'View thành phố',
                            on: _selectedView == 'city',
                            onTap: () =>
                                setState(() => _selectedView = 'city')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                        ctrl: _addressCtrl,
                        label: 'Khu vực / Địa chỉ',
                        hint: 'VD: Bãi Cháy, Hạ Long'),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                        ctrl: _mapLinkCtrl,
                        label: 'Link Google Maps',
                        hint: 'Dán link Google Maps tại đây'),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('THÔNG SỐ PHÒNG'),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Số phòng ngủ *',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                            label: 'Studio',
                            on: _bedrooms == 0,
                            onTap: () => setState(() => _bedrooms = 0)),
                        for (var i = 1; i <= 9; i++)
                          _Chip(
                              label: '${i}PN',
                              on: _bedrooms == i,
                              onTap: () => setState(() => _bedrooms = i)),
                        _Chip(
                            label: '10PN+',
                            on: _bedrooms >= 10,
                            onTap: () => setState(() => _bedrooms = 10)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Số nhà tắm / WC *',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 1; i <= 9; i++)
                          _Chip(
                              label: '$i WC',
                              on: _bathrooms == i,
                              onTap: () => setState(() => _bathrooms = i)),
                        _Chip(
                            label: '10+',
                            on: _bathrooms >= 10,
                            onTap: () => setState(() => _bathrooms = 10)),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

              _Section(
                highlighted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('SỨC CHỨA'),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                            child: _Field(
                                ctrl: _standardGuestsCtrl,
                                label: 'Tiêu chuẩn',
                                hint: 'VD: 10',
                                keyboard: TextInputType.number)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                            child: _Field(
                                ctrl: _maxGuestsCtrl,
                                label: 'Tối đa',
                                hint: 'VD: 20',
                                keyboard: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Khách vượt tiêu chuẩn sẽ tính phụ thu',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: colors.textSecondary,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('BẢNG GIÁ'),
                    const SizedBox(height: AppSpacing.sm),
                    _Field(
                        ctrl: _weekdayPriceCtrl,
                        label: 'Ngày thường (T2-T5)',
                        hint: '1.300.000',
                        keyboard: TextInputType.number,
                        inputFormatters: [VndInputFormatter()],
                        suffix: '₫'),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                        ctrl: _weekendPriceCtrl,
                        label: 'Cuối tuần (T6-CN)',
                        hint: '1.500.000',
                        keyboard: TextInputType.number,
                        inputFormatters: [VndInputFormatter()],
                        suffix: '₫'),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                        ctrl: _holidayPriceCtrl,
                        label: 'Ngày lễ / Cao điểm',
                        hint: '2.000.000',
                        keyboard: TextInputType.number,
                        inputFormatters: [VndInputFormatter()],
                        suffix: '₫'),
                  ],
                ),
              ).animate(delay: 250.ms).fadeIn(duration: 300.ms),

              _Section(
                highlighted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('PHỤ THU'),
                    const SizedBox(height: AppSpacing.sm),
                    _Field(
                        ctrl: _adultSurchargeCtrl,
                        label: 'Người lớn (> 11 tuổi)',
                        hint: '250.000',
                        keyboard: TextInputType.number,
                        inputFormatters: [VndInputFormatter()],
                        suffix: '₫'),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                        ctrl: _childSurchargeCtrl,
                        label: 'Trẻ em (7-11 tuổi)',
                        hint: '150.000',
                        keyboard: TextInputType.number,
                        inputFormatters: [VndInputFormatter()],
                        suffix: '₫'),
                    const SizedBox(height: 6),
                    Text('Trẻ em dưới 6 tuổi: Miễn phí',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: colors.textSecondary,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 300.ms),

              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _Title('TIỆN NGHI'),
                        const Spacer(),
                        Text('${_selectedAmenities.length} đã chọn',
                            style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    ..._amenityGroups.entries.map((g) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Text(g.key,
                                    style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textSecondary)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _toggleGroup(g.value),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: _isGroupAllSelected(g.value)
                                              ? colors.brand
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: _isGroupAllSelected(g.value)
                                                ? colors.brand
                                                : colors.borderStrong,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: _isGroupAllSelected(g.value)
                                            ? const Icon(Icons.check_rounded,
                                                size: 12, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        _isGroupAllSelected(g.value)
                                            ? 'Bỏ tất cả'
                                            : 'Chọn tất cả',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: _isGroupAllSelected(g.value)
                                              ? colors.brand
                                              : colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: g.value.map((a) {
                                final on = _selectedAmenities.contains(a);
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    on
                                        ? _selectedAmenities.remove(a)
                                        : _selectedAmenities.add(a);
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: on
                                          ? colors.brand.withValues(alpha: 0.1)
                                          : colors.bgSurface,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.full),
                                      border: Border.all(
                                          color: on
                                              ? colors.brand
                                              : colors.borderDefault),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (on) ...[
                                          Icon(Icons.check_rounded,
                                              size: 14, color: colors.brand),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(a,
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 12,
                                              fontWeight: on
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: on
                                                  ? colors.brand
                                                  : colors.textPrimary,
                                            )),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        )),
                  ],
                ),
              ).animate(delay: 350.ms).fadeIn(duration: 300.ms),

              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('CHÍNH SÁCH HUỶ'),
                    const SizedBox(height: AppSpacing.sm),
                    ..._cancellationPolicies.map((p) {
                      final on = _cancellationPolicy == p.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _cancellationPolicy = p.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: on
                                  ? colors.brand.withValues(alpha: 0.08)
                                  : colors.bgSurface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: on ? colors.brand : colors.borderDefault,
                                width: on ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  on
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color:
                                      on ? colors.brand : colors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.label,
                                        style: GoogleFonts.beVietnamPro(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary)),
                                    Text(p.desc,
                                        style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            color: colors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 300.ms),

              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('QUY ĐỊNH'),
                    const SizedBox(height: AppSpacing.sm),
                    _Field(
                      ctrl: _rulesCtrl,
                      label: 'Nội quy phòng',
                      hint: 'Nhập quy định...',
                      maxLines: 6,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Field(
                      ctrl: _notesCtrl,
                      label: 'Lưu ý bán phòng',
                      hint: 'VD: Ưu tiên bán cặp cuối tuần...',
                      maxLines: 4,
                    ),
                  ],
                ),
              ).animate(delay: 450.ms).fadeIn(duration: 300.ms),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isLoading
                      ? Center(
                          child: SizedBox(
                              height: 52,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: colors.brand))))
                      : FilledButton(
                          key: const ValueKey('save-btn'),
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.brand,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                          ),
                          child: Text('Lưu phòng',
                              style: GoogleFonts.beVietnamPro(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                ),
              ).animate(delay: 450.ms).fadeIn(duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final Widget child;
  final bool highlighted;
  const _Section({required this.child, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? (isDark
                ? colors.brand.withValues(alpha: 0.05)
                : AppColors.jade100.withValues(alpha: 0.3))
            : colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: highlighted
            ? Border.all(color: colors.brand.withValues(alpha: 0.3))
            : null,
        boxShadow: highlighted
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: child,
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.beVietnamPro(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.colors.textBrand,
          letterSpacing: 0.5));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffix;
  final int? maxLines;

  const _Field({
    required this.ctrl,
    required this.label,
    this.hint,
    this.keyboard,
    this.validator,
    this.inputFormatters,
    this.suffix,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
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
          controller: ctrl,
          keyboardType: maxLines != null && maxLines! > 1
              ? TextInputType.multiline
              : keyboard,
          maxLines: maxLines ?? 1,
          validator: validator,
          inputFormatters: inputFormatters,
          style: GoogleFonts.beVietnamPro(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.beVietnamPro(
                fontSize: 14, color: colors.textTertiary),
            suffixText: suffix,
            suffixStyle: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: on ? colors.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: on ? colors.brand : colors.borderDefault),
        ),
        child: Text(label,
            style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on ? Colors.white : colors.textPrimary)),
      ),
    );
  }
}
