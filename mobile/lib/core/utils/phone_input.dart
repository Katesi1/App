import 'package:flutter/services.dart';

/// Số điện thoại Việt Nam: 10 chữ số, bắt đầu bằng `0`.
///
/// Dùng làm bộ formatter + validator chung cho mọi input nhập SĐT
/// (booking, profile, register, forgot password, admin form...).
class PhoneInput {
  PhoneInput._();

  /// Số ký tự tối đa cho input field SĐT.
  static const int maxLength = 10;

  /// Regex hợp lệ — đúng 10 chữ số, ký tự đầu là `0`.
  static final RegExp _validRegex = RegExp(r'^0\d{9}$');

  /// Bộ formatter dùng cho `TextField.inputFormatters`:
  /// - Chỉ cho nhập digit
  /// - Ký tự đầu phải là `0` (chặn ngay khi user gõ ký tự khác làm digit đầu)
  /// - Tổng tối đa 10 ký tự
  static List<TextInputFormatter> get formatters => <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
        _LeadingZeroFormatter(),
      ];

  /// Validator dùng cho `TextFormField.validator` hoặc check thủ công.
  /// Trả `null` nếu hợp lệ; trả message tiếng Việt nếu sai.
  static String? validate(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (v.length != maxLength) return 'Số điện thoại phải có đúng 10 chữ số';
    if (!v.startsWith('0')) return 'Số điện thoại phải bắt đầu bằng 0';
    if (!_validRegex.hasMatch(v)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  /// Tương tự [validate] nhưng cho phép rỗng (vd field optional).
  static String? validateOptional(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    return validate(v);
  }

  /// Check nhanh `isValid` — dùng khi không cần message.
  static bool isValid(String? value) => validate(value) == null;
}

/// Đảm bảo ký tự đầu tiên (nếu có) phải là `0`. Nếu user gõ digit khác làm
/// ký tự đầu → từ chối edit và giữ giá trị cũ.
class _LeadingZeroFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!text.startsWith('0')) return oldValue;
    return newValue;
  }
}
