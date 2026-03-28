import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class PropertyRulesScreen extends StatefulWidget {
  final String homestayId;

  const PropertyRulesScreen({super.key, required this.homestayId});

  @override
  State<PropertyRulesScreen> createState() => _PropertyRulesScreenState();
}

class _PropertyRulesScreenState extends State<PropertyRulesScreen> {
  // Sức chứa
  final _standardCapacityCtrl = TextEditingController(text: '10 người lớn');
  final _childrenCapacityCtrl = TextEditingController(text: '4 trẻ');
  final _maxCapacityCtrl = TextEditingController(text: '20 người');

  // Phụ thu
  final _adultSurchargeCtrl = TextEditingController(text: '250.000');
  final _childSurchargeCtrl = TextEditingController(text: '150.000');

  // Giờ nhận/trả
  final _checkInCtrl = TextEditingController(text: '14:00');
  final _checkOutCtrl = TextEditingController(text: '12:00');

  // Lưu ý
  final _notesCtrl = TextEditingController(
    text:
        'Các căn ưu tiên bán cặp 2 đêm Lễ & Cuối tuần.\n'
        'Nếu có khách lễ đêm T7, BK sát ngày chủ động nhắn tin hỏi Sale',
  );

  @override
  void dispose() {
    _standardCapacityCtrl.dispose();
    _childrenCapacityCtrl.dispose();
    _maxCapacityCtrl.dispose();
    _adultSurchargeCtrl.dispose();
    _childSurchargeCtrl.dispose();
    _checkInCtrl.dispose();
    _checkOutCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quy định'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _buildSectionLabel('SỨC CHỨA'),
                const SizedBox(height: AppSpacing.sm),
                _buildContainer([
                  _buildRow('Tiêu chuẩn', _standardCapacityCtrl),
                  _buildDivider(),
                  _buildRow('Trẻ em dưới 6 tuổi', _childrenCapacityCtrl),
                  _buildDivider(),
                  _buildRow(
                    'Tối đa (đã phụ thu)',
                    _maxCapacityCtrl,
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionLabel('PHỤ THU'),
                const SizedBox(height: AppSpacing.sm),
                _buildContainer([
                  _buildRow(
                    'Người lớn',
                    _adultSurchargeCtrl,
                    suffix: 'đ/người',
                  ),
                  _buildDivider(),
                  _buildRow(
                    'Trẻ em 7-11 tuổi',
                    _childSurchargeCtrl,
                    suffix: 'đ/người',
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionLabel('GIỜ NHẬN/TRẢ'),
                const SizedBox(height: AppSpacing.sm),
                _buildContainer([
                  _buildRow('Check-in', _checkInCtrl),
                  _buildDivider(),
                  _buildRow('Check-out', _checkOutCtrl),
                ]),
                const SizedBox(height: AppSpacing.lg),
                _buildSectionLabel('LƯU Ý'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextFormField(
                    controller: _notesCtrl,
                    maxLines: 5,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: AppColors.navy,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
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

  Widget _buildContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(
    String label,
    TextEditingController controller, {
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 140,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.right,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixText: suffix,
                suffixStyle: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: AppColors.border);
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.oceanMid, AppColors.ocean],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: ElevatedButton(
            onPressed: () {
              // TODO: Save logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
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
      ),
    );
  }
}
