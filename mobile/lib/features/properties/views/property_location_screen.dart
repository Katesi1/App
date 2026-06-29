import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/location_helper.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../rooms/controllers/room_controller.dart';

class PropertyLocationScreen extends ConsumerStatefulWidget {
  final String homestayId;

  const PropertyLocationScreen({super.key, required this.homestayId});

  @override
  ConsumerState<PropertyLocationScreen> createState() =>
      _PropertyLocationScreenState();
}

class _PropertyLocationScreenState
    extends ConsumerState<PropertyLocationScreen> {
  final _addressCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();
  bool _isLoading = false;
  bool _gettingLocation = false;
  bool _initialized = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _mapLinkCtrl.dispose();
    super.dispose();
  }

  void _initFromRoom() {
    if (_initialized) return;
    final room = ref.read(roomDetailProvider(widget.homestayId)).valueOrNull;
    if (room == null) return;
    _initialized = true;
    _addressCtrl.text = room.address ?? '';
    _mapLinkCtrl.text = room.mapLink ?? '';
  }

  /// Xin quyền + lấy vị trí GPS hiện tại → tự tạo link Google Maps.
  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);
    final result = await LocationHelper.getCurrentLocation();
    if (!mounted) return;
    setState(() => _gettingLocation = false);

    switch (result) {
      case LocationSuccess(:final mapsLink):
        setState(() => _mapLinkCtrl.text = mapsLink);
        AppSnackBar.success(context, 'Đã lấy vị trí hiện tại');
      case LocationFailure(:final message):
        AppSnackBar.error(context, message);
    }
  }

  /// Mở thử link Google Maps đang nhập để kiểm tra đúng vị trí.
  Future<void> _openMapLink() async {
    final link = _mapLinkCtrl.text.trim();
    final uri = Uri.tryParse(link);
    if (link.isEmpty || uri == null) {
      AppSnackBar.error(context, 'Chưa có link Google Maps');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppSnackBar.error(context, 'Không mở được Google Maps');
    }
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    final ok =
        await ref.read(roomActionsProvider.notifier).update(widget.homestayId, {
      'address': _addressCtrl.text.trim(),
      if (_mapLinkCtrl.text.trim().isNotEmpty)
        'mapLink': _mapLinkCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      AppSnackBar.success(context, 'Đã lưu vị trí');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(context, 'Có lỗi xảy ra');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final roomAsync = ref.watch(roomDetailProvider(widget.homestayId));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Vị trí')),
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
                _label(context, 'Khu vực / Địa chỉ'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressCtrl,
                  style: GoogleFonts.beVietnamPro(fontSize: 14),
                  decoration: _inputDeco(context, 'VD: Bãi Cháy, Hạ Long'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _label(context, 'Link Google Maps'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _mapLinkCtrl,
                  style: GoogleFonts.beVietnamPro(fontSize: 14),
                  decoration:
                      _inputDeco(context, 'Dán link Google Maps tại đây'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            _gettingLocation ? null : _useCurrentLocation,
                        icon: _gettingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: Text(
                          _gettingLocation
                              ? 'Đang lấy...'
                              : 'Lấy vị trí hiện tại',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.brand,
                          side: BorderSide(color: colors.brand),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _openMapLink,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        'Mở thử',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        side: BorderSide(color: colors.borderDefault),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgSurfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: colors.brand),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Nhấn "Lấy vị trí hiện tại" để app tự định vị và tạo '
                          'link. Hoặc mở Google Maps, tìm vị trí phòng, nhấn '
                          '"Chia sẻ" rồi dán link vào đây.',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: colors.textBrand,
                          ),
                        ),
                      ),
                    ],
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
                              strokeWidth: 2, color: Colors.white))
                      : Text('Lưu',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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

  Widget _label(BuildContext context, String t) => Text(t,
      style: GoogleFonts.beVietnamPro(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: context.colors.textPrimary));

  InputDecoration _inputDeco(BuildContext context, String hint) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.beVietnamPro(fontSize: 14, color: colors.textTertiary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
