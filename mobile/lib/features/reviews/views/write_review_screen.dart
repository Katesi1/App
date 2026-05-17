import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/review_controller.dart';

/// Khách viết review sau khi booking đã `completed`. Entry point từ
/// `/my-bookings` → tap nút "Viết đánh giá" trên booking completed.
///
/// Flow:
/// 1. Chọn 1-5 sao cho 6 tiêu chí (default = 5)
/// 2. Comment optional + photos optional (text-only cho v1)
/// 3. Submit → backend reject nếu booking chưa completed / đã review
class WriteReviewScreen extends ConsumerStatefulWidget {
  final String propertyId;
  final String bookingId;
  final String? propertyName;

  const WriteReviewScreen({
    super.key,
    required this.propertyId,
    required this.bookingId,
    this.propertyName,
  });

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  // Default 5 sao cho mọi tiêu chí — match thói quen "khách hài lòng" mặc định.
  int _cleanliness = 5;
  int _location = 5;
  int _amenities = 5;
  int _service = 5;
  int _value = 5;
  int _accuracy = 5;

  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  double get _avgRating =>
      (_cleanliness + _location + _amenities + _service + _value + _accuracy) /
      6;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final payload = CreateReviewPayload(
      bookingId: widget.bookingId,
      cleanliness: _cleanliness,
      location: _location,
      amenities: _amenities,
      service: _service,
      value: _value,
      accuracy: _accuracy,
      comment: _commentCtrl.text,
    );
    final result = await ref.read(reviewActionsProvider.notifier).create(
          propertyId: widget.propertyId,
          payload: payload,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.success) {
      AppSnackBar.success(context, 'Cảm ơn bạn đã đánh giá!');
      context.pop(true);
    } else {
      AppSnackBar.error(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Viết đánh giá',
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (widget.propertyName != null && widget.propertyName!.isNotEmpty)
            _PropertyHeader(name: widget.propertyName!, avg: _avgRating),
          const SizedBox(height: AppSpacing.md),

          _SectionLabel(text: 'CHẤM ĐIỂM 6 TIÊU CHÍ'),
          const SizedBox(height: 8),
          _CriteriaPicker(
            label: 'Sạch sẽ',
            value: _cleanliness,
            onChanged: (v) => setState(() => _cleanliness = v),
          ),
          _CriteriaPicker(
            label: 'Vị trí',
            value: _location,
            onChanged: (v) => setState(() => _location = v),
          ),
          _CriteriaPicker(
            label: 'Tiện nghi',
            value: _amenities,
            onChanged: (v) => setState(() => _amenities = v),
          ),
          _CriteriaPicker(
            label: 'Dịch vụ',
            value: _service,
            onChanged: (v) => setState(() => _service = v),
          ),
          _CriteriaPicker(
            label: 'Giá trị',
            value: _value,
            onChanged: (v) => setState(() => _value = v),
          ),
          _CriteriaPicker(
            label: 'Đúng mô tả',
            value: _accuracy,
            onChanged: (v) => setState(() => _accuracy = v),
          ),

          const SizedBox(height: AppSpacing.md),
          _SectionLabel(text: 'NHẬN XÉT (TUỲ CHỌN)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              border: Border.all(color: colors.borderDefault),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _commentCtrl,
              maxLines: 5,
              minLines: 4,
              maxLength: 500,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: colors.textPrimary,
                height: 1.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Chia sẻ trải nghiệm của bạn để giúp khách khác…',
                hintStyle: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                disabledBackgroundColor:
                    colors.brand.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Gửi đánh giá',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header (property name + avg preview) ─────────────────────────────────────

class _PropertyHeader extends StatelessWidget {
  final String name;
  final double avg;

  const _PropertyHeader({required this.name, required this.avg});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.star_rounded,
                color: AppColors.gold500, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Điểm dự kiến: ${avg.toStringAsFixed(1)} / 5.0',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Criteria picker (1 row 5 stars) ──────────────────────────────────────────

class _CriteriaPicker extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _CriteriaPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.borderDefault),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final star = i + 1;
              final filled = star <= value;
              return GestureDetector(
                onTap: () => onChanged(star),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    filled
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 26,
                    color: filled ? AppColors.gold500 : colors.textTertiary,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: colors.textTertiary,
      ),
    );
  }
}
