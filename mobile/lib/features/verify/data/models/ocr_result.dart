import 'package:equatable/equatable.dart';

/// Kết quả OCR từ ảnh CCCD.
///
/// Backend (FPT.AI / VNPT eKYC) trả về JSON snake_case → parse trong [fromJson].
class OCRResult extends Equatable {
  final String? cccdNumber;
  final String? fullName;
  final String? dob;
  final String? address;
  final String? gender;
  final String? expiryDate;

  const OCRResult({
    this.cccdNumber,
    this.fullName,
    this.dob,
    this.address,
    this.gender,
    this.expiryDate,
  });

  factory OCRResult.fromJson(Map<String, dynamic> json) => OCRResult(
        cccdNumber: json['cccd_number'] as String? ?? json['cccdNumber'] as String?,
        fullName: json['full_name'] as String? ?? json['fullName'] as String?,
        dob: json['dob'] as String?,
        address: json['address'] as String?,
        gender: json['gender'] as String?,
        expiryDate:
            json['expiry_date'] as String? ?? json['expiryDate'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'cccd_number': cccdNumber,
        'full_name': fullName,
        'dob': dob,
        'address': address,
        'gender': gender,
        'expiry_date': expiryDate,
      };

  @override
  List<Object?> get props =>
      [cccdNumber, fullName, dob, address, gender, expiryDate];
}
