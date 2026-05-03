import 'package:equatable/equatable.dart';

/// Kết quả OCR/QR từ ảnh CCCD.
///
/// Frontend tự extract trên device (ML Kit OCR cho mặt trước, ML Kit barcode
/// cho QR mặt sau) → gửi lên backend kèm ảnh trong multipart body. Backend
/// chỉ lưu vào DB + Cloudinary, KHÔNG gọi FPT.AI hay OCR engine khác.
class OCRResult extends Equatable {
  // ── Common (cả mặt trước + QR mặt sau đều có) ──
  final String? cccdNumber; // 12 chữ số (CCCD chip mới)
  final String? fullName; // Họ và tên
  final String? dob; // Ngày sinh dd/MM/yyyy
  final String? gender; // "Nam" | "Nữ"

  // ── Mặt trước ──
  final String? address; // Nơi thường trú (multi-line)
  final String? expiryDate; // Có giá trị đến dd/MM/yyyy

  // ── Mặt sau (QR-only) ──
  final String? oldCmndNumber; // 9 chữ số (CMND cũ, có thể null)
  final String? hometown; // Quê quán
  final String? issueDate; // Ngày cấp dd/MM/yyyy

  const OCRResult({
    this.cccdNumber,
    this.fullName,
    this.dob,
    this.address,
    this.gender,
    this.expiryDate,
    this.oldCmndNumber,
    this.hometown,
    this.issueDate,
  });

  factory OCRResult.fromJson(Map<String, dynamic> json) => OCRResult(
        cccdNumber:
            json['cccdNumber'] as String? ?? json['cccd_number'] as String?,
        fullName: json['fullName'] as String? ?? json['full_name'] as String?,
        dob: json['dob'] as String?,
        address: json['address'] as String?,
        gender: json['gender'] as String?,
        expiryDate:
            json['expiryDate'] as String? ?? json['expiry_date'] as String?,
        oldCmndNumber: json['oldCmndNumber'] as String? ??
            json['old_cmnd_number'] as String?,
        hometown: json['hometown'] as String?,
        issueDate:
            json['issueDate'] as String? ?? json['issue_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (cccdNumber != null) 'cccdNumber': cccdNumber,
        if (fullName != null) 'fullName': fullName,
        if (dob != null) 'dob': dob,
        if (address != null) 'address': address,
        if (gender != null) 'gender': gender,
        if (expiryDate != null) 'expiryDate': expiryDate,
        if (oldCmndNumber != null) 'oldCmndNumber': oldCmndNumber,
        if (hometown != null) 'hometown': hometown,
        if (issueDate != null) 'issueDate': issueDate,
      };

  /// Merge front OCR + QR back. QR back ưu tiên cao hơn cho field chung
  /// (cccdNumber, fullName, dob, gender) vì QR machine-readable, chính xác
  /// hơn OCR text.
  OCRResult mergeWith(OCRResult? other) {
    if (other == null) return this;
    return OCRResult(
      cccdNumber: other.cccdNumber ?? cccdNumber,
      fullName: other.fullName ?? fullName,
      dob: other.dob ?? dob,
      gender: other.gender ?? gender,
      address: address ?? other.address,
      expiryDate: expiryDate ?? other.expiryDate,
      oldCmndNumber: other.oldCmndNumber ?? oldCmndNumber,
      hometown: other.hometown ?? hometown,
      issueDate: other.issueDate ?? issueDate,
    );
  }

  bool get isEmpty =>
      cccdNumber == null &&
      fullName == null &&
      dob == null &&
      address == null &&
      gender == null &&
      expiryDate == null &&
      oldCmndNumber == null &&
      hometown == null &&
      issueDate == null;

  @override
  List<Object?> get props => [
        cccdNumber,
        fullName,
        dob,
        address,
        gender,
        expiryDate,
        oldCmndNumber,
        hometown,
        issueDate,
      ];
}
