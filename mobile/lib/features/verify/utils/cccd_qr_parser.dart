import '../data/models/ocr_result.dart';

/// Parser cho QR code mặt sau CCCD chip mới (Bộ Công An).
///
/// Format chuẩn — các field phân cách bằng `|`:
/// ```
/// <cccdId>|<cmndCu>|<hoTen>|<dob>|<gioiTinh>|<queQuan>|<diaChi>|<ngayCap>
/// ```
///
/// Một số issuer trả 7 field (gộp queQuan + diaChi thành address). Parser
/// cover cả hai layout.
///
/// Field detail:
/// - `cccdId`: 12 chữ số (ID mới)
/// - `cmndCu`: 9 chữ số (CMND cũ — có thể empty nếu user không có)
/// - `hoTen`: full name (có dấu, viết hoa)
/// - `dob`: ngày sinh format `ddMMyyyy` (sẽ convert sang `dd/MM/yyyy`)
/// - `gioiTinh`: "Nam" | "Nữ"
/// - `queQuan`: quê quán (xã/huyện/tỉnh)
/// - `diaChi`: nơi thường trú (số nhà, đường, xã/huyện/tỉnh)
/// - `ngayCap`: ngày cấp format `ddMMyyyy`
class VietnamCccdQrParser {
  VietnamCccdQrParser._();

  /// Parse raw QR string. Trả `null` nếu format không đúng (không phải QR
  /// CCCD VN, hoặc thiếu field bắt buộc).
  static OCRResult? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split('|');
    // Layout 8 fields: id|cmnd|name|dob|gender|hometown|address|issueDate
    // Layout 7 fields: id|cmnd|name|dob|gender|address|issueDate
    if (parts.length < 7) return null;

    final cccdId = parts[0].trim();
    // ID phải là 12 chữ số (CCCD chip mới). Nếu không phải → không phải QR
    // CCCD → ignore.
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
      // 7 fields — không có hometown riêng
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

  /// `ddMMyyyy` (8 chữ số) hoặc `dd/MM/yyyy` → `dd/MM/yyyy`.
  /// Giữ nguyên nếu format khác hoặc empty.
  static String? _formatDate(String raw) {
    if (raw.isEmpty) return null;
    if (raw.contains('/')) return raw;
    if (raw.length == 8 && RegExp(r'^\d{8}$').hasMatch(raw)) {
      return '${raw.substring(0, 2)}/${raw.substring(2, 4)}/${raw.substring(4)}';
    }
    return raw;
  }
}
