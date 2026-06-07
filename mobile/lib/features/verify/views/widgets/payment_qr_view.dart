import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_color_scheme.dart';

/// Unified QR renderer for both VNPay QR and VietQR.
///
/// Backend returns QR in 2 forms:
/// 1. `payload` (raw EMVCo string, e.g. `00020101021238...`) — FE renders via
///    `QrImageView` (compact, scales cleanly).
/// 2. `imageBase64` (rendered PNG, may have `data:image/png;base64,` prefix) —
///    FE decodes + `Image.memory`. Fallback when backend uses the VNPay SDK
///    that emits a pre-rendered image.
///
/// The widget chooses the source in order: payload > imageBase64 > imageUrl.
/// If all are null, it shows a placeholder + error message.
///
/// [imageUrl] is the img.vietqr.io quick-link (server-rendered QR encoding
/// account + amount + memo) — used as a last-resort fallback when the backend
/// returns neither a raw EMVCo payload nor a base64 image.
class PaymentQrView extends StatelessWidget {
  final String? payload;
  final String? imageBase64;
  final String? imageUrl;
  final double size;

  const PaymentQrView({
    super.key,
    this.payload,
    this.imageBase64,
    this.imageUrl,
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
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        loadingBuilder: (context, widget, progress) {
          if (progress == null) return widget;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, _, __) =>
            _placeholder(context, 'Không tải được mã QR'),
      );
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
