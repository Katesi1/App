import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class HomestayImagesScreen extends StatefulWidget {
  final String homestayId;

  const HomestayImagesScreen({super.key, required this.homestayId});

  @override
  State<HomestayImagesScreen> createState() => _HomestayImagesScreenState();
}

class _HomestayImagesScreenState extends State<HomestayImagesScreen> {
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Phòng ngủ',
    'Phòng khách',
    'Bể bơi',
  ];

  final List<Map<String, String>> _images = [
    {'id': '1', 'category': 'Phòng ngủ'},
    {'id': '2', 'category': 'Phòng ngủ'},
    {'id': '3', 'category': 'Phòng khách'},
    {'id': '4', 'category': 'Phòng khách'},
    {'id': '5', 'category': 'Bể bơi'},
    {'id': '6', 'category': 'Bể bơi'},
    {'id': '7', 'category': 'Phòng ngủ'},
    {'id': '8', 'category': 'Phòng khách'},
    {'id': '9', 'category': 'Bể bơi'},
    {'id': '10', 'category': 'Phòng ngủ'},
    {'id': '11', 'category': 'Phòng khách'},
    {'id': '12', 'category': 'Bể bơi'},
    {'id': '13', 'category': 'Phòng ngủ'},
    {'id': '14', 'category': 'Phòng khách'},
    {'id': '15', 'category': 'Phòng ngủ'},
    {'id': '16', 'category': 'Bể bơi'},
    {'id': '17', 'category': 'Phòng khách'},
    {'id': '18', 'category': 'Phòng ngủ'},
  ];

  List<Map<String, String>> get _filteredImages {
    if (_selectedCategory == 'Tất cả') {
      return _images;
    }
    return _images
        .where((img) => img['category'] == _selectedCategory)
        .toList();
  }

  void _deleteImage(String id) {
    setState(() {
      _images.removeWhere((img) => img['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Anh can',
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.oceanLight,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '${_images.length} anh',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ocean,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterChips(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Giu de keo sap xep',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.muted,
              ),
            ),
          ),
          Expanded(child: _buildImageGrid()),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: _categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.ocean
                    : AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: isSelected
                      ? AppColors.ocean
                      : AppColors.border,
                ),
              ),
              child: Text(
                category,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : AppColors.ink,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageGrid() {
    final filtered = _filteredImages;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Chua co anh nao',
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: AppColors.muted,
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.0,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final image = filtered[index];
        return _buildImageCard(image);
      },
    );
  }

  Widget _buildImageCard(Map<String, String> image) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppRadius.md),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.oceanDeep,
                AppColors.oceanMid,
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              size: 40,
              color: Colors.white38,
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: GestureDetector(
            onTap: () => _deleteImage(image['id']!),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.coral,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: AppSpacing.sm,
          left: AppSpacing.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius:
                  BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              image['category']!,
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          colors: [AppColors.ocean, AppColors.oceanMid],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ocean.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          // TODO: implement image picker
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(
          Icons.camera_alt_outlined,
          color: Colors.white,
        ),
        label: Text(
          'Them anh',
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
