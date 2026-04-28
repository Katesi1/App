import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../rooms/controllers/room_controller.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7
const _jadeMidLight = Color(0xFF1B7E94);

class PropertyServicesScreen extends ConsumerStatefulWidget {
  final String homestayId;

  const PropertyServicesScreen({super.key, required this.homestayId});

  @override
  ConsumerState<PropertyServicesScreen> createState() =>
      _PropertyServicesScreenState();
}

class _PropertyServicesScreenState
    extends ConsumerState<PropertyServicesScreen> {
  final List<String> _services = [];
  bool _isLoading = false;
  bool _initialized = false;

  void _initFromRoom() {
    if (_initialized) return;
    final room = ref.read(roomDetailProvider(widget.homestayId)).valueOrNull;
    if (room == null) return;
    _initialized = true;
    _services.addAll(room.services);
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    final ok = await ref
        .read(roomActionsProvider.notifier)
        .update(widget.homestayId, {
      'services': _services,
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      AppSnackBar.success(context, 'Đã lưu dịch vụ');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(context, 'Có lỗi xảy ra');
    }
  }

  void _addService() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          title: Text('Thêm dịch vụ',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: GoogleFonts.beVietnamPro(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'VD: Thuê xe máy',
              hintStyle: GoogleFonts.beVietnamPro(
                  fontSize: 14, color: colors.textSecondary),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Huỷ')),
            TextButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  setState(() => _services.add(ctrl.text.trim()));
                }
                Navigator.pop(ctx);
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark
        ? const [AppColors.darkBg, AppColors.darkBorder]
        : const [AppColors.jade500, _jadeMidLight];
    final roomAsync = ref.watch(roomDetailProvider(widget.homestayId));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: const Text('Dịch vụ trả phí'),
        actions: [
          IconButton(
            onPressed: _addService,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: roomAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () =>
              ref.invalidate(roomDetailProvider(widget.homestayId)),
        ),
        data: (_) {
          _initFromRoom();
          if (_services.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.room_service_outlined,
                      size: 48, color: colors.textTertiary),
                  const SizedBox(height: 12),
                  Text('Chưa có dịch vụ nào',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15, color: colors.textSecondary,
                      )),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addService,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm dịch vụ'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _services.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: colors.borderDefault),
            itemBuilder: (_, i) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: colors.brand.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.room_service_outlined,
                    color: colors.brand, size: 20),
              ),
              title: Text(_services[i],
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  )),
              trailing: IconButton(
                onPressed: () => setState(() => _services.removeAt(i)),
                icon: Icon(Icons.delete_outline_rounded,
                    color: colors.error, size: 20),
              ),
            ),
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
