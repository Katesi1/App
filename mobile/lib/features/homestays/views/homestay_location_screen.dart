import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class _NearbyPlace {
  final IconData icon;
  final String description;

  const _NearbyPlace({required this.icon, required this.description});
}

class HomestayLocationScreen extends StatefulWidget {
  final String homestayId;

  const HomestayLocationScreen({super.key, required this.homestayId});

  @override
  State<HomestayLocationScreen> createState() => _HomestayLocationScreenState();
}

class _HomestayLocationScreenState extends State<HomestayLocationScreen> {
  final _codeController = TextEditingController(text: 'C3-06');
  final _zoneController = TextEditingController(
    text: 'Biệt thự Calvia Sun Grand City Feria Hạ Long',
  );
  final _descController = TextEditingController(
    text: 'Biệt thự ven biển Bãi Cháy',
  );

  final List<_NearbyPlace> _nearbyPlaces = [
    const _NearbyPlace(
      icon: Icons.location_on_outlined,
      description: 'Đối diện Vinpearl Hạ Long',
    ),
    const _NearbyPlace(
      icon: Icons.location_on_outlined,
      description: 'Cách bãi biển Bãi Cháy ~300m đi bộ',
    ),
    const _NearbyPlace(
      icon: Icons.sailing_outlined,
      description: 'Cảng tàu quốc tế Sun Group ~1km',
    ),
    const _NearbyPlace(
      icon: Icons.attractions_outlined,
      description: 'Công viên Sun World ~1km',
    ),
    const _NearbyPlace(
      icon: Icons.restaurant_outlined,
      description: 'Chợ hải sản Cái Dăm ~1km',
    ),
  ];

  @override
  void dispose() {
    _codeController.dispose();
    _zoneController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vị trí',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.oceanDeep,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _buildSectionLabel('ĐỊA CHỈ'),
                const SizedBox(height: AppSpacing.sm),
                _buildAddressSection(),
                const SizedBox(height: AppSpacing.lg),
                _buildMapPlaceholder(),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionLabel('XUNG QUANH'),
                const SizedBox(height: AppSpacing.sm),
                _buildNearbySection(),
              ],
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildAddressRow('Mã căn', _codeController),
          const Divider(height: 1, color: AppColors.border),
          _buildAddressRow('Khu', _zoneController),
          const Divider(height: 1, color: AppColors.border),
          _buildAddressRow('Mô tả', _descController),
        ],
      ),
    );
  }

  Widget _buildAddressRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: AppColors.ink,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 40,
              color: AppColors.ocean,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Xem bản đồ',
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ocean,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbySection() {
    return Column(
      children: [
        ...List.generate(_nearbyPlaces.length, (index) {
          final place = _nearbyPlaces[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(place.icon, size: 22, color: AppColors.muted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    place.description,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.ocean,
                  onPressed: () {},
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.coral,
                  onPressed: () {
                    setState(() {
                      _nearbyPlaces.removeAt(index);
                    });
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: AppColors.ocean),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Thêm địa điểm',
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
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.oceanMid, AppColors.ocean],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: MaterialButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            'Lưu',
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
