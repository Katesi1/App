import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../controllers/review_controller.dart';

/// Bottom sheet cho OWNER (hoặc ADMIN) trả lời 1 review. Backend ghi đè
/// reply cũ — không cần xử lý 409. Pre-fill với reply hiện tại nếu có.
Future<bool?> showOwnerReplyModal(
  BuildContext context, {
  required String propertyId,
  required ReviewModel review,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OwnerReplySheet(propertyId: propertyId, review: review),
  );
}

class _OwnerReplySheet extends ConsumerStatefulWidget {
  final String propertyId;
  final ReviewModel review;

  const _OwnerReplySheet({required this.propertyId, required this.review});

  @override
  ConsumerState<_OwnerReplySheet> createState() => _OwnerReplySheetState();
}

class _OwnerReplySheetState extends ConsumerState<_OwnerReplySheet> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.review.ownerReply ?? '');
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      AppSnackBar.error(context, 'Vui lòng nhập nội dung phản hồi');
      return;
    }
    setState(() => _submitting = true);
    final result = await ref.read(reviewActionsProvider.notifier).reply(
          propertyId: widget.propertyId,
          reviewId: widget.review.id,
          reply: text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.success) {
      AppSnackBar.success(context, 'Đã gửi phản hồi');
      Navigator.pop(context, true);
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEdit = widget.review.ownerReply != null;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Chỉnh sửa phản hồi' : 'Trả lời đánh giá',
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Phản hồi của ${widget.review.customerName} sẽ hiển thị công khai dưới review.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                border: Border.all(color: colors.borderDefault),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: 5,
                minLines: 3,
                maxLength: 500,
                autofocus: true,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: colors.textPrimary,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Cảm ơn bạn đã trải nghiệm…',
                  hintStyle: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.borderDefault),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Huỷ',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.brand,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEdit ? 'Cập nhật' : 'Gửi phản hồi',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
