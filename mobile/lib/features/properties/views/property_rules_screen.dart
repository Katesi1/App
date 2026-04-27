import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../rooms/controllers/room_controller.dart';

class PropertyRulesScreen extends ConsumerStatefulWidget {
  final String homestayId;

  const PropertyRulesScreen({super.key, required this.homestayId});

  @override
  ConsumerState<PropertyRulesScreen> createState() =>
      _PropertyRulesScreenState();
}

class _PropertyRulesScreenState extends ConsumerState<PropertyRulesScreen> {
  final _rulesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;

  static const _defaultRules =
      'Check-in sau 14:00, check-out trước 12:00.\n'
      'Không hút thuốc trong phòng.\n'
      'Giữ gìn vệ sinh chung.\n'
      'Không gây tiếng ồn sau 22:00.';

  static const _defaultNotes =
      'Ưu tiên bán cặp cuối tuần (T6-T7, T7-CN).\n'
      'Ngày lễ áp dụng giá lễ, tối thiểu 2 đêm.';

  static const _notesSeparator = '\n\n--- LƯU Ý ---\n';

  @override
  void dispose() {
    _rulesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _initFromRoom() {
    if (_initialized) return;
    final room = ref.read(roomDetailProvider(widget.homestayId)).valueOrNull;
    if (room == null) return;
    _initialized = true;

    final raw = room.rules ?? '';
    if (raw.contains(_notesSeparator)) {
      final parts = raw.split(_notesSeparator);
      _rulesCtrl.text = parts[0];
      _notesCtrl.text = parts.length > 1 ? parts[1] : _defaultNotes;
    } else {
      _rulesCtrl.text = raw.isNotEmpty ? raw : _defaultRules;
      _notesCtrl.text = _defaultNotes;
    }
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    final rules = _rulesCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final combined = notes.isNotEmpty
        ? '$rules$_notesSeparator$notes'
        : rules;

    final ok = await ref
        .read(roomActionsProvider.notifier)
        .update(widget.homestayId, {
      'rules': combined,
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      AppSnackBar.success(context, 'Đã lưu quy định');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(context, 'Có lỗi xảy ra');
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailProvider(widget.homestayId));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Quy định')),
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
                Text('Nội quy phòng',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _rulesCtrl,
                  maxLines: 12,
                  style: GoogleFonts.beVietnamPro(fontSize: 14, height: 1.6),
                  decoration: InputDecoration(
                    hintText: 'Nhập quy định...',
                    hintStyle: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: AppColors.muted.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.brownDark),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nội dung quy định sẽ hiển thị cho khách hàng khi xem chi tiết phòng.',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AppColors.brownDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Lưu ý bán phòng',
                    style: GoogleFonts.beVietnamPro(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 6,
                  style: GoogleFonts.beVietnamPro(fontSize: 14, height: 1.6),
                  decoration: InputDecoration(
                    hintText: 'VD: Ưu tiên bán cặp cuối tuần...',
                    hintStyle: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        color: AppColors.muted.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
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
      ),
    );
  }
}
