import 'package:flutter/services.dart';

/// Vietnamese phone: 10 digits, starts with `0`.
///
/// Shared formatter + validator for all phone inputs (booking, profile,
/// register, forgot password, admin form...).
class PhoneInput {
  PhoneInput._();

  /// Max length for the phone input field.
  static const int maxLength = 10;

  /// Valid regex — exactly 10 digits, first char is `0`.
  static final RegExp _validRegex = RegExp(r'^0\d{9}$');

  /// Formatters for `TextField.inputFormatters`:
  /// - Digits only
  /// - First char must be `0` (rejects any other char as leading digit)
  /// - Max 10 chars total
  static List<TextInputFormatter> get formatters => <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
        _LeadingZeroFormatter(),
      ];

  /// Validator for `TextFormField.validator` or manual checks.
  /// Returns `null` if valid; returns a Vietnamese message if invalid.
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

  /// Like [validate] but allows empty (e.g. optional fields).
  static String? validateOptional(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    return validate(v);
  }

  /// Quick `isValid` check — use when a message isn't needed.
  static bool isValid(String? value) => validate(value) == null;
}

/// Ensures the first char (if any) is `0`. If the user types another digit
/// as the first char → reject the edit and keep the old value.
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
