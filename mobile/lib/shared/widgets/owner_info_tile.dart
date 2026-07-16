import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_spacing.dart';
import 'loading_widget.dart';

/// Hiển thị thông tin chủ sở hữu (tên + SĐT) — chỉ dùng cho viewer
/// cross-owner (ADMIN / SALE hệ thống). Gate hiển thị nằm ở caller
/// (`user.seesCrossOwnerData`), widget này chỉ lo phần render.
///
/// - [dense] = true  → chip gọn 1 dòng cho card danh sách.
/// - [dense] = false → section đầy đủ (icon + tên đậm + SĐT phụ) cho màn chi tiết.
///
/// SĐT rỗng → hiển thị "Chưa có SĐT" mờ, không bấm-gọi.
/// SĐT có giá trị → bấm để gọi (tel:), fallback sao chép vào clipboard.
class OwnerInfoTile extends StatelessWidget {
  final String name;
  final String phone;
  final bool dense;

  const OwnerInfoTile({
    super.key,
    required this.name,
    required this.phone,
    this.dense = false,
  });

  bool get _hasPhone => phone.trim().isNotEmpty;

  Future<void> _callOwner(BuildContext context) async {
    if (!_hasPhone) {
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      await Clipboard.setData(ClipboardData(text: phone.trim()));
      if (context.mounted) {
        AppSnackBar.info(context, 'Đã sao chép SĐT: ${phone.trim()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return dense ? _buildDense(context) : _buildSection(context);
  }

  // ── Chip gọn cho card danh sách ─────────────────────────────────────────
  Widget _buildDense(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: _hasPhone ? () => _callOwner(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.bgSurfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline_rounded,
                size: 13, color: colors.textSecondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                _hasPhone
                    ? 'Chủ: $name · ${phone.trim()}'
                    : 'Chủ: $name · Chưa có SĐT',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_hasPhone) ...[
              const SizedBox(width: 4),
              Icon(Icons.phone_rounded, size: 12, color: colors.brand),
            ],
          ],
        ),
      ),
    );
  }

  // ── Section đầy đủ cho màn chi tiết ─────────────────────────────────────
  Widget _buildSection(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.bgSurfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: _hasPhone ? () => _callOwner(context) : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.storefront_outlined,
                    color: colors.brand, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chủ sở hữu',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: colors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _hasPhone ? phone.trim() : 'Chưa có SĐT',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _hasPhone
                            ? colors.textSecondary
                            : colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasPhone)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.brand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.phone_rounded,
                      color: colors.brand, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
