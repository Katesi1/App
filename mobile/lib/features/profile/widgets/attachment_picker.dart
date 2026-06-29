import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../controllers/account_controller.dart';
import '../data/models/account_models.dart';

/// Bộ chọn + upload ảnh đính kèm cho support ticket / feedback (BE §23).
///
/// Chọn ảnh → `POST /uploads` → giữ URL; gỡ ảnh → `DELETE /uploads/:id`.
/// Parent nhận danh sách URL đã upload xong qua [onChanged] và trạng thái
/// đang-upload qua [onBusyChanged] (để khoá nút gửi tránh mất attachment).
class AttachmentPicker extends ConsumerStatefulWidget {
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<bool>? onBusyChanged;
  final int maxFiles;

  const AttachmentPicker({
    super.key,
    required this.onChanged,
    this.onBusyChanged,
    this.maxFiles = 5,
  });

  @override
  ConsumerState<AttachmentPicker> createState() => _AttachmentPickerState();
}

/// Một mục đính kèm: đang upload → có [file] khi xong, có [error] khi lỗi.
class _Item {
  final String path;
  UploadedFile? file;
  Object? error;
  _Item(this.path);

  bool get uploading => file == null && error == null;
}

class _AttachmentPickerState extends ConsumerState<AttachmentPicker> {
  final List<_Item> _items = [];

  bool get _busy => _items.any((i) => i.uploading);
  int get _slotsLeft => widget.maxFiles - _items.length;

  void _notify() {
    widget.onChanged(
      _items.where((i) => i.file != null).map((i) => i.file!.url).toList(),
    );
    widget.onBusyChanged?.call(_busy);
  }

  Future<void> _pick() async {
    if (_slotsLeft <= 0) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (picked.isEmpty || !mounted) return;
    final toAdd = picked.take(_slotsLeft).map((x) => _Item(x.path)).toList();
    setState(() => _items.addAll(toAdd));
    _notify();
    for (final item in toAdd) {
      _upload(item);
    }
  }

  Future<void> _upload(_Item item) async {
    final result =
        await ref.read(accountRepositoryProvider).uploadFile(item.path);
    if (!mounted) return;
    setState(() {
      if (result.success) {
        item.file = result.data;
        item.error = null;
      } else {
        item.error = result.message;
      }
    });
    _notify();
  }

  void _retry(_Item item) {
    setState(() => item.error = null);
    _notify();
    _upload(item);
  }

  void _remove(_Item item) {
    final id = item.file?.id;
    setState(() => _items.remove(item));
    _notify();
    if (id != null && id.isNotEmpty) {
      ref.read(accountRepositoryProvider).deleteUpload(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file_rounded,
                size: 16, color: colors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Đính kèm ảnh',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${_items.length}/${widget.maxFiles}',
              style: TextStyle(fontSize: 12, color: colors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._items.map((i) => _Thumb(
                  item: i,
                  onRemove: () => _remove(i),
                  onRetry: () => _retry(i),
                )),
            if (_slotsLeft > 0)
              GestureDetector(
                onTap: _pick,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.brand, width: 1.5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.add_photo_alternate_outlined,
                      color: colors.brand, size: 26),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final _Item item;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  const _Thumb({
    required this.item,
    required this.onRemove,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.file(
              File(item.path),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          if (item.uploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            )
          else if (item.error != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: onRetry,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Center(
                    child: Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration:
                    BoxDecoration(color: colors.error, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
