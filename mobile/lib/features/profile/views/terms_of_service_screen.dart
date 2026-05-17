import 'package:flutter/material.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Điều khoản sử dụng')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.warningBg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'Khi tiếp tục sử dụng Halong24h, bạn xác nhận đã đọc '
              'và đồng ý với các điều khoản dịch vụ dưới đây.',
              style: TextStyle(color: colors.warning, height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _TermItem(
            title: 'Tài khoản và thông tin',
            description:
                'Bạn chịu trách nhiệm cung cấp thông tin chính xác và cập nhật '
                'để đảm bảo quyền lợi giao dịch.',
          ),
          const _TermItem(
            title: 'Hành vi bị cấm',
            description:
                'Nghiêm cấm gian lận, spam, giả mạo, hoặc sử dụng nền tảng '
                'cho mục đích vi phạm pháp luật.',
          ),
          const _TermItem(
            title: 'Đặt phòng và thanh toán',
            description:
                'Bạn cần tuân thủ chính sách đặt/hủy phòng và nghĩa vụ thanh toán '
                'theo từng giao dịch cụ thể.',
          ),
          const _TermItem(
            title: 'Tạm khóa hoặc chấm dứt tài khoản',
            description:
                'Halong24h có thể giới hạn hoặc khóa tài khoản nếu phát hiện '
                'hành vi rủi ro ảnh hưởng đến cộng đồng.',
          ),
          const _TermItem(
            title: 'Cập nhật điều khoản',
            description:
                'Điều khoản có thể được cập nhật để phù hợp vận hành và pháp lý. '
                'Việc tiếp tục dùng app sau cập nhật được xem là đồng ý.',
          ),
        ],
      ),
    );
  }
}

class _TermItem extends StatelessWidget {
  final String title;
  final String description;

  const _TermItem({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
