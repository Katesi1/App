import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Crop a full-resolution capture down to the CCCD frame shown on screen.
///
/// TCVN standard CCCD: 85.6 × 53.98 mm → aspect ratio ≈ 1.586:1.
/// The scanner shows a frame at screen center with width [frameWidthFraction]
/// (default 0.86 of the preview width). This function center-crops the image
/// at the same ratio and returns a new `File` written to disk.
class CCCDImageCropper {
  CCCDImageCropper._();

  /// Standard CCCD aspect ratio (width / height).
  static const double aspectRatio = 1.586;

  /// Center-crop [src] to the CCCD frame and save to the tmp dir.
  ///
  /// [frameWidthFraction] is the frame width as a fraction of the preview
  /// width (0..1). Default 0.86 — matches the scanner UI.
  ///
  /// Returns `null` if decoding fails.
  static Future<File?> cropToCccdFrame(
    File src, {
    double frameWidthFraction = 0.86,
  }) async {
    final bytes = await src.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // Images from the camera plugin are already orientation-corrected (EXIF baked).
    // Portrait shot → height > width.
    final w = decoded.width;
    final h = decoded.height;

    // Compute frame width as a fraction of the image width.
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
