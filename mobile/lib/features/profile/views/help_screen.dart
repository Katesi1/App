import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7 — chưa có token sẵn
const _jadeMidLight = Color(0xFF1B7E94);

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _supportPhone = '0901234567';
  static const _supportEmail = 'support@halong24h.vn';
  static const _supportHours = 'T2 - CN: 8:00 - 22:00';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqCategory> get _filteredCategories {
    if (_query.isEmpty) return _faqCategories;
    final q = _query.toLowerCase();
    final result = <_FaqCategory>[];
    for (final cat in _faqCategories) {
      final matched = cat.items
          .where((item) =>
              item.question.toLowerCase().contains(q) ||
              item.answer.toLowerCase().contains(q))
          .toList();
      if (matched.isNotEmpty) {
        result.add(_FaqCategory(
          icon: cat.icon,
          title: cat.title,
          items: matched,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredCategories;

    final headerGradient = isDark
        ? const [AppColors.darkBg, AppColors.darkBorder]
        : const [AppColors.jade500, _jadeMidLight];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ giúp'),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Header + Search ───────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: headerGradient,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Xin chào, bạn cần giúp gì?',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tìm câu trả lời nhanh hoặc liên hệ hỗ trợ',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm câu hỏi...',
                      hintStyle: GoogleFonts.beVietnamPro(
                        color: colors.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colors.textSecondary,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colors.bgSurface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Quick contact cards ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _ContactCard(
                      icon: Icons.phone_outlined,
                      label: 'Gọi điện',
                      value: _supportPhone,
                      color: colors.success,
                      onTap: () => _launchPhone(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ContactCard(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _supportEmail,
                      color: colors.brand,
                      onTap: () => _launchEmail(context),
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Support hours ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.warningBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        color: colors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Giờ hỗ trợ: $_supportHours',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── FAQ Section title ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Câu hỏi thường gặp',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── FAQ categories ────────────────────────────────────
          if (filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48,
                        color: colors.textTertiary.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'Không tìm thấy kết quả',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thử từ khóa khác hoặc liên hệ hỗ trợ',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final cat = filtered[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: _FaqCategoryCard(category: cat),
                  )
                      .animate(delay: Duration(milliseconds: 250 + index * 80))
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0);
                },
                childCount: filtered.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Footer ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    Icon(Icons.headset_mic_outlined,
                        color: colors.brand, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Vẫn cần trợ giúp?',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.brand,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đội ngũ hỗ trợ luôn sẵn sàng giúp bạn',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _launchPhone(context),
                            icon: const Icon(Icons.phone_outlined, size: 18),
                            label: const Text('Gọi ngay'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.brand,
                              side: BorderSide(color: colors.brand),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _launchEmail(context),
                            icon: const Icon(Icons.email_outlined, size: 18),
                            label: const Text('Gửi email'),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.brand,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── App version ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Center(
              child: Text(
                'Halong24h v1.0.0',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      await Clipboard.setData(ClipboardData(text: _supportPhone));
      if (context.mounted) {
        AppSnackBar.info(context, 'Đã sao chép SĐT: $_supportPhone');
      }
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Hỗ trợ Halong24h'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      await Clipboard.setData(ClipboardData(text: _supportEmail));
      if (context.mounted) {
        AppSnackBar.info(context, 'Đã sao chép email: $_supportEmail');
      }
    }
  }
}

// ─── Contact Card ───────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: colors.bgSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FAQ Category Card (Expandable) ─────────────────────────────────────────

class _FaqCategoryCard extends StatelessWidget {
  final _FaqCategory category;

  const _FaqCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.brand.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(category.icon, color: colors.brand, size: 20),
          ),
          title: Text(
            category.title,
            style: GoogleFonts.beVietnamPro(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          subtitle: Text(
            '${category.items.length} câu hỏi',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          children:
              category.items.map((item) => _FaqItemTile(item: item)).toList(),
        ),
      ),
    );
  }
}

// ─── FAQ Item Tile ──────────────────────────────────────────────────────────

class _FaqItemTile extends StatelessWidget {
  final _FaqItem item;

  const _FaqItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
        leading:
            Icon(Icons.help_outline_rounded, color: colors.brand, size: 18),
        title: Text(
          item.question,
          style: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              item.answer,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                height: 1.6,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FAQ Data ───────────────────────────────────────────────────────────────

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _FaqCategory {
  final IconData icon;
  final String title;
  final List<_FaqItem> items;
  const _FaqCategory({
    required this.icon,
    required this.title,
    required this.items,
  });
}

const _faqCategories = <_FaqCategory>[
  _FaqCategory(
    icon: Icons.person_outline_rounded,
    title: 'Tài khoản & Đăng nhập',
    items: [
      _FaqItem(
        question: 'Làm sao để tạo tài khoản?',
        answer: 'Bạn có thể tạo tài khoản bằng cách nhấn "Đăng ký" ở màn hình '
            'đăng nhập. Nhập số điện thoại, mật khẩu và chọn vai trò '
            '(Khách hàng hoặc Nhân viên). Bạn cũng có thể đăng ký nhanh '
            'bằng tài khoản Google.',
      ),
      _FaqItem(
        question: 'Quên mật khẩu thì phải làm sao?',
        answer: 'Tại màn hình đăng nhập, nhấn "Quên mật khẩu" và nhập số điện '
            'thoại hoặc email đã đăng ký. Hệ thống sẽ gửi mã xác nhận '
            'để bạn đặt lại mật khẩu mới.',
      ),
      _FaqItem(
        question: 'Làm sao để đổi mật khẩu?',
        answer: 'Vào phần "Tài khoản" → "Đổi mật khẩu". Nhập mật khẩu hiện '
            'tại, sau đó nhập mật khẩu mới (tối thiểu 8 ký tự, bao gồm '
            'chữ hoa, chữ thường, số và ký tự đặc biệt).',
      ),
      _FaqItem(
        question: 'Tôi có thể đăng nhập bằng Google không?',
        answer: 'Có! Tại màn hình đăng nhập, nhấn nút "Đăng nhập với Google". '
            'Nếu là lần đầu, hệ thống sẽ tự tạo tài khoản cho bạn.',
      ),
    ],
  ),
  _FaqCategory(
    icon: Icons.calendar_month_outlined,
    title: 'Đặt phòng',
    items: [
      _FaqItem(
        question: 'Làm sao để đặt phòng?',
        answer: 'Từ trang chủ, nhấn "Tìm phòng" → chọn ngày nhận/trả phòng, '
            'số lượng khách → chọn phòng phù hợp → nhấn "Đặt phòng". '
            'Booking sẽ được giữ (HOLD) trong 30 phút để bạn xác nhận.',
      ),
      _FaqItem(
        question: 'Trạng thái đặt phòng gồm những gì?',
        answer: '• Đang giữ (HOLD): Phòng được giữ 30 phút, chờ xác nhận.\n'
            '• Đã xác nhận (CONFIRMED): Đặt phòng thành công.\n'
            '• Đã huỷ (CANCELLED): Đặt phòng đã bị huỷ.\n'
            '• Hoàn thành (COMPLETED): Khách đã trả phòng.',
      ),
      _FaqItem(
        question: 'Tôi có thể huỷ đặt phòng không?',
        answer: 'Có. Vào "Booking của tôi", chọn booking cần huỷ và nhấn '
            '"Huỷ đặt phòng". Lưu ý: chỉ huỷ được khi booking đang ở '
            'trạng thái "Đang giữ" hoặc "Đã xác nhận".',
      ),
      _FaqItem(
        question: 'Phòng bị giữ (HOLD) nghĩa là gì?',
        answer: 'Khi bạn đặt phòng, phòng sẽ được giữ trong 30 phút. Trong '
            'thời gian này, nhân viên sẽ xác nhận booking của bạn. Nếu '
            'quá thời gian mà chưa được xác nhận, booking sẽ tự động huỷ.',
      ),
    ],
  ),
  _FaqCategory(
    icon: Icons.apartment_outlined,
    title: 'Phòng & Homestay',
    items: [
      _FaqItem(
        question: 'Làm sao để xem chi tiết phòng?',
        answer: 'Tại trang "Tìm phòng", nhấn vào phòng bạn quan tâm để xem '
            'thông tin chi tiết bao gồm: hình ảnh, giá, tiện nghi, '
            'sức chứa và lịch trống.',
      ),
      _FaqItem(
        question: 'Giá phòng được tính như thế nào?',
        answer: 'Giá phòng được tính theo đêm. Giá có thể khác nhau giữa '
            'ngày thường và cuối tuần/ngày lễ. Tổng tiền = Giá phòng '
            '× Số đêm lưu trú.',
      ),
      _FaqItem(
        question: 'Phòng có những trạng thái nào?',
        answer: '• Trống (xanh lá): Phòng sẵn sàng cho khách đặt.\n'
            '• Đã đặt (vàng): Phòng có booking sắp tới.\n'
            '• Đang ở (xanh dương): Khách đang lưu trú.\n'
            '• Bảo trì (xám): Phòng đang bảo trì, không thể đặt.',
      ),
    ],
  ),
  _FaqCategory(
    icon: Icons.payment_outlined,
    title: 'Thanh toán',
    items: [
      _FaqItem(
        question: 'Các hình thức thanh toán?',
        answer: 'Hiện tại hỗ trợ thanh toán trực tiếp tại homestay khi '
            'nhận phòng. Chúng tôi đang phát triển thêm các phương '
            'thức thanh toán online trong thời gian tới.',
      ),
      _FaqItem(
        question: 'Chính sách hoàn tiền như thế nào?',
        answer: 'Nếu bạn huỷ booking trước thời gian nhận phòng 24 giờ, '
            'bạn sẽ được hoàn tiền 100%. Huỷ trong vòng 24 giờ trước '
            'nhận phòng sẽ tuỳ theo chính sách của từng homestay.',
      ),
    ],
  ),
  _FaqCategory(
    icon: Icons.admin_panel_settings_outlined,
    title: 'Quản lý (Dành cho chủ homestay)',
    items: [
      _FaqItem(
        question: 'Tôi là chủ homestay, làm sao để bắt đầu?',
        answer: 'Đăng ký tài khoản với vai trò "Nhân viên", sau đó liên hệ '
            'admin để được cấp quyền quản lý homestay. Bạn sẽ có thể '
            'thêm phòng, quản lý booking và xem báo cáo.',
      ),
      _FaqItem(
        question: 'Làm sao để xác nhận booking?',
        answer: 'Vào phần "Lịch" hoặc "Tổng quan" → chọn booking đang ở '
            'trạng thái "Đang giữ" → nhấn "Xác nhận". Booking sẽ '
            'chuyển sang trạng thái "Đã xác nhận".',
      ),
    ],
  ),
  _FaqCategory(
    icon: Icons.settings_outlined,
    title: 'Cài đặt & Khác',
    items: [
      _FaqItem(
        question: 'Làm sao để bật chế độ tối?',
        answer: 'Vào "Tài khoản" → bật "Chế độ tối". Giao diện sẽ chuyển '
            'sang nền tối, giúp bảo vệ mắt khi sử dụng vào ban đêm.',
      ),
      _FaqItem(
        question: 'Thông tin cá nhân có được bảo mật không?',
        answer: 'Có. Chúng tôi sử dụng mã hoá bảo mật để lưu trữ token '
            'đăng nhập và thông tin cá nhân. Dữ liệu được truyền tải '
            'an toàn qua HTTPS.',
      ),
    ],
  ),
];
