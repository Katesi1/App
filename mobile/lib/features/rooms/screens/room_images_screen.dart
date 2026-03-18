import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/room_repository.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../providers/room_provider.dart';

class RoomImagesScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomImagesScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomImagesScreen> createState() => _RoomImagesScreenState();
}

class _RoomImagesScreenState extends ConsumerState<RoomImagesScreen> {
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickAndUpload() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    if (files.isEmpty) return;

    setState(() => _isUploading = true);
    final result = await RoomRepository()
        .uploadImages(widget.roomId, files.map((f) => f.path).toList());
    if (!mounted) return;
    setState(() => _isUploading = false);

    if (result.success) {
      ref.invalidate(roomDetailProvider(widget.roomId));
      AppSnackBar.success(
          context, 'Upload ${result.data?.length ?? 0} ảnh thành công');
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  Future<void> _deleteImage(String imageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xoá ảnh',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        content:
            Text('Bạn có chắc muốn xoá ảnh này?', style: GoogleFonts.nunito()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await RoomRepository().deleteImage(widget.roomId, imageId);
    if (!mounted) return;
    if (result.success) {
      ref.invalidate(roomDetailProvider(widget.roomId));
      AppSnackBar.success(context, 'Đã xoá ảnh');
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  Future<void> _setCover(String imageId) async {
    final result = await RoomRepository().setCoverImage(widget.roomId, imageId);
    if (!mounted) return;
    if (result.success) {
      ref.invalidate(roomDetailProvider(widget.roomId));
      AppSnackBar.success(context, 'Đã đặt ảnh bìa');
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý ảnh',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded),
              onPressed: _pickAndUpload,
              tooltip: 'Thêm ảnh',
            ),
        ],
      ),
      body: roomAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (room) {
          if (room.images.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.photo_library_outlined,
              message: 'Chưa có ảnh nào',
              subMessage: 'Nhấn nút bên dưới để thêm ảnh',
              onAction: _pickAndUpload,
              actionLabel: 'Thêm ảnh',
            );
          }

          return Column(
            children: [
              // Upload progress bar
              if (_isUploading)
                const LinearProgressIndicator(
                  color: AppColors.primary,
                ),

              // Hint
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 14,
                        color: colors.onSurface.withValues(alpha: 0.45)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${room.images.length} ảnh  •  Nhấn ★ đặt làm bìa  •  Nhấn giữ để xoá',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: room.images.length,
                  itemBuilder: (_, i) {
                    final img = room.images[i];
                    return GestureDetector(
                      onLongPress: () => _deleteImage(img.id),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: CachedNetworkImage(
                              imageUrl: img.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                  color: colors.surfaceContainerHighest),
                              errorWidget: (_, __, ___) => Container(
                                color: colors.surfaceContainerHighest,
                                child: Icon(Icons.broken_image_outlined,
                                    color: colors.onSurface
                                        .withValues(alpha: 0.3)),
                              ),
                            ),
                          ),

                          // Cover badge
                          if (img.isCover)
                            Positioned(
                              top: AppSpacing.xs,
                              left: AppSpacing.xs,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  'Bìa',
                                  style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),

                          // Star / cover button
                          Positioned(
                            top: AppSpacing.xs,
                            right: AppSpacing.xs,
                            child: GestureDetector(
                              onTap: () => _setCover(img.id),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  img.isCover
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 16,
                                  color: img.isCover
                                      ? Colors.amber
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),

                          // Delete button
                          Positioned(
                            bottom: AppSpacing.xs,
                            right: AppSpacing.xs,
                            child: GestureDetector(
                              onTap: () => _deleteImage(img.id),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete_outline_rounded,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate(delay: Duration(milliseconds: i * 40))
                        .fadeIn(duration: 250.ms)
                        .scale(
                            begin: const Offset(0.9, 0.9),
                            duration: 250.ms,
                            curve: Curves.easeOut);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: roomAsync.valueOrNull != null
          ? FloatingActionButton.extended(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: Text('Thêm ảnh',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              backgroundColor: _isUploading ? Colors.grey : AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
