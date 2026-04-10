import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../rooms/controllers/room_controller.dart';

class PropertyCancellationScreen extends ConsumerStatefulWidget {
  final String homestayId;

  const PropertyCancellationScreen({super.key, required this.homestayId});

  @override
  ConsumerState<PropertyCancellationScreen> createState() =>
      _PropertyCancellationScreenState();
}

class _PropertyCancellationScreenState
    extends ConsumerState<PropertyCancellationScreen> {
  int _selected = 0;
  bool _isLoading = false;
  bool _initialized = false;

  static const _policies = [
    (
      value: 0,
      label: 'Linh hoạt',
      desc: 'Hoàn 100% nếu huỷ trước 1 ngày',
      icon: Icons.sentiment_satisfied_alt_rounded,
      color: AppColors.emerald,
    ),
    (
      value: 1,
      label: 'Vừa phải',
      desc: 'Hoàn 100% nếu huỷ trước 7 ngày',
      icon: Icons.sentiment_neutral_rounded,
      color: AppColors.amber,
    ),
    (
      value: 2,
      label: 'Nghiêm ngặt',
      desc: 'Không hoàn tiền sau khi đặt',
      icon: Icons.sentiment_dissatisfied_rounded,
      color: AppColors.coral,
    ),
  ];

  void _initFromRoom() {
    if (_initialized) return;
    final room = ref.read(roomDetailProvider(widget.homestayId)).valueOrNull;
    if (room == null) return;
    _initialized = true;
    _selected = room.cancellationPolicy ?? 0;
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    final ok = await ref
        .read(roomActionsProvider.notifier)
        .update(widget.homestayId, {
      'cancellationPolicy': _selected,
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      AppSnackBar.success(context, 'Đã lưu chính sách huỷ');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(context, 'Có lỗi xảy ra');
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailProvider(widget.homestayId));

    return Scaffold(
      appBar: AppBar(title: const Text('Chính sách huỷ')),
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
            children: _policies.map((p) {
              final on = _selected == p.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => setState(() => _selected = p.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: on
                          ? p.color.withValues(alpha: 0.08)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: on ? p.color : AppColors.border,
                        width: on ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          on
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: on ? p.color : AppColors.muted,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.label,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: on ? p.color : AppColors.ink,
                                  )),
                              const SizedBox(height: 2),
                              Text(p.desc,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  )),
                            ],
                          ),
                        ),
                        Icon(p.icon, color: p.color, size: 24),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            width: double.infinity, height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.oceanMid, AppColors.ocean],
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
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Lưu',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700, fontSize: 15,
                          color: Colors.white,
                        )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
