import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../rooms/controllers/room_controller.dart';

class PropertyAmenitiesScreen extends ConsumerStatefulWidget {
  final String homestayId;

  const PropertyAmenitiesScreen({
    super.key,
    required this.homestayId,
  });

  @override
  ConsumerState<PropertyAmenitiesScreen> createState() =>
      _PropertyAmenitiesScreenState();
}

class _PropertyAmenitiesScreenState
    extends ConsumerState<PropertyAmenitiesScreen> {
  final Set<String> _selectedAmenities = {};
  bool _isLoading = false;
  bool _initialized = false;

  static const _amenityGroups = {
    'Phòng khách': [
      'Điều hòa', 'Wifi', 'TV', 'Karaoke', 'Loa di động',
    ],
    'Bếp & Ăn uống': [
      'Bếp đầy đủ', 'Tủ lạnh', 'Lò vi sóng', 'Bếp từ',
      'BBQ ngoài trời', 'Bát đũa', 'Nước lọc free',
    ],
    'Phòng ngủ & Tắm': [
      'Bồn tắm', 'Vòi sen', 'Nước nóng', 'Máy sấy tóc',
      'Đèn sưởi', 'Khăn tắm', 'Dầu gội/Sữa tắm',
    ],
    'Ngoài trời': [
      'Bể bơi', 'Ban công', 'View biển',
      'Sân vườn', 'Sân thượng', 'Đỗ xe',
    ],
    'Tiện ích chung': [
      'Máy giặt', 'Bàn là', 'Tủ quần áo', 'Két sắt', 'Thang máy',
    ],
    'Giải trí': [
      'Bida', 'Bàn bóng bàn', 'Xích đu', 'Khu vui chơi trẻ em',
    ],
  };

  void _initFromRoom() {
    if (_initialized) return;
    final room = ref.read(roomDetailProvider(widget.homestayId)).valueOrNull;
    if (room == null) return;
    _initialized = true;
    _selectedAmenities.addAll(room.amenities);
  }

  Future<void> _onSave() async {
    setState(() => _isLoading = true);

    final ok = await ref
        .read(roomActionsProvider.notifier)
        .update(widget.homestayId, {
      'amenities': _selectedAmenities.toList(),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      AppSnackBar.success(context, 'Đã lưu tiện ích');
      Navigator.of(context).pop();
    } else {
      AppSnackBar.error(context, 'Có lỗi xảy ra, vui lòng thử lại');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final roomAsync = ref.watch(roomDetailProvider(widget.homestayId));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tiện ích'),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${_selectedAmenities.length}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textBrand,
                  ),
                ),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: roomAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorStateWidget(
            message: e.toString().replaceAll('Exception: ', ''),
            onRetry: () =>
                ref.invalidate(roomDetailProvider(widget.homestayId)),
          ),
          data: (room) {
            _initFromRoom();

            final allPreset =
                _amenityGroups.values.expand((v) => v).toSet();
            final extraAmenities = _selectedAmenities
                .where((a) => !allPreset.contains(a))
                .toList();

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      ..._amenityGroups.entries.map((group) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                  top: AppSpacing.md,
                                ),
                                child: Text(
                                  group.key.toUpperCase(),
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              ...group.value.map((amenity) {
                                final on =
                                    _selectedAmenities.contains(amenity);
                                return _AmenityRow(
                                  name: amenity,
                                  enabled: on,
                                  onToggle: () => setState(() {
                                    if (on) {
                                      _selectedAmenities.remove(amenity);
                                    } else {
                                      _selectedAmenities.add(amenity);
                                    }
                                  }),
                                );
                              }),
                            ],
                          )),

                      if (extraAmenities.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xs,
                            top: AppSpacing.md,
                          ),
                          child: Text(
                            'KHÁC',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        ...extraAmenities.map((amenity) => _AmenityRow(
                              name: amenity,
                              enabled: true,
                              onToggle: () => setState(() {
                                _selectedAmenities.remove(amenity);
                              }),
                            )),
                      ],

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.brand, colors.brandLight],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Lưu',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AmenityRow extends StatelessWidget {
  final String name;
  final bool enabled;
  final VoidCallback onToggle;

  const _AmenityRow({
    required this.name,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? colors.success : colors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: enabled ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (_) => onToggle(),
            activeTrackColor: colors.brand,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
