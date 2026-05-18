import '../data/models/ocr_result.dart';

/// Best-effort parser for ML Kit OCR text from the front of a new chipped CCCD.
///
/// VN CCCDs use a bilingual template (Vietnamese + English), so the parser
/// uses regex matched against fixed keywords. Unlike the back QR (machine-
/// readable, 100% accurate), OCR text may be off by 1-2 characters — this
/// result is **best-effort** to pre-fill, admin still reviews in the queue.
///
/// New chipped CCCD layout:
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

  /// Parse raw text. Returns `OCRResult` with nullable fields — anything that
  /// fails to match stays `null`.
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

  /// 12 consecutive digits — signature of the new chipped CCCD. Avoid
  /// collisions with DOB (8 digits with /) or phone (10 digits starting with 0).
  static String? _extractCccdNumber(String text) {
    final match = RegExp(r'\b(\d{12})\b').firstMatch(text);
    return match?.group(1);
  }

  /// Full name = line after "Họ và tên" or "Full name". CCCD names are
  /// always UPPERCASE.
  static String? _extractFullName(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('họ và tên') || lower.contains('full name')) {
        // Could be "Họ và tên: NGUYỄN VĂN A" or "Họ và tên\nNGUYỄN VĂN A"
        final inline = _afterColon(line);
        if (inline != null && _looksLikeName(inline)) return inline;
        if (i + 1 < lines.length && _looksLikeName(lines[i + 1])) {
          return lines[i + 1];
        }
      }
    }
    // Fallback — find a pure-UPPERCASE line (no lowercase, no digits).
    for (final line in lines) {
      if (_looksLikeName(line) && line.length >= 5) return line;
    }
    return null;
  }

  /// CCCD name: all UPPERCASE, spaces between words, no digits.
  static bool _looksLikeName(String s) {
    if (s.isEmpty) return false;
    if (s.contains(RegExp(r'\d'))) return false;
    if (s.contains(':')) return false;
    final letters = s.replaceAll(' ', '');
    if (letters.isEmpty) return false;
    return letters == letters.toUpperCase() &&
        letters.toUpperCase() != letters.toLowerCase();
  }

  /// Date dd/MM/yyyy after the keyword. Matches common formats (with or
  /// without "/" between segments).
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

  /// "Nam" or "Nữ" after "Giới tính" / "Sex".
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

  /// Permanent address — multi-line, runs until we hit "Có giá trị đến"
  /// or "Date of expiry" or end of lines. Best-effort.
  static String? _extractAddress(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      final isMarker = lower.contains('nơi thường trú') ||
          lower.contains('place of residence');
      if (!isMarker) continue;

      final buffer = <String>[];
      // Inline portion after ":"
      final inline = _afterColon(lines[i]);
      if (inline != null && inline.isNotEmpty) buffer.add(inline);

      for (var j = i + 1; j < lines.length; j++) {
        final next = lines[j].toLowerCase();
        if (next.contains('có giá trị đến') ||
            next.contains('date of expiry')) {
          break;
        }
        // Skip blank lines (could be another header).
        if (lines[j].trim().isEmpty) continue;
        buffer.add(lines[j].trim());
        // Address is at most 3 lines — stop to avoid swallowing more.
        if (buffer.length >= 3) break;
      }
      if (buffer.isEmpty) return null;
      return buffer.join(', ');
    }
    return null;
  }

  /// Return the portion after `:` (trimmed). `null` if missing or empty.
  static String? _afterColon(String line) {
    final idx = line.indexOf(':');
    if (idx < 0 || idx == line.length - 1) return null;
    final after = line.substring(idx + 1).trim();
    return after.isEmpty ? null : after;
  }
}
