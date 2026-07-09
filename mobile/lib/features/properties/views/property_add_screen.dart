import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show TextInputFormatter, LengthLimitingTextInputFormatter;
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
import '../../../shared/widgets/required_label.dart';
import '../../../shared/widgets/subscription_locked_sheet.dart';
import '../../rooms/controllers/room_controller.dart';
import '../controllers/property_controller.dart';

/// Vị trí cơ sở lấy từ GPS (lat/lng) + link Google Maps tự sinh.
class PickedLocation {
  final double latitude;
  final double longitude;

  const PickedLocation(this.latitude, this.longitude);

  /// Link Google Maps chuẩn để lưu vào `mapLink` (mở được cả web + app).
  String get mapLink =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}

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

  // Vị trí cơ sở lấy từ GPS (lat/lng + link).
  PickedLocation? _picked;
  bool _locating = false;

  int _bedrooms = 5;
  int _bathrooms = 5;

  final _standardGuestsCtrl = TextEditingController();
  final _standardChildrenCtrl = TextEditingController();
  final _maxGuestsCtrl = TextEditingController();

  // Trẻ em tự động = 1/2 người lớn cho tới khi OWNER tự sửa ô này.
  bool _autoFillChildren = true;

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

  /// Villa = loại hình lớn → tối thiểu 3 phòng ngủ + 3 WC.
  bool get _isVilla => _selectedType == 0;
  static const _villaMinRooms = 3;

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
    _rulesCtrl.dispose();
    _notesCtrl.dispose();
    // _bathrooms is an int field, no controller to dispose
    _standardGuestsCtrl.dispose();
    _standardChildrenCtrl.dispose();
    _maxGuestsCtrl.dispose();
    _weekdayPriceCtrl.dispose();
    _weekendPriceCtrl.dispose();
    _holidayPriceCtrl.dispose();
    _adultSurchargeCtrl.dispose();
    _childSurchargeCtrl.dispose();
    super.dispose();
  }

  // Khi nhập số người lớn → tự điền trẻ em = 1/2 (làm tròn xuống).
  // Chỉ tự điền khi OWNER chưa tự sửa ô trẻ em (vẫn cho phép sửa lại).
  void _onAdultsChanged(String value) {
    if (!_autoFillChildren) {
      return;
    }
    final adults = int.tryParse(value.trim()) ?? 0;
    _standardChildrenCtrl.text = (adults ~/ 2).toString();
  }

  @override
  void initState() {
    super.initState();
    // Điền sẵn nhà tắm + sức chứa theo số phòng ngủ mặc định.
    _applyRoomDefaults();
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

  /// Chọn loại hình → villa ép tối thiểu 3 phòng ngủ + 3 WC.
  void _selectType(int value) {
    setState(() {
      _selectedType = value;
      if (value == 0) {
        if (_bedrooms < _villaMinRooms) {
          _bedrooms = _villaMinRooms;
          _applyRoomDefaults();
        }
        if (_bathrooms < _villaMinRooms) {
          _bathrooms = _villaMinRooms;
        }
      }
    });
  }

  /// Chọn số phòng ngủ → tự điền nhà tắm + sức chứa cho bớt thao tác.
  void _selectBedrooms(int count) {
    setState(() {
      _bedrooms = count;
      _applyRoomDefaults();
    });
  }

  /// Quy ước tự điền: nhà tắm = số phòng ngủ (studio/1PN → 1 WC);
  /// tiêu chuẩn = tối đa = số phòng ngủ × 2 (studio tính như 1 phòng).
  /// Người dùng vẫn có thể chỉnh tay sau đó.
  void _applyRoomDefaults() {
    final effectiveRooms = _bedrooms == 0 ? 1 : _bedrooms;
    _bathrooms = effectiveRooms;
    final adults = effectiveRooms * 2;
    _standardGuestsCtrl.text = adults.toString();
    _maxGuestsCtrl.text = adults.toString();
    // Trẻ em = 1/2 người lớn cho tới khi OWNER tự sửa ô này.
    if (_autoFillChildren) {
      _standardChildrenCtrl.text = (adults ~/ 2).toString();
    }
  }

  /// Bottom sheet nhập số phòng ngủ lớn (≥10).
  Future<void> _openBedroomCountSheet() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BedroomCountSheet(
        initial: _bedrooms >= 10 ? _bedrooms : 10,
      ),
    );
    if (result != null) _selectBedrooms(result);
  }

  /// Lấy vị trí hiện tại (GPS) ghim cho cơ sở. Không cần Google Maps/billing.
  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          AppSnackBar.error(context, 'Vui lòng bật dịch vụ vị trí (GPS)');
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppSnackBar.error(context, 'Chưa cấp quyền truy cập vị trí');
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() => _picked = PickedLocation(pos.latitude, pos.longitude));
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Không lấy được vị trí hiện tại');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // Guard tường minh: form trong ListView build lười nên field giá có thể
    // chưa được validate khi nằm ngoài viewport → check lại giá ngày thường.
    if (_parsePrice(_weekdayPriceCtrl.text) <= 0) {
      AppSnackBar.error(context, 'Vui lòng nhập giá ngày thường lớn hơn 0');
      return;
    }
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
      'standardChildren': int.tryParse(_standardChildrenCtrl.text) ?? 0,
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
      if (_picked != null) ...{
        'latitude': _picked!.latitude,
        'longitude': _picked!.longitude,
        'mapLink': _picked!.mapLink,
      },
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

  /// Giá ngày thường bắt buộc + phải > 0.
  String? _validateRequiredPrice(String? v) {
    final raw = (v ?? '').replaceAll('.', '').replaceAll(',', '').trim();
    if (raw.isEmpty) return 'Nhập giá phòng';
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return 'Giá phải lớn hơn 0';
    return null;
  }

  /// Giá cuối tuần / ngày lễ không bắt buộc, nhưng nếu nhập thì phải > 0.
  String? _validateOptionalPrice(String? v) {
    final raw = (v ?? '').replaceAll('.', '').replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return 'Giá phải lớn hơn 0';
    return null;
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
                              onTap: () => _selectType(t.value),
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
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(20),
                        ],
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
                    Text('Vị trí cơ sở',
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    _LocationTile(
                      picked: _picked,
                      loading: _locating,
                      onTap: _useCurrentLocation,
                      onClear: () => setState(() => _picked = null),
                    ),
                  ],
                ),
              ).animate(delay: 100.ms).fadeIn(duration: 300.ms),
              _Section(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('THÔNG SỐ PHÒNG'),
                    const SizedBox(height: AppSpacing.sm),
                    RequiredLabel('Số phòng ngủ *',
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
                            enabled: !_isVilla,
                            onTap: () => _selectBedrooms(0)),
                        for (var i = 1; i <= 9; i++)
                          _Chip(
                              label: '${i}PN',
                              on: _bedrooms == i,
                              enabled: !_isVilla || i >= _villaMinRooms,
                              onTap: () => _selectBedrooms(i)),
                        _Chip(
                            label: _bedrooms >= 10 ? '${_bedrooms}PN' : '10PN+',
                            on: _bedrooms >= 10,
                            onTap: _openBedroomCountSheet),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    RequiredLabel('Số nhà tắm / WC *',
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
                              enabled: !_isVilla || i >= _villaMinRooms,
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
                                label: 'Người lớn',
                                hint: 'VD: 10',
                                keyboard: TextInputType.number,
                                onChanged: _onAdultsChanged)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                            child: _Field(
                                ctrl: _standardChildrenCtrl,
                                label: 'Trẻ em',
                                hint: 'VD: 2',
                                keyboard: TextInputType.number,
                                onChanged: (_) => _autoFillChildren = false)),
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
                    Text(
                        'Người lớn + trẻ em là sức chứa tiêu chuẩn (đã bao '
                        'trong giá); khách vượt sẽ tính phụ thu',
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
                        label: 'Ngày thường (T2-T5) *',
                        hint: '1.300.000',
                        keyboard: TextInputType.number,
                        inputFormatters: [VndInputFormatter()],
                        validator: _validateRequiredPrice,
                        suffix: '₫'),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                        ctrl: _weekendPriceCtrl,
                        label: 'Cuối tuần (T6-CN)',
                        hint: '1.500.000',
                        keyboard: TextInputType.number,
                        inputFormatters: [VndInputFormatter()],
                        validator: _validateOptionalPrice,
                        suffix: '₫'),
                    const SizedBox(height: AppSpacing.md),
                    _Field(
                        ctrl: _holidayPriceCtrl,
                        label: 'Ngày lễ / Cao điểm',
                        hint: '2.000.000',
                        keyboard: TextInputType.number,
                        inputFormatters: [VndInputFormatter()],
                        validator: _validateOptionalPrice,
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
  Widget build(BuildContext context) => RequiredLabel(text,
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
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.ctrl,
    required this.label,
    this.hint,
    this.keyboard,
    this.validator,
    this.inputFormatters,
    this.suffix,
    this.maxLines,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequiredLabel(label,
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
          onChanged: onChanged,
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
  final bool enabled;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.on,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
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
      ),
    );
  }
}

