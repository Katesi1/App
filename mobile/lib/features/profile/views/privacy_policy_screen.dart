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
              'Halong24h là ứng dụng quản lý phòng dành cho chủ homestay, '
              'doanh nghiệp và cá nhân có phòng cho thuê. Chúng tôi cam kết '
              'bảo vệ dữ liệu cá nhân của bạn — chính sách này mô tả cách chúng '
              'tôi thu thập, sử dụng, lưu trữ và bảo vệ dữ liệu.',
              style: TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _PolicySection(
            title: '1. Dữ liệu chúng tôi thu thập',
            points: [
              'Thông tin tài khoản: họ tên, email, số điện thoại.',
              'Dữ liệu vận hành: thông tin phòng, lịch đặt phòng và nhân viên '
                  'do bạn tạo, quản lý.',
              'Dữ liệu xác thực danh tính (KYC): ảnh CCCD và ảnh selfie, chỉ '
                  'thu thập với chủ phòng khi đăng ký vận hành.',
            ],
          ),
          const _PolicySection(
            title: '2. Mục đích sử dụng',
            points: [
              'Đăng nhập, xác thực người dùng và phân quyền (chủ / nhân viên).',
              'Cung cấp công cụ quản lý phòng, lịch và nhân viên.',
              'Bảo đảm an toàn, uy tín và trách nhiệm của người đăng phòng; '
                  'phòng chống gian lận, đăng tin tràn lan hoặc giả mạo.',
              'Chúng tôi cam kết KHÔNG sử dụng dữ liệu của bạn vào bất kỳ mục '
                  'đích trái phép nào.',
            ],
          ),
          const _PolicySection(
            title: '3. Xác thực danh tính (KYC)',
            points: [
              'KYC chỉ phục vụ mục đích an toàn, uy tín và trách nhiệm — không '
                  'dùng cho nhận diện khuôn mặt hay bất kỳ mục đích nào khác.',
              'Quản trị viên (admin) sẽ kiểm duyệt KYC trước khi chủ phòng được '
                  'đăng phòng và thêm nhân viên, nhằm tránh đăng tin tràn lan, '
                  'giả mạo làm ảnh hưởng hiệu suất hệ thống.',
              'Chúng tôi cam kết không dùng dữ liệu KYC cho mục đích trái phép '
                  'và không chia sẻ ra ngoài trừ khi pháp luật yêu cầu.',
            ],
          ),
          const _PolicySection(
            title: '4. Lưu trữ & hình ảnh',
            points: [
              'Mọi hình ảnh (ảnh phòng, ảnh CCCD và selfie KYC) được lưu trữ '
                  'trên Cloudinary.',
              'Dữ liệu được bảo vệ và chỉ dùng cho việc vận hành dịch vụ; hệ '
                  'thống không lưu trữ dữ liệu cá nhân cho mục đích riêng.',
            ],
          ),
          const _PolicySection(
            title: '5. Xoá dữ liệu',
            points: [
              'Khi bạn xoá tài khoản, toàn bộ dữ liệu cá nhân và dữ liệu KYC '
                  '(bao gồm ảnh CCCD và selfie) sẽ bị xoá theo.',
              'Hệ thống không giữ lại các thông tin này cho mục đích riêng sau '
                  'khi tài khoản bị xoá.',
            ],
          ),
          const _PolicySection(
            title: '6. Chia sẻ dữ liệu',
            points: [
              'Không bán dữ liệu cá nhân cho bên thứ ba.',
              'Chỉ chia sẻ khi có yêu cầu hợp pháp từ cơ quan có thẩm quyền.',
            ],
          ),
          const _PolicySection(
            title: '7. Quyền của người dùng',
            points: [
              'Yêu cầu chỉnh sửa thông tin cá nhân.',
              'Yêu cầu bản sao dữ liệu cá nhân.',
              'Yêu cầu xoá tài khoản cùng toàn bộ dữ liệu KYC.',
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
