import 'dart:io';

import 'ocr_result.dart';

/// Kết quả pop từ [CCCDScannerScreen] về caller.
///
/// Bao gồm cả ảnh đã chụp + dữ liệu OCR/QR đã extract trên device. Caller
/// truyền cả 2 lên backend trong cùng multipart request — backend KHÔNG cần
/// chạy OCR engine của riêng nó.
class ScannerResult {
  final File image;

  /// Dữ liệu trích xuất từ ảnh (OCR mặt trước hoặc QR mặt sau). `null` nếu
  /// scanner không extract được (vd ảnh chụp tay, không nhận diện được).
  final OCRResult? ocrResult;

  const ScannerResult({required this.image, this.ocrResult});
}
