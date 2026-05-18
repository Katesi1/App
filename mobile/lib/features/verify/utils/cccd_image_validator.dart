import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../data/models/ocr_result.dart';
import '../data/models/verify_enums.dart';
import 'cccd_front_ocr_parser.dart';
import 'cccd_qr_parser.dart';

/// Result of validating a CCCD image from gallery.
class CccdValidationResult {
  /// True when CCCD-specific signals are detected (keyword text or QR payload
  /// matching the expected format).
  final bool isCccd;

  /// Extracted OCR/QR data (null if nothing was detected).
  final OCRResult? ocrResult;

  /// Reject reason (null on pass). Shown to user so they know why.
  final String? reason;

  const CccdValidationResult({
    required this.isCccd,
    this.ocrResult,
    this.reason,
  });
}

/// Validate a still image (from gallery) is a CCCD before uploading.
///
/// Unlike `CCCDScannerScreen` (live frame stream for auto-shutter), this
/// validator runs ML Kit once on a file to check whether it's a CCCD. Prevents
/// owners from accidentally uploading selfies/landscapes/other documents.
///
/// Logic:
/// - Front: run `TextRecognizer` → match keywords "CĂN CƯỚC CÔNG DÂN",
///   "CITIZEN IDENTITY"... (≥ 2 hits). On match, extract OCR fields.
/// - Back: run `BarcodeScanner` (QR mode) → look for a payload starting with
///   12 digits. On match, parse the QR.
class CccdImageValidator {
  CccdImageValidator._();

  /// Reliable keywords for the front of a VN CCCD. ≥ 2 hits to reduce false positives.
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

  /// Keywords for the back of a VN CCCD. Used as fallback when no QR is present (older chip).
  static const _backKeywords = [
    'ĐẶC ĐIỂM NHÂN DẠNG',
    'PERSONAL IDENTIFICATION',
    'NGÀY, THÁNG, NĂM',
    'DATE, MONTH, YEAR',
    'CỤC TRƯỞNG',
    'DIRECTOR GENERAL',
    'BỘ CÔNG AN',
    'MINISTRY OF PUBLIC SECURITY',
    'NƠI THƯỜNG TRÚ',
    'PLACE OF RESIDENCE',
  ];

  /// Validate an image from gallery. Returns the result + extracted OCR.
  ///
  /// **Important**: the caller is responsible for handling the result:
  /// - `isCccd: true` → upload as usual
  /// - `isCccd: false` → show warning dialog; may allow override or require
  ///   the user to retake
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

  /// Back side: try QR first (100% accurate on new chip); fallback to OCR
  /// keyword text (for old chip without QR — admin reviews + types manually).
  static Future<CccdValidationResult> _validateBack(InputImage input) async {
    final scanner = BarcodeScanner(formats: const [BarcodeFormat.qrCode]);
    try {
      final barcodes = await scanner.processImage(input);
      for (final b in barcodes) {
        final raw = b.rawValue;
        if (raw == null || raw.isEmpty) continue;
        // CCCD QR always starts with a 12-digit ID + |
        if (!RegExp(r'^\d{12}\|').hasMatch(raw)) continue;
        final ocr = VietnamCccdQrParser.parse(raw);
        if (ocr != null) {
          return CccdValidationResult(isCccd: true, ocrResult: ocr);
        }
      }
      // No QR → try OCR keyword text (old chip + blurry new chip).
      return _validateBackByText(input);
    } catch (e) {
      return CccdValidationResult(
        isCccd: false,
        reason: 'Không đọc được ảnh: $e',
      );
    } finally {
      await scanner.close();
    }
  }

  /// Fallback: OCR keyword text on the back side (≥2 hits). Passes when the
  /// distinctive markers "BỘ CÔNG AN", "CỤC TRƯỞNG", "ĐẶC ĐIỂM NHÂN DẠNG"... are found.
  static Future<CccdValidationResult> _validateBackByText(
    InputImage input,
  ) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(input);
      final hits = _countHits(recognized.text, _backKeywords);
      if (hits >= 2) {
        return const CccdValidationResult(isCccd: true);
      }
      return const CccdValidationResult(
        isCccd: false,
        reason: 'Ảnh không phải mặt sau CCCD. '
            'Vui lòng chụp đủ vùng có chữ "BỘ CÔNG AN" + "ĐẶC ĐIỂM NHÂN DẠNG" '
            '(và QR code nếu là CCCD chip mới).',
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

  static int _countKeywordHits(String text) => _countHits(text, _frontKeywords);

  static int _countHits(String text, List<String> keywords) {
    final upper = text.toUpperCase();
    var hits = 0;
    for (final k in keywords) {
      if (upper.contains(k)) hits++;
    }
    return hits;
  }
}
