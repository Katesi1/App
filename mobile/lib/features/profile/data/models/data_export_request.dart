import 'package:equatable/equatable.dart';

/// `POST/GET /users/me/data-export`
class DataExportRequest extends Equatable {
  final String id;
  final String status;
  final String? downloadUrl;
  final String? fileName;
  final DateTime? requestedAt;
  final DateTime? completedAt;

  const DataExportRequest({
    required this.id,
    required this.status,
    this.downloadUrl,
    this.fileName,
    this.requestedAt,
    this.completedAt,
  });

  factory DataExportRequest.fromJson(Map<String, dynamic> json) {
    return DataExportRequest(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      status: (json['status'] ?? 'pending') as String,
      downloadUrl: (json['downloadUrl'] ?? json['download_url']) as String?,
      fileName: (json['fileName'] ?? json['file_name'] ?? json['filename'])
          as String?,
      requestedAt: _parseDate(json['requestedAt'] ?? json['requested_at']),
      completedAt: _parseDate(json['completedAt'] ?? json['completed_at']),
    );
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'processing':
        return 'Đang xử lý';
      case 'completed':
      case 'ready':
        return 'Đã hoàn tất';
      case 'failed':
        return 'Thất bại';
      default:
        return status;
    }
  }

  bool get isReady =>
      status.toLowerCase() == 'completed' || status.toLowerCase() == 'ready';

  String get displayFile =>
      fileName ?? downloadUrl?.split('/').last ?? 'personal_data.zip';

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  @override
  List<Object?> get props =>
      [id, status, downloadUrl, fileName, requestedAt, completedAt];
}
