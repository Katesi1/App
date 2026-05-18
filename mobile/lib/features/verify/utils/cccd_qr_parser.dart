import '../data/models/ocr_result.dart';

/// Parser for the back QR code of the new chipped CCCD (Ministry of Public
/// Security).
///
/// Standard format — fields separated by `|`:
/// ```
/// <cccdId>|<cmndCu>|<hoTen>|<dob>|<gioiTinh>|<queQuan>|<diaChi>|<ngayCap>
/// ```
///
/// Some issuers return 7 fields (queQuan + diaChi merged into address). The
/// parser handles both layouts.
///
/// Field details:
/// - `cccdId`: 12 digits (new ID)
/// - `cmndCu`: 9 digits (old CMND — may be empty if the user has none)
/// - `hoTen`: full name (with diacritics, uppercase)
/// - `dob`: date of birth in `ddMMyyyy` (converted to `dd/MM/yyyy`)
/// - `gioiTinh`: "Nam" | "Nữ"
/// - `queQuan`: hometown (ward/district/province)
/// - `diaChi`: permanent address (house number, street, ward/district/province)
/// - `ngayCap`: issue date in `ddMMyyyy`
class VietnamCccdQrParser {
  VietnamCccdQrParser._();

  /// Parse the raw QR string. Returns `null` if the format is wrong (not a
  /// VN CCCD QR, or missing required fields).
  static OCRResult? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split('|');
    // Layout 8 fields: id|cmnd|name|dob|gender|hometown|address|issueDate
    // Layout 7 fields: id|cmnd|name|dob|gender|address|issueDate
    if (parts.length < 7) return null;

    final cccdId = parts[0].trim();
    // ID must be 12 digits (new chipped CCCD). Otherwise this isn't a CCCD QR
    // → ignore.
    if (!RegExp(r'^\d{12}$').hasMatch(cccdId)) return null;

    final cmndOld = parts[1].trim();
    final fullName = parts[2].trim();
    final dobRaw = parts[3].trim();
    final gender = parts[4].trim();

    String? hometown;
    String? address;
    String issueDateRaw;

    if (parts.length >= 8) {
      hometown = parts[5].trim();
      address = parts[6].trim();
      issueDateRaw = parts[7].trim();
    } else {
      // 7 fields — no separate hometown field
      address = parts[5].trim();
      issueDateRaw = parts[6].trim();
    }

    return OCRResult(
      cccdNumber: cccdId,
      oldCmndNumber: cmndOld.isEmpty ? null : cmndOld,
      fullName: fullName.isEmpty ? null : fullName,
      dob: _formatDate(dobRaw),
      gender: gender.isEmpty ? null : gender,
      hometown: hometown == null || hometown.isEmpty ? null : hometown,
      address: address.isEmpty ? null : address,
      issueDate: _formatDate(issueDateRaw),
    );
  }

  /// `ddMMyyyy` (8 digits) or `dd/MM/yyyy` → `dd/MM/yyyy`.
  /// Leaves the value unchanged for other formats or empty input.
  static String? _formatDate(String raw) {
    if (raw.isEmpty) return null;
    if (raw.contains('/')) return raw;
    if (raw.length == 8 && RegExp(r'^\d{8}$').hasMatch(raw)) {
      return '${raw.substring(0, 2)}/${raw.substring(2, 4)}/${raw.substring(4)}';
    }
    return raw;
  }
}
