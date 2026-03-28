import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';

class HomestayInfoScreen extends StatefulWidget {
  final String homestayId;

  const HomestayInfoScreen({super.key, required this.homestayId});

  @override
  State<HomestayInfoScreen> createState() => _HomestayInfoScreenState();
}

class _HomestayInfoScreenState extends State<HomestayInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _bedroomCountCtrl;
  late final TextEditingController _bathroomCountCtrl;
  late final TextEditingController _bedDetailCtrl;
  late final TextEditingController _bathDetailCtrl;
  late final TextEditingController _kitchenCtrl;
  late final TextEditingController _livingRoomCtrl;

  @override
  void initState() {
    super.initState();
    _descriptionCtrl = TextEditingController();
    _bedroomCountCtrl = TextEditingController();
    _bathroomCountCtrl = TextEditingController();
    _bedDetailCtrl = TextEditingController();
    _bathDetailCtrl = TextEditingController();
    _kitchenCtrl = TextEditingController();
    _livingRoomCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _bedroomCountCtrl.dispose();
    _bathroomCountCtrl.dispose();
    _bedDetailCtrl.dispose();
    _bathDetailCtrl.dispose();
    _kitchenCtrl.dispose();
    _livingRoomCtrl.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    AppSnackBar.success(context, 'Đã lưu thông tin chi tiết');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin chi tiết'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildLabel('Mô tả marketing'),
            const SizedBox(height: AppSpacing.xs),
            _buildMultilineField(
              controller: _descriptionCtrl,
              hintText: 'Nhập mô tả marketing...',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Số phòng ngủ'),
                      const SizedBox(height: AppSpacing.xs),
                      _buildNumberField(
                        controller: _bedroomCountCtrl,
                        hintText: '0',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Số WC'),
                      const SizedBox(height: AppSpacing.xs),
                      _buildNumberField(
                        controller: _bathroomCountCtrl,
                        hintText: '0',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLabel('Chi tiết giường'),
            const SizedBox(height: AppSpacing.xs),
            _buildMultilineField(
              controller: _bedDetailCtrl,
              hintText: 'Nhập chi tiết giường...',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLabel('Chi tiết phòng tắm'),
            const SizedBox(height: AppSpacing.xs),
            _buildMultilineField(
              controller: _bathDetailCtrl,
              hintText: 'Nhập chi tiết phòng tắm...',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLabel('Phòng bếp', color: AppColors.teal),
            const SizedBox(height: AppSpacing.xs),
            _buildMultilineField(
              controller: _kitchenCtrl,
              hintText: 'Nhập thông tin phòng bếp...',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLabel('Phòng khách', color: AppColors.teal),
            const SizedBox(height: AppSpacing.xs),
            _buildMultilineField(
              controller: _livingRoomCtrl,
              hintText: 'Nhập thông tin phòng khách...',
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                onPressed: _onSave,
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
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {Color? color}) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.muted,
      ),
    );
  }

  Widget _buildMultilineField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 3,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.beVietnamPro(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: AppColors.muted,
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.ocean, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.beVietnamPro(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.beVietnamPro(
          fontSize: 14,
          color: AppColors.muted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.ocean, width: 1.5),
        ),
      ),
    );
  }
}