/// Nút lấy vị trí hiện tại (GPS) cho cơ sở — không cần Google Maps/billing.
class _LocationTile extends StatelessWidget {
  final PickedLocation? picked;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _LocationTile({
    required this.picked,
    required this.loading,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final has = picked != null;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: has ? colors.brand.withValues(alpha: 0.08) : colors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: has ? colors.brand : colors.borderDefault,
            width: has ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (loading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: colors.brand),
              )
            else
              Icon(has ? Icons.place_rounded : Icons.my_location_rounded,
                  color: has ? colors.brand : colors.textSecondary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loading
                        ? 'Đang lấy vị trí...'
                        : (has ? 'Đã ghim vị trí' : 'Lấy vị trí hiện tại'),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: has ? colors.textPrimary : colors.textSecondary,
                    ),
                  ),
                  if (has && !loading) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${picked!.latitude.toStringAsFixed(6)}, '
                      '${picked!.longitude.toStringAsFixed(6)}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (has && !loading)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 20, color: colors.textSecondary),
              )
            else if (!loading)
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet nhập số phòng ngủ lớn (≥10) với stepper + nhập tay.
class _BedroomCountSheet extends StatefulWidget {
  final int initial;
  const _BedroomCountSheet({required this.initial});

  @override
  State<_BedroomCountSheet> createState() => _BedroomCountSheetState();
}

