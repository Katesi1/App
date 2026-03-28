import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';

enum _CancellationPolicy { flexible, moderate, strict }

class HomestaCancellationScreen extends StatefulWidget {
  final String homestayId;

  const HomestaCancellationScreen({
    super.key,
    required this.homestayId,
  });

  @override
  State<HomestaCancellationScreen> createState() =>
      _HomestaCancellationScreenState();
}

class _HomestaCancellationScreenState
    extends State<HomestaCancellationScreen> {
  _CancellationPolicy _selected = _CancellationPolicy.flexible;
  final _freeDaysController = TextEditingController();
  final _refundPercentController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _freeDaysController.dispose();
    _refundPercentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính sách huỷ'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBanner(),
                  const SizedBox(height: AppSpacing.md),
                  RadioGroup<_CancellationPolicy>(
                    groupValue: _selected,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selected = val);
                      }
                    },
                    child: Column(
                      children: [
                        _buildPolicyCard(
                          policy: _CancellationPolicy.flexible,
                          title: 'Linh hoạt',
                          rules: const [
                            'Hoàn 100% nếu huỷ trước 1 ngày '
                                'nhận phòng',
                            'Huỷ sau thời hạn: Không hoàn tiền',
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildPolicyCard(
                          policy: _CancellationPolicy.moderate,
                          title: 'Vừa phải',
                          rules: const [
                            'Hoàn 100% nếu huỷ trước 7 ngày '
                                'nhận phòng',
                            'Huỷ trong 7 ngày: Hoàn 50%',
                            'Huỷ trong 3 ngày: Không hoàn tiền',
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildPolicyCard(
                          policy: _CancellationPolicy.strict,
                          title: 'Nghiêm ngặt',
                          rules: const [
                            'Hoàn 50% nếu huỷ trước 14 ngày',
                            'Huỷ trong 14 ngày: '
                                'Không hoàn tiền',
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'TUỲ CHỈNH',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTextField(
                    label: 'Số ngày huỷ miễn phí',
                    controller: _freeDaysController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTextField(
                    label: '% hoàn tiền',
                    controller: _refundPercentController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTextField(
                    label: 'Ghi chú thêm',
                    controller: _noteController,
                    maxLines: 3,
                    hint: 'Nhập ghi chú...',
                  ),
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.oceanMid,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Chọn chính sách áp dụng cho căn này. '
              'Khách sẽ thấy chính sách khi xem link.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: AppColors.ocean,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard({
    required _CancellationPolicy policy,
    required String title,
    required List<String> rules,
  }) {
    final isSelected = _selected == policy;
    return GestureDetector(
      onTap: () => setState(() => _selected = policy),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.ocean
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius:
              BorderRadius.circular(AppRadius.md),
          color: AppColors.surface,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...rules.map(
                    (rule) => Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.xs,
                      ),
                      child: Text(
                        rule,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Radio<_CancellationPolicy>(
              value: policy,
              activeColor: AppColors.ocean,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: AppColors.slate,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(
                color: AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppRadius.sm),
              borderSide: const BorderSide(
                color: AppColors.ocean,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.oceanMid,
                  AppColors.ocean,
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
                'Lưu chính sách',
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

  void _onSave() {
    // TODO: Integrate with API
    AppSnackBar.success(context, 'Đã lưu chính sách huỷ');
  }
}
