import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/room_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../rooms/controllers/room_controller.dart';

class PropertyImagesScreen extends ConsumerStatefulWidget {
  final String homestayId;

  const PropertyImagesScreen({super.key, required this.homestayId});

  @override
  ConsumerState<PropertyImagesScreen> createState() =>
      _PropertyImagesScreenState();
}

class _PropertyImagesScreenState extends ConsumerState<PropertyImagesScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;

    setState(() => _uploading = true);
    final paths = picked.map((f) => f.path).toList();
    final (ok, err) = await ref
        .read(roomActionsProvider.notifier)
        .uploadImages(widget.homestayId, paths);

    if (!mounted) return;
    setState(() => _uploading = false);
    if (ok) {
      AppSnackBar.success(context, 'Đã tải lên ${picked.length} ảnh');
    } else {
      AppSnackBar.error(context, 'Không thể tải ảnh: $err');
    }
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() => _uploading = true);
    final (ok, err) = await ref
        .read(roomActionsProvider.notifier)
        .uploadImages(widget.homestayId, [picked.path]);

    if (!mounted) return;
    setState(() => _uploading = false);
    if (ok) {
      AppSnackBar.success(context, 'Đã tải lên ảnh');
    } else {
      AppSnackBar.error(context, 'Không thể tải ảnh: $err');
    }
  }

  Future<void> _deleteImage(RoomImageModel img) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          title: const Text('Xoá ảnh'),
          content: const Text('Bạn chắc chắn muốn xoá ảnh này?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Huỷ')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Xoá', style: TextStyle(color: colors.error))),
          ],
        );
      },
    );
    if (confirm != true) return;

    final ok = await ref
        .read(roomActionsProvider.notifier)
        .deleteImage(widget.homestayId, img.id);

    if (!mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Đã xoá ảnh');
    } else {
      AppSnackBar.error(context, 'Không thể xoá ảnh');
    }
  }

  Future<void> _setCover(RoomImageModel img) async {
    final ok = await ref
        .read(roomActionsProvider.notifier)
        .setCoverImage(widget.homestayId, img.id);

    if (!mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Đã đặt ảnh bìa');
    } else {
      AppSnackBar.error(context, 'Không thể đặt ảnh bìa');
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colors = ctx.colors;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Thêm ảnh',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    )),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          colors.brand.withValues(alpha: isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.camera_alt_outlined, color: colors.brand),
                  ),
                  title: Text('Chụp ảnh',
                      style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.brandSecondary
                          .withValues(alpha: isDark ? 0.22 : 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.photo_library_outlined,
                        color: colors.brandSecondary),
                  ),
                  title: Text('Chọn từ thư viện',
                      style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUpload();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final roomAsync = ref.watch(roomDetailProvider(widget.homestayId));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: const Text('Ảnh căn'),
        actions: [
          if (_uploading)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: colors.brand),
              ),
            ),
        ],
      ),
      body: roomAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(roomDetailProvider(widget.homestayId)),
        ),
        data: (room) {
          if (room.images.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildImageGrid(context, room.images);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _showPickerSheet,
        backgroundColor: colors.brand,
        icon:
            const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
        label: Text('Thêm ảnh',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colors.brand.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Icon(Icons.photo_library_outlined,
                size: 48, color: colors.brand),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Chưa có ảnh nào',
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              )),
          const SizedBox(height: AppSpacing.sm),
          Text('Thêm ảnh để khách hàng hình dung\nvề căn phòng của bạn.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.5,
              )),
        ],
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, List<RoomImageModel> images) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text('Nhấn "Đặt ảnh chính" để chọn ảnh hiển thị · X = xoá',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: colors.textSecondary,
              )),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: images.length,
            itemBuilder: (_, i) => _buildImageCard(context, images[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(BuildContext context, RoomImageModel img) {
    final colors = context.colors;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            color: colors.bgSurfaceContainer,
            child: CachedNetworkImage(
              imageUrl: img.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              memCacheWidth: 400,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
        // Delete button
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: GestureDetector(
            onTap: () => _deleteImage(img),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
        // Cover badge or set cover button
        Positioned(
          bottom: AppSpacing.sm,
          left: AppSpacing.sm,
          child: img.isCover
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.jade500.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.gold500),
                      const SizedBox(width: 4),
                      Text('Ảnh chính',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () => _setCover(img),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text('Đặt ảnh chính',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        )),
                  ),
                ),
        ),
      ],
    );
  }
}
