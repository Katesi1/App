import '../data/models/ocr_result.dart';

/// Parser best-effort cho text ML Kit OCR đọc từ mặt trước CCCD chip mới.
///
/// CCCD VN có template song ngữ (Việt + English) nên parser dùng regex theo
/// keyword cố định. Khác QR (machine-readable, chính xác 100%), OCR text có
/// thể sai 1-2 ký tự — kết quả này là **best-effort** để pre-fill, admin sẽ
/// duyệt lại trong queue.
///
/// CCCD chip mới layout:
/// ```
/// CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM
/// CĂN CƯỚC CÔNG DÂN / CITIZEN IDENTITY CARD
/// Số / No.: 012345678901
/// Họ và tên / Full name: NGUYỄN VĂN A
/// Ngày sinh / Date of birth: 01/01/1990
/// Giới tính / Sex: Nam
/// Quốc tịch / Nationality: Việt Nam
/// Quê quán / Place of origin: ...
/// Nơi thường trú / Place of residence: ...
/// Có giá trị đến / Date of expiry: 01/01/2030
/// ```
class CccdFrontOcrParser {
  CccdFrontOcrParser._();

  /// Parse raw text. Trả `OCRResult` với các field nullable — field nào
  /// không match được sẽ là `null`.
  static OCRResult parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final fullText = lines.join('\n');

    return OCRResult(
      cccdNumber: _extractCccdNumber(fullText),
      fullName: _extractFullName(lines),
      dob: _extractDate(
        fullText,
        keywords: ['Ngày sinh', 'Date of birth'],
      ),
      gender: _extractGender(fullText),
      address: _extractAddress(lines),
      expiryDate: _extractDate(
        fullText,
        keywords: ['Có giá trị đến', 'Date of expiry'],
      ),
    );
  }

  // ── Field extractors ──────────────────────────────────────────────────────

  /// 12 chữ số liên tiếp — đặc trưng CCCD chip mới. Tránh nhầm với DOB
  /// (8 số có dấu /), số phone (10 số bắt đầu 0).
  static String? _extractCccdNumber(String text) {
    final match = RegExp(r'\b(\d{12})\b').firstMatch(text);
    return match?.group(1);
  }

  /// Họ tên = dòng sau "Họ và tên" hoặc "Full name". Tên CCCD luôn UPPERCASE.
  static String? _extractFullName(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('họ và tên') || lower.contains('full name')) {
        // Có thể "Họ và tên: NGUYỄN VĂN A" hoặc "Họ và tên\nNGUYỄN VĂN A"
        final inline = _afterColon(line);
        if (inline != null && _looksLikeName(inline)) return inline;
        if (i + 1 < lines.length && _looksLikeName(lines[i + 1])) {
          return lines[i + 1];
        }
      }
    }
    // Fallback — tìm dòng UPPERCASE thuần (không có chữ thường, không số)
    for (final line in lines) {
      if (_looksLikeName(line) && line.length >= 5) return line;
    }
    return null;
  }

  /// Tên CCCD: toàn UPPERCASE, có khoảng trắng giữa các từ, không số.
  static bool _looksLikeName(String s) {
    if (s.isEmpty) return false;
    if (s.contains(RegExp(r'\d'))) return false;
    if (s.contains(':')) return false;
    final letters = s.replaceAll(' ', '');
    if (letters.isEmpty) return false;
    return letters == letters.toUpperCase() &&
        letters.toUpperCase() != letters.toLowerCase();
  }

  /// Date dd/MM/yyyy sau keyword. Match mọi định dạng phổ biến (có hoặc
  /// không có "/" giữa các phần).
  static String? _extractDate(String text, {required List<String> keywords}) {
    for (final kw in keywords) {
      final pattern = RegExp(
        '${RegExp.escape(kw)}[^0-9]*(\\d{1,2}[/-]\\d{1,2}[/-]\\d{2,4})',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(text);
      if (match != null) return _normalizeDate(match.group(1)!);
    }
    return null;
  }

  /// Convert `1-1-2020` → `01/01/2020`, `1/1/20` → `01/01/2020`.
  static String _normalizeDate(String raw) {
    final parts = raw.split(RegExp(r'[/-]'));
    if (parts.length != 3) return raw;
    final d = parts[0].padLeft(2, '0');
    final m = parts[1].padLeft(2, '0');
    var y = parts[2];
    if (y.length == 2) y = '20$y'; // best-effort
    return '$d/$m/$y';
  }

  /// "Nam" hoặc "Nữ" sau "Giới tính" / "Sex".
  static String? _extractGender(String text) {
    final pattern = RegExp(
      r'(?:Giới tính|Sex)[^A-Za-zÀ-ỹ]*(Nam|Nữ|Male|Female)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    if (match == null) return null;
    final g = match.group(1)!.toLowerCase();
    if (g == 'nam' || g == 'male') return 'Nam';
    if (g == 'nữ' || g == 'female') return 'Nữ';
    return null;
  }

  /// Nơi thường trú — multi-line, kéo dài cho tới dòng có "Có giá trị đến"
  /// hoặc "Date of expiry" hoặc hết dòng. Best-effort.
  static String? _extractAddress(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      final isMarker = lower.contains('nơi thường trú') ||
          lower.contains('place of residence');
      if (!isMarker) continue;

      final buffer = <String>[];
      // Inline portion sau dấu ":"
      final inline = _afterColon(lines[i]);
      if (inline != null && inline.isNotEmpty) buffer.add(inline);

      for (var j = i + 1; j < lines.length; j++) {
        final next = lines[j].toLowerCase();
        if (next.contains('có giá trị đến') ||
            next.contains('date of expiry')) {
          break;
        }
        // Bỏ dòng UPPERCASE thuần (có thể là tiêu đề khác)
        if (lines[j].trim().isEmpty) continue;
        buffer.add(lines[j].trim());
        // Address tối đa 3 dòng — dừng để tránh nuốt thêm
        if (buffer.length >= 3) break;
      }
      if (buffer.isEmpty) return null;
      return buffer.join(', ');
    }
    return null;
  }

  /// Trả phần sau dấu `:` (trim). `null` nếu không có hoặc rỗng.
  static String? _afterColon(String line) {
    final idx = line.indexOf(':');
    if (idx < 0 || idx == line.length - 1) return null;
    final after = line.substring(idx + 1).trim();
    return after.isEmpty ? null : after;
  }
}
