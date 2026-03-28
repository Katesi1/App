import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../homestays/controllers/homestay_controller.dart';
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
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _bedrooms = 1;
  int _maxGuests = 2;
  String? _selectedHomestayId;
  bool _isLoading = false;

  bool get _isEdit => widget.roomId != null;

  @override
  void initState() {
    super.initState();
    _selectedHomestayId = widget.homestayId;
    if (_isEdit) _loadRoom();
  }

  Future<void> _loadRoom() async {
    final result = await RoomRepository().getRoomDetail(widget.roomId!);
    if (result.success && mounted) {
      final room = result.data!;
      _nameCtrl.text = room.name;
      _codeCtrl.text = room.code;
      _descCtrl.text = room.description ?? '';
      setState(() {
        _bedrooms = room.bedrooms;
        _maxGuests = room.maxGuests;
        _selectedHomestayId = room.homestayId;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHomestayId == null) {
      AppSnackBar.error(context, 'Vui lòng chọn homestay');
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'homestayId': _selectedHomestayId,
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim(),
      'bedrooms': _bedrooms,
      'maxGuests': _maxGuests,
      if (_descCtrl.text.trim().isNotEmpty)
        'description': _descCtrl.text.trim(),
    };

    final repo = RoomRepository();
    final result = _isEdit
        ? await repo.updateRoom(widget.roomId!, data)
        : await repo.createRoom(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ref.invalidate(roomListProvider);
      if (_isEdit) ref.invalidate(roomDetailProvider(widget.roomId!));
      AppSnackBar.success(context,
          _isEdit ? 'Cập nhật phòng thành công' : 'Tạo phòng thành công');
      context.pop();
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homestaysAsync = ref.watch(homestayListProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa phòng' : 'Thêm phòng mới'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Homestay dropdown from provider
              homestaysAsync
                  .when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Homestay *',
                          prefixIcon: Icon(Icons.home_work_outlined)),
                      enabled: false,
                    ),
                    data: (homestays) => DropdownButtonFormField<String>(
                      initialValue: _selectedHomestayId,
                      decoration: InputDecoration(
                        labelText: 'Homestay *',
                        prefixIcon: Icon(Icons.home_work_outlined,
                            color: colors.primary),
                      ),
                      items: homestays
                          .map((h) => DropdownMenuItem(
                              value: h.id,
                              child: Text(h.name, style: GoogleFonts.beVietnamPro())))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedHomestayId = v),
                      validator: (v) => v == null ? 'Chọn homestay' : null,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Tên phòng *',
                  prefixIcon: Icon(Icons.bed_outlined, color: colors.primary),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Nhập tên phòng' : null,
              ).animate(delay: 50.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _codeCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Mã phòng *',
                  hintText: 'VD: P01, VILLA-01',
                  prefixIcon: Icon(Icons.tag_rounded, color: colors.primary),
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Nhập mã phòng' : null,
              ).animate(delay: 100.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.lg),

              // Counters
              Text(
                'Thông số phòng',
                style: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  Expanded(
                    child: _CounterField(
                      label: 'Phòng ngủ',
                      icon: Icons.bed_outlined,
                      value: _bedrooms,
                      min: 1,
                      max: 10,
                      onChanged: (v) => setState(() => _bedrooms = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _CounterField(
                      label: 'Khách tối đa',
                      icon: Icons.people_outline_rounded,
                      value: _maxGuests,
                      min: 1,
                      max: 20,
                      onChanged: (v) => setState(() => _maxGuests = v),
                    ),
                  ),
                ],
              ).animate(delay: 150.ms).fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  prefixIcon:
                      Icon(Icons.description_outlined, color: colors.primary),
                  alignLabelWithHint: true,
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 300.ms),

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
                          _isEdit ? 'Lưu thay đổi' : 'Tạo phòng',
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
    );
  }
}

// ─── Counter Field ────────────────────────────────────────────────────────────
class _CounterField extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CounterField({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: colors.surface,
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14, color: colors.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: colors.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CounterBtn(
                icon: Icons.remove_rounded,
                onPressed: value > min ? () => onChanged(value - 1) : null,
                color: colors.primary,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$value',
                  key: ValueKey(value),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
              ),
              _CounterBtn(
                icon: Icons.add_rounded,
                onPressed: value < max ? () => onChanged(value + 1) : null,
                color: colors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  const _CounterBtn({required this.icon, this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) => Material(
        color: onPressed != null
            ? color.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(icon,
                size: 20,
                color:
                    onPressed != null ? color : color.withValues(alpha: 0.3)),
          ),
        ),
      );
}
