import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../properties/controllers/property_controller.dart';
import '../controllers/room_controller.dart';

class RoomFormScreen extends ConsumerStatefulWidget {
  final String? roomId;
  final String? homestayId;

  const RoomFormScreen({super.key, this.roomId, this.homestayId});

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Loại hình
  String _selectedType = 'VILLA';

  // Ảnh
  final List<File> _pickedImages = [];

  // Thông tin cơ bản
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();

  // Thông số phòng
  int _bedrooms = 5;
  final _bathroomCtrl = TextEditingController();

  // Sức chứa
  final _standardGuestsCtrl = TextEditingController();
  final _maxGuestsCtrl = TextEditingController();

  // Bảng giá
  final _weekdayPriceCtrl = TextEditingController();
  final _weekendPriceCtrl = TextEditingController();
  final _holidayPriceCtrl = TextEditingController();

  // Phụ thu
  final _adultSurchargeCtrl = TextEditingController();
  final _childSurchargeCtrl = TextEditingController();

  // Tiện nghi
  final Set<String> _selectedAmenities = {};

  // Chính sách huỷ
  String _cancellationPolicy = 'FLEXIBLE';

  // Homestay (ẩn — tự chọn hoặc truyền từ param)
  String? _selectedHomestayId;

  bool _isLoading = false;
  bool get _isEdit => widget.roomId != null;

  // ── Amenity groups ──
  static const _amenityGroups = {
    'Phòng khách': ['Điều hòa', 'Wifi', 'TV', 'Karaoke', 'Loa di động'],
    'Bếp & Ăn uống': [
      'Bếp đầy đủ',
      'Tủ lạnh',
      'BBQ ngoài trời',
      'Bát đũa 20 người',
      'Nước lọc free',
    ],
    'Phòng ngủ & Tắm': [
      'Bồn tắm',
      'Máy sấy tóc',
      'Đèn sưởi',
      'Khăn tắm',
      'Dầu gội/Sữa tắm',
    ],
    'Ngoài trời': ['Bể bơi', 'Ban công', 'View biển', 'Sân vườn', 'Đỗ xe'],
    'Giải trí': ['Bida', 'Bàn bóng bàn', 'Máy giặt', 'Bàn là'],
  };

  static const _cancellationPolicies = [
    (value: 'FLEXIBLE', label: 'Linh hoạt', desc: 'Hoàn 100% nếu huỷ trước 1 ngày'),
    (value: 'MODERATE', label: 'Vừa phải', desc: 'Hoàn 100% nếu huỷ trước 7 ngày'),
    (value: 'STRICT', label: 'Nghiêm ngặt', desc: 'Không hoàn tiền sau khi đặt'),
  ];

