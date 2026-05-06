import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../data/models/ocr_result.dart';
import '../data/models/verify_enums.dart';
import 'cccd_front_ocr_parser.dart';
import 'cccd_qr_parser.dart';

/// Kết quả validate ảnh CCCD từ gallery.
class CccdValidationResult {
  /// True nếu phát hiện đặc trưng CCCD trong ảnh (keyword text hoặc QR
  /// payload đúng format).
  final bool isCccd;

  /// Dữ liệu OCR/QR đã extract (null nếu không nhận diện được).
  final OCRResult? ocrResult;

  /// Lý do reject (null nếu pass). Hiện cho user biết tại sao.
  final String? reason;

  const CccdValidationResult({
    required this.isCccd,
    this.ocrResult,
    this.reason,
  });
}

/// Validate ảnh tĩnh (từ gallery) là CCCD trước khi upload.
///
/// Khác `CCCDScannerScreen` (live frame stream để auto-shutter), validator này
/// chạy ML Kit 1 lần trên file để check ảnh có phải CCCD không. Tránh trường
/// hợp owner gửi nhầm ảnh selfie/phong cảnh/giấy tờ khác.
///
/// Logic:
/// - Mặt trước: chạy `TextRecognizer` → match keyword "CĂN CƯỚC CÔNG DÂN",
///   "CITIZEN IDENTITY"... (≥ 2 hit). Có thì extract OCR fields.
/// - Mặt sau: chạy `BarcodeScanner` (QR mode) → tìm payload bắt đầu 12 chữ
///   số. Có thì parse QR.
class CccdImageValidator {
  CccdImageValidator._();

  /// Keywords tin cậy cho mặt trước CCCD VN. ≥ 2 hit để giảm false positive.
  static const _frontKeywords = [
    'CĂN CƯỚC CÔNG DÂN',
    'CAN CUOC CONG DAN',
    'CITIZEN IDENTITY',
    'IDENTITY CARD',
    'SOCIALIST REPUBLIC',
    'CỘNG HÒA XÃ HỘI',
    'HỌ VÀ TÊN',
    'FULL NAME',
    'NGÀY SINH',
    'DATE OF BIRTH',
    'QUỐC TỊCH',
    'NATIONALITY',
  ];

  /// Validate ảnh từ gallery. Trả về kết quả + extracted OCR.
  ///
  /// **Quan trọng**: caller responsible cho việc xử lý kết quả:
  /// - `isCccd: true` → upload bình thường
  /// - `isCccd: false` → show warning dialog, có thể allow override hoặc
  ///   bắt user chụp lại
  static Future<CccdValidationResult> validate({
    required File image,
    required CCCDSide side,
  }) async {
    final input = InputImage.fromFilePath(image.path);
    return side == CCCDSide.front
        ? _validateFront(input)
        : _validateBack(input);
  }

  static Future<CccdValidationResult> _validateFront(InputImage input) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(input);
      final text = recognized.text;
      final hits = _countKeywordHits(text);

      if (hits < 2) {
        return CccdValidationResult(
          isCccd: false,
          reason: 'Ảnh không chứa các thông tin đặc trưng của CCCD '
              '(số CCCD, họ tên, ngày sinh...). Có thể bạn chọn nhầm ảnh.',
        );
      }

      final ocr = CccdFrontOcrParser.parse(text);
      return CccdValidationResult(
        isCccd: true,
        ocrResult: ocr.isEmpty ? null : ocr,
      );
    } catch (e) {
      return CccdValidationResult(
        isCccd: false,
        reason: 'Không đọc được ảnh: $e',
      );
    } finally {
      await recognizer.close();
    }
  }

  static Future<CccdValidationResult> _validateBack(InputImage input) async {
    final scanner = BarcodeScanner(formats: const [BarcodeFormat.qrCode]);
    try {
      final barcodes = await scanner.processImage(input);
      for (final b in barcodes) {
        final raw = b.rawValue;
        if (raw == null || raw.isEmpty) continue;
        // CCCD QR luôn bắt đầu bằng 12-digit ID + |
        if (!RegExp(r'^\d{12}\|').hasMatch(raw)) continue;
        final ocr = VietnamCccdQrParser.parse(raw);
        if (ocr != null) {
          return CccdValidationResult(isCccd: true, ocrResult: ocr);
        }
      }
      return const CccdValidationResult(
        isCccd: false,
        reason: 'Không tìm thấy QR code CCCD trong ảnh. '
            'CCCD chip mới (sau 2021) có QR ở mặt sau — vui lòng chụp '
            'sao cho thấy rõ QR.',
      );
    } catch (e) {
      return CccdValidationResult(
        isCccd: false,
        reason: 'Không đọc được ảnh: $e',
      );
    } finally {
      await scanner.close();
    }
  }

  static int _countKeywordHits(String text) {
    final upper = text.toUpperCase();
    var hits = 0;
    for (final k in _frontKeywords) {
      if (upper.contains(k)) hits++;
    }
    return hits;
  }
}
