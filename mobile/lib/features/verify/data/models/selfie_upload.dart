import 'package:equatable/equatable.dart';

class SelfieUpload extends Equatable {
  final String id;
  final String imageUrl;

  /// Score (0..1) face match với CCCD đã upload trước. < 0.85 → mismatch.
  final double faceMatchScore;
  final bool isValid;
  final DateTime uploadedAt;
  final String? localPath;

  const SelfieUpload({
    required this.id,
    required this.imageUrl,
    required this.faceMatchScore,
    required this.isValid,
    required this.uploadedAt,
    this.localPath,
  });

  factory SelfieUpload.fromJson(Map<String, dynamic> json) => SelfieUpload(
        id: json['id'] as String,
        imageUrl:
            json['imageUrl'] as String? ?? json['image_url'] as String? ?? '',
        faceMatchScore:
            (json['faceMatchScore'] ?? json['face_match_score'] as num?)
                    ?.toDouble() ??
                0,
        isValid: (json['isValid'] ?? json['is_valid'] ?? true) as bool,
        uploadedAt: DateTime.parse(
          (json['uploadedAt'] ?? json['uploaded_at']) as String,
        ),
        localPath: json['localPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'faceMatchScore': faceMatchScore,
        'isValid': isValid,
        'uploadedAt': uploadedAt.toIso8601String(),
        'localPath': localPath,
      };

  @override
  List<Object?> get props =>
      [id, imageUrl, faceMatchScore, isValid, uploadedAt, localPath];
}