  static const _typeOptions = [
    (value: 'VILLA', label: 'Villa', icon: Icons.villa_rounded),
    (value: 'HOMESTAY', label: 'Homestay', icon: Icons.cottage_rounded),
    (value: 'APARTMENT', label: 'Căn hộ', icon: Icons.apartment_rounded),
    (value: 'HOTEL', label: 'Khách sạn', icon: Icons.hotel_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selectedHomestayId = widget.homestayId;
    if (_isEdit) _loadRoom();
  }

  Future<void> _loadRoom() async {
    final repo = ref.read(roomRepositoryProvider);
    final result = await repo.getRoomDetail(widget.roomId!);
    if (result.success && mounted) {
      final room = result.data!;
      _codeCtrl.text = room.code;
      _nameCtrl.text = room.name;
      _descriptionToFields(room);
      setState(() {
        _bedrooms = room.bedrooms;
        _maxGuestsCtrl.text = room.maxGuests > 0 ? '${room.maxGuests}' : '';
        _selectedHomestayId = room.homestayId;
      });
      if (room.price != null) {
        _weekdayPriceCtrl.text = _fmtPrice(room.price!.weekdayPrice);
        _weekendPriceCtrl.text = _fmtPrice(room.price!.saturdayPrice);
        _holidayPriceCtrl.text = _fmtPrice(room.price!.holidayPrice);
      }
    }
  }

  void _descriptionToFields(dynamic room) {
    // Placeholder — populate from room fields when API supports them
  }

  String _fmtPrice(double price) {
    if (price <= 0) return '';
    final str = price.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  double _parsePrice(String text) {
    final cleaned = text.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _mapLinkCtrl.dispose();
    _bathroomCtrl.dispose();
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

    // Auto-select first homestay nếu chưa có
    if (_selectedHomestayId == null) {
      final homestays = ref.read(homestayListProvider).valueOrNull;
      if (homestays != null && homestays.isNotEmpty) {
        _selectedHomestayId = homestays.first.id;
      } else {
        AppSnackBar.error(context, 'Chưa có homestay nào, vui lòng tạo trước');
        return;
      }
    }

    setState(() => _isLoading = true);

    final actions = ref.read(roomActionsProvider.notifier);

    // ── Room data — gửi đầy đủ tất cả fields ──
    final data = <String, dynamic>{
      'homestayId': _selectedHomestayId,
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim(),
      'type': _selectedType,
      'bedrooms': _bedrooms,
      'bathrooms': int.tryParse(_bathroomCtrl.text) ?? 1,
      'standardGuests': int.tryParse(_standardGuestsCtrl.text) ?? _bedrooms * 2,
      'maxGuests': int.tryParse(_maxGuestsCtrl.text) ?? _bedrooms * 2,
      'amenities': _selectedAmenities.toList(),
      'cancellationPolicy': _cancellationPolicy,
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (_mapLinkCtrl.text.trim().isNotEmpty)
        'mapLink': _mapLinkCtrl.text.trim(),
      if (_adultSurchargeCtrl.text.isNotEmpty)
        'adultSurcharge': _parsePrice(_adultSurchargeCtrl.text),
      if (_childSurchargeCtrl.text.isNotEmpty)
        'childSurcharge': _parsePrice(_childSurchargeCtrl.text),
    };

    String? roomId;

    if (_isEdit) {
      final ok = await actions.update(widget.roomId!, data);
      if (ok) roomId = widget.roomId;
    } else {
      final room = await actions.create(data);
      roomId = room?.id;
    }

    if (!mounted) return;

    if (roomId != null) {
      // Upload ảnh
      if (_pickedImages.isNotEmpty) {
        await actions.uploadImages(
            roomId, _pickedImages.map((f) => f.path).toList());
      }

      // Upsert bảng giá
      final priceData = <String, dynamic>{};
      if (_weekdayPriceCtrl.text.isNotEmpty) {
        priceData['weekdayPrice'] = _parsePrice(_weekdayPriceCtrl.text);
      }
      if (_weekendPriceCtrl.text.isNotEmpty) {
        final wp = _parsePrice(_weekendPriceCtrl.text);
        priceData['fridayPrice'] = wp;
        priceData['saturdayPrice'] = wp;
      }
      if (_holidayPriceCtrl.text.isNotEmpty) {
        priceData['holidayPrice'] = _parsePrice(_holidayPriceCtrl.text);
      }
      if (priceData.isNotEmpty) {
        await actions.upsertPrice(roomId, priceData);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.success(
          context, _isEdit ? 'Cập nhật thành công' : 'Tạo phòng thành công');
      context.pop();
    } else {
      setState(() => _isLoading = false);
      final errorMsg = ref.read(roomActionsProvider).asError?.error.toString() ?? 'Có lỗi xảy ra';
      AppSnackBar.error(context, errorMsg);
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa phòng' : 'Thêm phòng')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _buildTypeSection(),
            _buildImageSection(),
            _buildBasicInfoSection(),
            _buildRoomSpecSection(),
            _buildCapacitySection(),
            _buildPricingSection(),
            _buildSurchargeSection(),
            _buildAmenitySection(),
            _buildCancellationSection(),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ── LOẠI HÌNH * ──
  Widget _buildTypeSection() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('LOẠI HÌNH *'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _typeOptions.map((t) {
              final selected = _selectedType == t.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: t.value != 'HOTEL' ? 8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = t.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.ocean : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: selected ? AppColors.ocean : AppColors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(t.icon,
                              size: 26,
                              color: selected ? Colors.white : AppColors.muted),
                          const SizedBox(height: 6),
                          Text(
                            t.label,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : AppColors.muted,
                            ),
                          ),
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
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── ẢNH PHÒNG ──
  Widget _buildImageSection() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionTitle('ẢNH PHÒNG'),
              const Spacer(),
              Text('${_pickedImages.length}/20',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500)),
            ],
          ),
          Text('Ảnh đầu tiên sẽ là ảnh bìa',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._pickedImages.asMap().entries.map((e) => _ImageThumb(
                    file: e.value,
                    onRemove: () => setState(() => _pickedImages.removeAt(e.key)),
                  )),
              if (_pickedImages.length < 20) _AddImageBtn(onTap: _pickImages),
            ],
          ),
        ],
      ),
    ).animate(delay: 50.ms).fadeIn(duration: 300.ms);
  }

  // ── THÔNG TIN CƠ BẢN ──
  Widget _buildBasicInfoSection() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('THÔNG TIN CƠ BẢN'),
          const SizedBox(height: AppSpacing.sm),
          _Field(controller: _codeCtrl, label: 'Mã căn *', hint: 'VD: C3-06',
              validator: (v) => v?.trim().isEmpty == true ? 'Nhập mã căn' : null),
          const SizedBox(height: AppSpacing.md),
          _Field(controller: _nameCtrl, label: 'Tên hiển thị', hint: 'VD: Villa Vịnh Xanh'),
          const SizedBox(height: AppSpacing.md),
          _Field(controller: _addressCtrl, label: 'Địa chỉ',
              hint: 'VD: Bãi Cháy, Hạ Long, Quảng Ninh'),
          const SizedBox(height: AppSpacing.md),
          _Field(controller: _mapLinkCtrl, label: 'Link Google Maps',
              hint: 'Dán link Google Maps tại đây'),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 300.ms);
  }

  // ── THÔNG SỐ PHÒNG ──
  Widget _buildRoomSpecSection() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('THÔNG SỐ PHÒNG'),
          const SizedBox(height: AppSpacing.sm),
          Text('Số phòng ngủ *',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 2; i <= 9; i++)
                _ChipBtn(
                    label: '${i}PN',
                    selected: _bedrooms == i,
                    onTap: () => setState(() => _bedrooms = i)),
              _ChipBtn(
                  label: '10PN+',
                  selected: _bedrooms >= 10,
                  onTap: () => setState(() => _bedrooms = 10)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(controller: _bathroomCtrl, label: 'Số nhà tắm / WC', hint: 'VD: 5',
              keyboardType: TextInputType.number),
        ],
      ),
    ).animate(delay: 150.ms).fadeIn(duration: 300.ms);
  }

  // ── SỨC CHỨA ──
  Widget _buildCapacitySection() {
    return _Section(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('SỨC CHỨA'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _Field(
                  controller: _standardGuestsCtrl, label: 'Tiêu chuẩn', hint: 'VD: 10',
                  keyboardType: TextInputType.number)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _Field(
                  controller: _maxGuestsCtrl, label: 'Tối đa', hint: 'VD: 20',
                  keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Khách vượt tiêu chuẩn sẽ tính phụ thu',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic)),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 300.ms);
  }

  // ── BẢNG GIÁ ──
  Widget _buildPricingSection() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('BẢNG GIÁ'),
          const SizedBox(height: AppSpacing.sm),
          _Field(controller: _weekdayPriceCtrl, label: 'Ngày thường (T2-T5)',
              hint: '1.300.000', keyboardType: TextInputType.number),
          const SizedBox(height: AppSpacing.md),
          _Field(controller: _weekendPriceCtrl, label: 'Cuối tuần (T6-CN)',
              hint: '1.500.000', keyboardType: TextInputType.number),
          const SizedBox(height: AppSpacing.md),
          _Field(controller: _holidayPriceCtrl, label: 'Ngày lễ / Cao điểm',
              hint: '2.000.000', keyboardType: TextInputType.number),
        ],
      ),
    ).animate(delay: 250.ms).fadeIn(duration: 300.ms);
  }

  // ── PHỤ THU ──
  Widget _buildSurchargeSection() {
    return _Section(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('PHỤ THU'),
          const SizedBox(height: AppSpacing.sm),
          _Field(controller: _adultSurchargeCtrl, label: 'Người lớn (> 11 tuổi)',
              hint: 'VD: 250.000', keyboardType: TextInputType.number),
          const SizedBox(height: AppSpacing.md),
          _Field(controller: _childSurchargeCtrl, label: 'Trẻ em (7-11 tuổi)',
              hint: 'VD: 150.000', keyboardType: TextInputType.number),
          const SizedBox(height: 6),
          Text('Trẻ em dưới 6 tuổi: Miễn phí',
              style: GoogleFonts.beVietnamPro(
                  fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic)),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 300.ms);
  }

  // ── TIỆN NGHI ──
  Widget _buildAmenitySection() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionTitle('TIỆN NGHI'),
              const Spacer(),
              Text('${_selectedAmenities.length} đã chọn',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500)),
            ],
          ),
          ..._amenityGroups.entries.map((group) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Text(group.key,
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: group.value.map((a) {
                      final on = _selectedAmenities.contains(a);
                      return GestureDetector(
                        onTap: () => setState(() {
                          on ? _selectedAmenities.remove(a) : _selectedAmenities.add(a);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: on
                                ? AppColors.teal.withValues(alpha: 0.1)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: on ? AppColors.teal : AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (on) ...[
                                const Icon(Icons.check_rounded, size: 14, color: AppColors.teal),
                                const SizedBox(width: 4),
                              ],
                              Text(a,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                                    color: on
                                        ? AppColors.teal
                                        : Theme.of(context).colorScheme.onSurface,
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
    ).animate(delay: 350.ms).fadeIn(duration: 300.ms);
  }

  // ── CHÍNH SÁCH HUỶ ──
  Widget _buildCancellationSection() {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('CHÍNH SÁCH HUỶ'),
          const SizedBox(height: AppSpacing.sm),
          ..._cancellationPolicies.map((p) {
            final on = _cancellationPolicy == p.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => setState(() => _cancellationPolicy = p.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: on ? AppColors.teal.withValues(alpha: 0.08) : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: on ? AppColors.teal : AppColors.border,
                      width: on ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        on ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        color: on ? AppColors.teal : AppColors.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.label,
                              style: GoogleFonts.beVietnamPro(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(p.desc,
                              style: GoogleFonts.beVietnamPro(
                                  fontSize: 12, color: AppColors.muted)),
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
    ).animate(delay: 400.ms).fadeIn(duration: 300.ms);
  }

  // ── LƯU PHÒNG ──
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isLoading
            ? const Center(
                child: SizedBox(
                    height: 52,
                    child: Center(
                        child: CircularProgressIndicator(color: AppColors.ocean))))
            : FilledButton(
                key: const ValueKey('save-btn'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ocean,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: Text('Lưu phòng',
                    style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
      ),
    ).animate(delay: 450.ms).fadeIn(duration: 300.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Section card (white card with optional highlight bg)
class _Section extends StatelessWidget {
  final Widget child;
  final bool highlighted;
  const _Section({required this.child, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? (isDark
                ? AppColors.teal.withValues(alpha: 0.05)
                : AppColors.tealLight.withValues(alpha: 0.3))
            : (isDark ? AppColors.darkContainer : Colors.white),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: highlighted
            ? Border.all(color: AppColors.teal.withValues(alpha: 0.3))
            : null,
        boxShadow: highlighted
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

/// Section title (ocean color, bold)
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.beVietnamPro(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ocean, letterSpacing: 0.5));
}

/// Standard text field matching the screenshots
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.beVietnamPro(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.beVietnamPro(
                fontSize: 14, color: AppColors.muted.withValues(alpha: 0.6)),
            filled: true,
            fillColor: isDark ? AppColors.darkContainer : AppColors.background,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

/// Bedroom / type chip
class _ChipBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.ocean : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: selected ? AppColors.ocean : AppColors.border),
          ),
          child: Text(label,
              style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.ink)),
        ),
      );
}

/// Image thumbnail with remove button
class _ImageThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _ImageThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      );
}

/// Add image button
class _AddImageBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _AddImageBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.teal, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_photo_alternate_outlined, color: AppColors.teal, size: 28),
              Text('Thêm ảnh',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 10, color: AppColors.teal, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}
