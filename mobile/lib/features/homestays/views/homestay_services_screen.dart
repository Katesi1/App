import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';

class HomestayServicesScreen extends StatefulWidget {
  final String homestayId;

  const HomestayServicesScreen({super.key, required this.homestayId});

  @override
  State<HomestayServicesScreen> createState() => _HomestayServicesScreenState();
}

class _HomestayServicesScreenState extends State<HomestayServicesScreen> {
  final List<String> _services = [
    'Dịch vụ thuê nấu ăn tại Villa',
    'Setup BBQ tại Villa',
    'Tiệc Gala Dinner theo thực đơn yêu cầu',
    'Thuê Dọn dẹp bếp, dụng cụ BBQ sau bữa ăn',
    'Than hoa, thực phẩm',
    'Hỗ trợ đặt xe đưa đón, vé tàu, vé công viên chiết khấu cao',
  ];

  Future<void> _showServiceDialog({int? index}) async {
    final isEdit = index != null;
    final controller = TextEditingController(
      text: isEdit ? _services[index] : '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEdit ? 'Sửa dịch vụ' : 'Thêm dịch vụ',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.navy,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            style: GoogleFonts.beVietnamPro(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nhập tên dịch vụ',
              hintStyle: GoogleFonts.beVietnamPro(
                color: AppColors.muted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(
                  color: AppColors.ocean,
                  width: 1.5,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên dịch vụ';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Huỷ',
              style: GoogleFonts.beVietnamPro(
                color: AppColors.muted,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ocean,
            ),
            child: Text(
              isEdit ? 'Cập nhật' : 'Thêm',
              style: GoogleFonts.beVietnamPro(),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isEdit) {
          _services[index] = result;
        } else {
          _services.add(result);
        }
      });
    }
  }

  void _deleteService(int index) {
    setState(() {
      _services.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dịch vụ trả phí'),
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(
            child: _services.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.room_service_outlined,
                    message: 'Chưa có dịch vụ',
                    subMessage: 'Nhấn + để thêm dịch vụ mới',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _services.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.border,
                    ),
                    itemBuilder: (context, index) =>
                        _buildServiceItem(index),
                  ),
          ),
          _buildSaveButton(),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 40,
        height: 40,
        child: FloatingActionButton(
          onPressed: () => _showServiceDialog(),
          backgroundColor: AppColors.ocean,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.oceanPale,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.oceanMid,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Khách liên hệ sale để đặt dịch vụ',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: AppColors.ocean,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _services[index],
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.navy,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _showServiceDialog(index: index),
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.ocean,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            onPressed: () => _deleteService(index),
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.coral,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
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
              AppSnackBar.success(context, 'Đã lưu dịch vụ');
              Navigator.pop(context);
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
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
