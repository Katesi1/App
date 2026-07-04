import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/user_model.dart';

/// Gate tạo phòng theo tài khoản nhận tiền. Trả về `true` nếu được phép tiếp
/// tục tạo phòng; `false` nếu đã chặn (đã hiện popup + điều hướng tuỳ chọn).
///
/// Chỉ áp cho OWNER đã qua KYC nhưng CHƯA có bank được duyệt — SALE/ADMIN và
/// owner chưa KYC (đã có luồng khác) không bị chặn ở đây.
Future<bool> ensureBankForPropertyCreate(
  BuildContext context,
  UserModel? user,
) async {
  if (!(user?.isOwner ?? false)) return true;
  if (!(user?.isKycVerified ?? false)) return true; // KYC gate lo ở nơi khác
  if (user!.hasApprovedBank) return true;

  final go = await showBankRequiredDialog(context, bankStatus: user.bankStatus);
  if (go == true && context.mounted) {
    context.push('/profile/bank-account');
  }
  return false;
}

/// Popup chặn tạo phòng khi OWNER chưa có tài khoản nhận tiền được duyệt.
/// Trả về `true` nếu user chọn đi cấu hình ngay.
///
/// [bankStatus]: none | pending | rejected — để đổi nội dung cho đúng ngữ cảnh
/// (đang chờ duyệt vs chưa có vs bị từ chối).
Future<bool?> showBankRequiredDialog(
  BuildContext context, {
  String bankStatus = 'none',
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) => _BankRequiredDialog(bankStatus: bankStatus),
  );
}

class _BankRequiredDialog extends StatelessWidget {
  final String bankStatus;
  const _BankRequiredDialog({required this.bankStatus});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPending = bankStatus == 'pending';
    final isRejected = bankStatus == 'rejected';

    final (accent, icon, title, body, cta) = isPending
        ? (
            AppColors.amber,
            Icons.hourglass_top_rounded,
            'Tài khoản đang chờ duyệt',
            'Tài khoản nhận tiền của bạn đang chờ admin duyệt. Bạn có thể tạo '
                'phòng ngay khi tài khoản được duyệt.',
            'Xem trạng thái',
          )
        : isRejected
            ? (
                AppColors.coral,
                Icons.error_outline_rounded,
                'Tài khoản bị từ chối',
                'Tài khoản nhận tiền chưa hợp lệ. Vui lòng cập nhật và gửi lại '
                    'để có thể tạo phòng.',
                'Cập nhật ngay',
              )
            : (
                AppColors.ocean,
                Icons.account_balance_rounded,
                'Cần tài khoản nhận tiền',
                'Để tạo phòng, bạn cần thêm tài khoản ngân hàng nhận tiền cọc. '
                    'Tài khoản sẽ được admin duyệt trước khi dùng để tạo mã QR '
                    'cho khách chuyển cọc.',
                'Thêm tài khoản',
              );

    return Dialog(
      backgroundColor: colors.bgSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, color: accent, size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.5,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(cta),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Để sau',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
