import 'dart:io';

import 'ocr_result.dart';

/// Result popped from [CCCDScannerScreen] back to the caller.
///
/// Includes the captured image + data already extracted on-device (OCR/QR).
/// The caller forwards both to backend in the same multipart request — the
/// backend does NOT need to run its own OCR engine.
class ScannerResult {
  final File image;

  /// Data extracted from the image (front OCR or back QR). `null` if the
  /// scanner couldn't extract (e.g. handheld photo, unreadable).
  final OCRResult? ocrResult;

  const ScannerResult({required this.image, this.ocrResult});
}
