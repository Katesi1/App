import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class HomestayAmenitiesScreen extends StatefulWidget {
  final String homestayId;

  const HomestayAmenitiesScreen({
    super.key,
    required this.homestayId,
  });

  @override
  State<HomestayAmenitiesScreen> createState() =>
      _HomestayAmenitiesScreenState();
}

class _HomestayAmenitiesScreenState
    extends State<HomestayAmenitiesScreen> {
  late List<Map<String, dynamic>> _amenities;

  @override
  void initState() {
    super.initState();
    _amenities = [
      {'name': 'Bể bơi riêng', 'enabled': true},
      {'name': 'Bếp nướng BBQ ngoài trời', 'enabled': true},
      {'name': 'Free wifi tốc độ cao', 'enabled': true},
      {'name': 'Karaoke loa kéo miễn phí', 'enabled': true},
      {'name': 'Đỗ xe ô tô miễn phí', 'enabled': true},
      {'name': 'Bếp từ tủ lạnh ấm siêu tốc', 'enabled': true},
      {'name': 'Bồn tắm phòng master', 'enabled': true},
      {'name': 'Máy sấy tóc đèn sưởi', 'enabled': true},
      {'name': 'Quản gia hỗ trợ 24/7', 'enabled': true},
      {'name': 'Bàn Bi-a', 'enabled': false},
      {'name': 'Bàn Piano', 'enabled': false},
      {'name': 'View biển', 'enabled': false},
      {'name': 'Sân vườn BBQ rộng', 'enabled': false},
    ];
  }

  int get _enabledCount =>
      _amenities.where((a) => a['enabled'] == true).length;

  void _toggleAmenity(int index) {
    setState(() {
      _amenities[index] = {
        ..._amenities[index],
        'enabled': !(_amenities[index]['enabled'] as bool),
      };
    });
  }

  void _onAddAmenity() {
    // TODO: implement add amenity dialog
  }

  void _onSave() {
    // TODO: implement save logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                color: AppColors.oceanLight,
                borderRadius:
                    BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$_enabledCount',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ocean,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              children: [
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.sm,
                  ),
                  child: Text(
                    'TIỆN ÍCH MIỄN PHÍ',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _amenities.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.border,
                  ),
                  itemBuilder: (context, index) {
                    final amenity = _amenities[index];
                    final enabled = amenity['enabled'] as bool;
                    return _AmenityRow(
                      name: amenity['name'] as String,
                      enabled: enabled,
                      onToggle: () => _toggleAmenity(index),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: _onAddAmenity,
                  borderRadius:
                      BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.ocean,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Thêm tiện ích khác',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ocean,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
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
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.ocean,
                        AppColors.oceanMid,
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppRadius.md,
                        ),
                      ),
                    ),
                    child: Text(
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            enabled
                ? Icons.check_circle
                : Icons.cancel,
            color: enabled
                ? AppColors.emerald
                : AppColors.slate,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: enabled
                    ? AppColors.ink
                    : AppColors.muted,
              ),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (_) => onToggle(),
            activeTrackColor: AppColors.ocean,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
