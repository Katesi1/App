import 'package:equatable/equatable.dart';

/// OCR/QR result from a CCCD image.
///
/// Frontend extracts on-device (ML Kit OCR for the front, ML Kit barcode for
/// the back QR) → sends to backend along with the image in a multipart body.
/// Backend just stores it to DB + Cloudinary; does NOT call FPT.AI or any
/// other OCR engine.
class OCRResult extends Equatable {
  // Common fields (present on both front and back QR)
  final String? cccdNumber; // 12 digits (new chipped CCCD)
  final String? fullName; // Full name
  final String? dob; // Date of birth dd/MM/yyyy
  final String? gender; // "Nam" | "Nữ"

  // Front-only
  final String? address; // Permanent address (multi-line)
  final String? expiryDate; // Valid until dd/MM/yyyy

  // Back-only (QR-only)
  final String? oldCmndNumber; // 9 digits (old CMND, may be null)
  final String? hometown; // Hometown
  final String? issueDate; // Issue date dd/MM/yyyy

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

  /// Merge front OCR + back QR. Back QR takes priority for shared fields
  /// (cccdNumber, fullName, dob, gender) because it's machine-readable and
  /// more accurate than OCR text.
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
