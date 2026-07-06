import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
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
  bool _initialized = false;
  bool _locating = false;

  // Toạ độ GPS khi dùng "Lấy vị trí hiện tại" (null nếu chỉ dán link thủ công).
  double? _latitude;
  double? _longitude;

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

  /// Link Google Maps chuẩn từ toạ độ — mở được cả web + app khi click.
  String _mapLinkFromCoords(double lat, double lng) =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

  /// Lấy vị trí hiện tại (GPS) và tự điền link Google Maps. Người dùng cũng có
  /// thể bỏ qua nút này và dán link Google Maps thủ công vào ô bên dưới.
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
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _mapLinkCtrl.text = _mapLinkFromCoords(pos.latitude, pos.longitude);
        });
        AppSnackBar.success(context, 'Đã lấy vị trí hiện tại');
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Không lấy được vị trí hiện tại');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    // Nếu người dùng tự sửa/dán link khác sau khi lấy GPS thì toạ độ cũ không
    // còn khớp link → chỉ gửi lat/lng khi link vẫn là link sinh từ toạ độ đó.
    final link = _mapLinkCtrl.text.trim();
    final coordsMatchLink = _latitude != null &&
        _longitude != null &&
        link == _mapLinkFromCoords(_latitude!, _longitude!);

    final ok =
        await ref.read(roomActionsProvider.notifier).update(widget.homestayId, {
      'address': _addressCtrl.text.trim(),
      if (link.isNotEmpty) 'mapLink': link,
      if (coordsMatchLink) 'latitude': _latitude,
      if (coordsMatchLink) 'longitude': _longitude,
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
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(roomDetailProvider(widget.homestayId));
            await ref.read(roomDetailProvider(widget.homestayId).future);
          },
          child: roomAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => ErrorStateWidget(
              message: e.toString().replaceAll('Exception: ', ''),
              onRetry: () =>
                  ref.invalidate(roomDetailProvider(widget.homestayId)),
            ),
            data: (_) {
              _initFromRoom();
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                  _label(context, 'Vị trí trên bản đồ'),
                  const SizedBox(height: 6),
                  // Cách 1: lấy vị trí hiện tại (GPS) → tự sinh link Google Maps.
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _locating ? null : _useCurrentLocation,
                      icon: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 20),
                      label: Text(
                        _locating
                            ? 'Đang lấy vị trí...'
                            : 'Lấy vị trí hiện tại',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.brand,
                        side: BorderSide(color: colors.brand),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Dải phân cách "hoặc" giữa 2 cách.
                  Row(
                    children: [
                      Expanded(child: Divider(color: colors.borderDefault)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        child: Text(
                          'hoặc dán link',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: colors.textTertiary,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colors.borderDefault)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Cách 2: dán link Google Maps thủ công (lấy từ bản web/app).
                  TextFormField(
                    controller: _mapLinkCtrl,
                    style: GoogleFonts.beVietnamPro(fontSize: 14),
                    keyboardType: TextInputType.url,
                    // Đổi link thủ công → xoá toạ độ GPS cũ cho khỏi lệch link.
                    onChanged: (_) {
                      if (_latitude != null || _longitude != null) {
                        setState(() {
                          _latitude = null;
                          _longitude = null;
                        });
                      }
                    },
                    decoration:
                        _inputDeco(context, 'Dán link Google Maps tại đây'),
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
                            'Nhấn "Lấy vị trí hiện tại" khi bạn đang ở cơ sở, '
                            'hoặc mở Google Maps tìm vị trí → "Chia sẻ" → dán link '
                            'vào đây. Link này hiển thị bên web, khách bấm vào sẽ '
                            'mở đúng vị trí cơ sở.',
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