class _BedroomCountSheetState extends State<_BedroomCountSheet> {
  static const _min = 10;
  static const _max = 99;
  late int _count = widget.initial.clamp(_min, _max);

  void _set(int v) => setState(() => _count = v.clamp(_min, _max));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Số phòng ngủ',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary)),
          const SizedBox(height: 4),
          Text('Nhập số phòng ngủ cho cơ sở lớn (từ 10 trở lên)',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13, color: colors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepperBtn(
                icon: Icons.remove_rounded,
                enabled: _count > _min,
                onTap: () => _set(_count - 1),
              ),
              Column(
                children: [
                  Text('$_count',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: colors.brand)),
                  Text('phòng ngủ',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 12, color: colors.textSecondary)),
                ],
              ),
              _StepperBtn(
                icon: Icons.add_rounded,
                enabled: _count < _max,
                onTap: () => _set(_count + 1),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_count),
            style: FilledButton.styleFrom(
              backgroundColor: colors.brand,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text('Xác nhận',
                style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepperBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color:
              enabled ? colors.brand.withValues(alpha: 0.1) : colors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border:
              Border.all(color: enabled ? colors.brand : colors.borderDefault),
        ),
        child: Icon(icon,
            color: enabled ? colors.brand : colors.textSecondary, size: 26),
      ),
    );
  }
}
