import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';

class PropertyImagesScreen extends StatefulWidget {
  final String homestayId;

  const PropertyImagesScreen({super.key, required this.homestayId});

  @override
  State<PropertyImagesScreen> createState() => _PropertyImagesScreenState();
}

class _PropertyImagesScreenState extends State<PropertyImagesScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // đóng bottom sheet
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      setState(() => _images.addAll(picked));
    } catch (_) {
      if (mounted) AppSnackBar.error(context, 'Không thể chọn ảnh');
    }
  }

  Future<void> _takePhoto() async {
    Navigator.pop(context); // đóng bottom sheet
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;
      setState(() => _images.add(picked));
    } catch (_) {
      if (mounted) AppSnackBar.error(context, 'Không thể chụp ảnh');
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Thêm ảnh',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.oceanLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.ocean,
                  ),
                ),
                title: Text(
                  'Chụp ảnh',
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                subtitle: Text(
                  'Dùng camera để chụp ảnh mới',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                onTap: _takePhoto,
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.teal,
                  ),
                ),
                title: Text(
                  'Chọn từ thư viện',
                  style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                subtitle: Text(
                  'Có thể chọn nhiều ảnh cùng lúc',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ảnh căn'),
        actions: [
          if (_images.isNotEmpty)
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
                '${_images.length} ảnh',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ocean,
                ),
              ),
            ),
        ],
      ),
      body: _images.isEmpty ? _buildEmptyState() : _buildImageGrid(),
      floatingActionButton: _images.isEmpty ? null : _buildFab(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.oceanLight,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: AppColors.ocean,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Chưa có ảnh nào',
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Thêm ảnh để khách hàng có thể\nhình dung rõ hơn về căn phòng của bạn.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
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
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  onTap: _showPickerSheet,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Thêm ảnh',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            'Nhấn giữ để sắp xếp · Nhấn X để xoá',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.muted,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.0,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) => _buildImageCard(index),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Image.file(
            File(_images[index].path),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: GestureDetector(
            onTap: () => _removeImage(index),
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
        if (index == 0)
          Positioned(
            bottom: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.ocean.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                'Ảnh bìa',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
        onPressed: _showPickerSheet,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
        label: Text(
          'Thêm ảnh',
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
