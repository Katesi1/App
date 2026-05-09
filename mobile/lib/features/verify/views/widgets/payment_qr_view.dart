import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_color_scheme.dart';

/// Render QR thống nhất cho cả VNPay QR + VietQR.
///
/// Backend có 2 cách trả QR:
/// 1. `payload` (EMVCo raw string, vd `00020101021238...`) — FE render bằng
///    `QrImageView` (nhỏ gọn, scale tốt).
/// 2. `imageBase64` (PNG đã render, có thể có prefix `data:image/png;base64,`)
///    — FE decode + `Image.memory`. Fallback khi backend dùng SDK VNPay sinh
///    sẵn ảnh.
///
/// Widget tự chọn nguồn theo thứ tự: payload > imageBase64. Nếu cả 2 null thì
/// hiện placeholder + thông báo lỗi.
class PaymentQrView extends StatelessWidget {
  final String? payload;
  final String? imageBase64;
  final double size;

  const PaymentQrView({
    super.key,
    this.payload,
    this.imageBase64,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget child;
    if (payload != null && payload!.isNotEmpty) {
      child = QrImageView(
        data: payload!,
        size: size,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
    } else if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        final raw = imageBase64!.contains(',')
            ? imageBase64!.split(',').last
            : imageBase64!;
        final bytes = base64Decode(raw);
        child = Image.memory(
          Uint8List.fromList(bytes),
          width: size,
          height: size,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );
      } catch (_) {
        child = _placeholder(context, 'Ảnh QR không hợp lệ');
      }
    } else {
      child = _placeholder(context, 'Chưa có dữ liệu QR');
    }

    return Container(
      width: size + 16,
      height: size + 16,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderDefault),
      ),
      child: child,
    );
  }

  Widget _placeholder(BuildContext context, String msg) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.bgSurfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 64, color: colors.textTertiary),
          const SizedBox(height: 6),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
