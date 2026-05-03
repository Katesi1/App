import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Crop ảnh chụp full-resolution về đúng vùng khung CCCD trên màn hình.
///
/// CCCD chuẩn TCVN: 85.6 × 53.98 mm → aspect ratio ≈ 1.586:1.
/// Scanner hiển thị frame ở center màn hình, rộng [frameWidthFraction]
/// (mặc định 0.86 của bề ngang preview). Hàm này crop center của ảnh
/// theo cùng tỉ lệ + trả về `File` mới đã ghi ra disk.
class CCCDImageCropper {
  CCCDImageCropper._();

  /// Tỉ lệ chuẩn CCCD (rộng / cao).
  static const double aspectRatio = 1.586;

  /// Crop center [src] về frame CCCD và lưu xuống tmp dir.
  ///
  /// [frameWidthFraction] là phần trăm chiều rộng frame so với chiều rộng
  /// preview (0..1). Mặc định 0.86 — khớp với UI scanner.
  ///
  /// Trả về `null` nếu decode thất bại.
  static Future<File?> cropToCccdFrame(
    File src, {
    double frameWidthFraction = 0.86,
  }) async {
    final bytes = await src.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // Ảnh từ camera plugin đã được orientation-corrected (EXIF baked).
    // Portrait shot → ảnh có height > width.
    final w = decoded.width;
    final h = decoded.height;

    // Tính frame width theo phần trăm của bề ngang ảnh.
    final frameW = (w * frameWidthFraction).round();
    final frameH = (frameW / aspectRatio).round();

    // Center crop.
    final left = ((w - frameW) / 2).round().clamp(0, w);
    final top = ((h - frameH) / 2).round().clamp(0, h);

    final cropped = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: frameW.clamp(1, w - left),
      height: frameH.clamp(1, h - top),
    );

    final jpg = img.encodeJpg(cropped, quality: 88);
    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/cccd_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final out = File(outPath);
    await out.writeAsBytes(jpg, flush: true);
    return out;
  }
}
