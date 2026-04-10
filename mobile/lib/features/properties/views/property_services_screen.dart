import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../rooms/controllers/room_controller.dart';

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
      builder: (ctx) => AlertDialog(
        title: Text('Thêm dịch vụ',
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.beVietnamPro(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'VD: Thuê xe máy',
            hintStyle: GoogleFonts.beVietnamPro(
                fontSize: 14, color: AppColors.muted),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailProvider(widget.homestayId));

    return Scaffold(
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
                  const Icon(Icons.room_service_outlined,
                      size: 48, color: AppColors.slate),
                  const SizedBox(height: 12),
                  Text('Chưa có dịch vụ nào',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15, color: AppColors.muted,
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
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.room_service_outlined,
                    color: AppColors.teal, size: 20),
              ),
              title: Text(_services[i],
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14, fontWeight: FontWeight.w500,
                  )),
              trailing: IconButton(
                onPressed: () => setState(() => _services.removeAt(i)),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.coral, size: 20),
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
