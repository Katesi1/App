import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Chính sách quyền riêng tư')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.borderDefault),
            ),
            child: const Text(
              'Halong24h cam kết bảo vệ dữ liệu cá nhân của bạn. '
              'Chính sách này mô tả cách chúng tôi thu thập, sử dụng, '
              'lưu trữ và bảo vệ dữ liệu.',
              style: TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _PolicySection(
            title: '1. Dữ liệu thu thập',
            points: [
              'Thông tin tài khoản: họ tên, email, số điện thoại.',
              'Thông tin giao dịch: đặt phòng, thanh toán, hóa đơn.',
              'Dữ liệu xác thực KYC khi chủ homestay đăng ký vận hành.',
            ],
          ),
          const _PolicySection(
            title: '2. Mục đích sử dụng',
            points: [
              'Xử lý đăng nhập, xác thực người dùng và phân quyền.',
              'Cung cấp dịch vụ đặt phòng, quản lý booking, hỗ trợ khách hàng.',
              'Phòng chống gian lận, tăng độ an toàn vận hành nền tảng.',
            ],
          ),
          const _PolicySection(
            title: '3. Chia sẻ dữ liệu',
            points: [
              'Chỉ chia sẻ khi cần cho đối tác thanh toán/vận hành liên quan.',
              'Hoặc khi có yêu cầu hợp pháp từ cơ quan có thẩm quyền.',
              'Không bán dữ liệu cá nhân cho bên thứ ba.',
            ],
          ),
          const _PolicySection(
            title: '4. Quyền của người dùng',
            points: [
              'Yêu cầu chỉnh sửa thông tin cá nhân.',
              'Yêu cầu bản sao dữ liệu cá nhân.',
              'Yêu cầu xóa tài khoản theo chính sách.',
            ],
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final List<String> points;

  const _PolicySection({
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...points.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $item',
                style: TextStyle(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
