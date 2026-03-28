import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/homestay_repository.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/homestay_controller.dart';

class HomestayFormScreen extends ConsumerStatefulWidget {
  final String? homestayId;
  const HomestayFormScreen({super.key, this.homestayId});

  @override
  ConsumerState<HomestayFormScreen> createState() => _HomestayFormScreenState();
}

class _HomestayFormScreenState extends ConsumerState<HomestayFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  bool _isLoading = false;

  bool get _isEdit => widget.homestayId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadHomestay();
  }

  Future<void> _loadHomestay() async {
    final result = await HomestayRepository().getHomestay(widget.homestayId!);
    if (result.success && mounted) {
      final h = result.data!;
      _nameCtrl.text = h.name;
      _addressCtrl.text = h.address;
      _mapLinkCtrl.text = h.mapLink ?? '';
      _latCtrl.text = h.latitude?.toString() ?? '';
      _lngCtrl.text = h.longitude?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _mapLinkCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      if (_mapLinkCtrl.text.trim().isNotEmpty)
        'mapLink': _mapLinkCtrl.text.trim(),
      if (_latCtrl.text.trim().isNotEmpty)
        'latitude': double.tryParse(_latCtrl.text.trim()),
      if (_lngCtrl.text.trim().isNotEmpty)
        'longitude': double.tryParse(_lngCtrl.text.trim()),
    };

    final ok = _isEdit
        ? await ref
            .read(homestayActionsProvider.notifier)
            .update(widget.homestayId!, data)
        : await ref.read(homestayActionsProvider.notifier).create(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      AppSnackBar.success(context,
          _isEdit ? 'Cập nhật homestay thành công' : 'Tạo homestay thành công');
      context.pop();
    } else {
      final err = ref.read(homestayActionsProvider);
      AppSnackBar.error(
          context, err.hasError ? err.error.toString() : 'Có lỗi xảy ra');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa homestay' : 'Thêm homestay mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Tên homestay *',
                  prefixIcon:
                      Icon(Icons.home_work_outlined, color: colors.primary),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Nhập tên homestay' : null,
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.md),

              // Address
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ *',
                  prefixIcon:
                      Icon(Icons.location_on_outlined, color: colors.primary),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Nhập địa chỉ' : null,
              ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.md),

              // Map link
              TextFormField(
                controller: _mapLinkCtrl,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Link Google Maps',
                  hintText: 'https://maps.google.com/...',
                  prefixIcon: Icon(Icons.map_outlined, color: colors.primary),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!v.trim().startsWith('http')) return 'URL không hợp lệ';
                  return null;
                },
              ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.lg),

              // Lat/Lng section
              Text(
                'Toạ độ GPS (tuỳ chọn)',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.my_location_rounded,
                            color: colors.primary, size: 18),
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (double.tryParse(v.trim()) == null) {
                          return 'Số không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icon(Icons.my_location_rounded,
                            color: colors.primary, size: 18),
                        isDense: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (double.tryParse(v.trim()) == null) {
                          return 'Số không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.xl),

              // Save button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
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
                        icon: Icon(
                            _isEdit ? Icons.save_rounded : Icons.add_rounded),
                        label: Text(
                          _isEdit ? 'Lưu thay đổi' : 'Tạo homestay',
                          style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
              ).animate(delay: 250.ms).fadeIn(duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
