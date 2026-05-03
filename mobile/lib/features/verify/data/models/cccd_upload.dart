import 'package:equatable/equatable.dart';

import 'ocr_result.dart';

/// Một upload CCCD (front hoặc back) với kết quả OCR.
class CCCDUpload extends Equatable {
  final String id;
  final String imageUrl;
  final OCRResult? ocrResult;

  /// Confidence của OCR (0..1). < 0.8 → cảnh báo người dùng chụp lại.
  final double confidence;
  final DateTime uploadedAt;

  /// Đường dẫn local (nếu chưa upload xong / chỉ preview offline).
  final String? localPath;

  const CCCDUpload({
    required this.id,
    required this.imageUrl,
    this.ocrResult,
    required this.confidence,
    required this.uploadedAt,
    this.localPath,
  });

  factory CCCDUpload.fromJson(Map<String, dynamic> json) => CCCDUpload(
        id: json['id'] as String,
        imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
        ocrResult: json['ocrResult'] == null && json['ocr_result'] == null
            ? null
            : OCRResult.fromJson(
                (json['ocrResult'] ?? json['ocr_result']) as Map<String, dynamic>,
              ),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        uploadedAt: DateTime.parse(
          (json['uploadedAt'] ?? json['uploaded_at']) as String,
        ),
        localPath: json['localPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'ocrResult': ocrResult?.toJson(),
        'confidence': confidence,
        'uploadedAt': uploadedAt.toIso8601String(),
        'localPath': localPath,
      };

  CCCDUpload copyWith({
    String? id,
    String? imageUrl,
    OCRResult? ocrResult,
    double? confidence,
    DateTime? uploadedAt,
    String? localPath,
  }) =>
      CCCDUpload(
        id: id ?? this.id,
        imageUrl: imageUrl ?? this.imageUrl,
        ocrResult: ocrResult ?? this.ocrResult,
        confidence: confidence ?? this.confidence,
        uploadedAt: uploadedAt ?? this.uploadedAt,
        localPath: localPath ?? this.localPath,
      );

  @override
  List<Object?> get props =>
      [id, imageUrl, ocrResult, confidence, uploadedAt, localPath];
}
