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
            title: 'Phạm vi dịch vụ',
            description:
                'Halong24h là ứng dụng quản lý phòng dành cho chủ homestay, '
                'doanh nghiệp và cá nhân có phòng cho thuê (quản lý phòng, lịch '
                'và nhân viên). Ứng dụng không bán gói hay đăng ký trả phí.',
          ),
          const _TermItem(
            title: 'Tài khoản và thông tin',
            description:
                'Bạn chịu trách nhiệm cung cấp thông tin chính xác, cập nhật và '
                'bảo mật tài khoản của mình.',
          ),
          const _TermItem(
            title: 'Xác thực danh tính (KYC)',
            description:
                'Để đăng phòng và thêm nhân viên, bạn cần hoàn tất xác thực '
                'danh tính (KYC) và được quản trị viên kiểm duyệt trước. Việc '
                'này nhằm bảo đảm an toàn, uy tín, trách nhiệm và tránh đăng tin '
                'tràn lan, giả mạo ảnh hưởng đến hiệu suất hệ thống.',
          ),
          const _TermItem(
            title: 'Hành vi bị cấm',
            description:
                'Nghiêm cấm gian lận, spam, giả mạo, đăng tin sai sự thật. Bạn '
                'cam kết không sử dụng nền tảng cho bất kỳ mục đích trái pháp '
                'luật nào.',
          ),
          const _TermItem(
            title: 'Dữ liệu cá nhân',
            description:
                'Bạn đồng ý cho chúng tôi thu thập và xử lý dữ liệu theo Chính '
                'sách quyền riêng tư. Mọi hình ảnh được lưu trên Cloudinary. Khi '
                'bạn xoá tài khoản, dữ liệu KYC (gồm ảnh CCCD và selfie) sẽ bị '
                'xoá theo; hệ thống không lưu trữ cho mục đích riêng.',
          ),
          const _TermItem(
            title: 'Tạm khoá hoặc chấm dứt tài khoản',
            description:
                'Halong24h có thể giới hạn hoặc khoá tài khoản nếu phát hiện '
                'hành vi rủi ro, gian lận hoặc ảnh hưởng đến cộng đồng và hiệu '
                'suất hệ thống.',
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
