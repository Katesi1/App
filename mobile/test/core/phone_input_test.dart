import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/phone_input.dart';

void main() {
  // ---------------------------------------------------------------------------
  // PhoneInput.validate
  // ---------------------------------------------------------------------------
  group('PhoneInput.validate', () {
    test('null value → "Vui lòng nhập số điện thoại"', () {
      expect(
        PhoneInput.validate(null),
        'Vui lòng nhập số điện thoại',
      );
    });

    test('empty string → "Vui lòng nhập số điện thoại"', () {
      expect(
        PhoneInput.validate(''),
        'Vui lòng nhập số điện thoại',
      );
    });

    test('whitespace-only string → "Vui lòng nhập số điện thoại"', () {
      expect(
        PhoneInput.validate('   '),
        'Vui lòng nhập số điện thoại',
      );
    });

    test('9 digits → "Số điện thoại phải có đúng 10 chữ số"', () {
      expect(
        PhoneInput.validate('123456789'),
        'Số điện thoại phải có đúng 10 chữ số',
      );
    });

    test('11 digits → "Số điện thoại phải có đúng 10 chữ số"', () {
      expect(
        PhoneInput.validate('12345678901'),
        'Số điện thoại phải có đúng 10 chữ số',
      );
    });

    test(
        '10 digits not starting with 0 → '
        '"Số điện thoại phải bắt đầu bằng 0"', () {
      expect(
        PhoneInput.validate('1234567890'),
        'Số điện thoại phải bắt đầu bằng 0',
      );
    });

    test('valid "0123456789" → null', () {
      expect(PhoneInput.validate('0123456789'), isNull);
    });

    test('valid "0987654321" → null', () {
      expect(PhoneInput.validate('0987654321'), isNull);
    });

    test('value with leading/trailing spaces is trimmed before validation', () {
      expect(PhoneInput.validate(' 0123456789 '), isNull);
    });

    test(
        '"0123abc890" (non-digit chars, 10 chars total) → '
        'length check passes but regex fails → error', () {
      // After trim the string is 10 chars, starts with '0', but contains
      // non-digit chars so the regex r'^0\d{9}$' will not match.
      final result = PhoneInput.validate('0123abc890');
      expect(result, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // PhoneInput.validateOptional
  // ---------------------------------------------------------------------------
  group('PhoneInput.validateOptional', () {
    test('null → null (field optional, no error)', () {
      expect(PhoneInput.validateOptional(null), isNull);
    });

    test('empty string → null (field optional, no error)', () {
      expect(PhoneInput.validateOptional(''), isNull);
    });

    test('whitespace-only → null (treated as empty)', () {
      expect(PhoneInput.validateOptional('   '), isNull);
    });

    test('valid number → null', () {
      expect(PhoneInput.validateOptional('0123456789'), isNull);
    });

    test('9 digits → error (delegates to validate)', () {
      expect(
        PhoneInput.validateOptional('123456789'),
        isNotNull,
      );
    });

    test('10 digits not starting with 0 → error', () {
      expect(
        PhoneInput.validateOptional('9123456789'),
        isNotNull,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // PhoneInput.isValid
  // ---------------------------------------------------------------------------
  group('PhoneInput.isValid', () {
    test('"0123456789" → true', () {
      expect(PhoneInput.isValid('0123456789'), isTrue);
    });

    test('"0987654321" → true', () {
      expect(PhoneInput.isValid('0987654321'), isTrue);
    });

    test('"9123456789" (no leading zero) → false', () {
      expect(PhoneInput.isValid('9123456789'), isFalse);
    });

    test('null → false', () {
      expect(PhoneInput.isValid(null), isFalse);
    });

    test('empty string → false', () {
      expect(PhoneInput.isValid(''), isFalse);
    });

    test('9-digit number → false', () {
      expect(PhoneInput.isValid('012345678'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // PhoneInput.formatters
  // ---------------------------------------------------------------------------
  group('PhoneInput.formatters', () {
    test('returns a list of exactly 3 formatters', () {
      expect(PhoneInput.formatters, hasLength(3));
    });

    test('first formatter is FilteringTextInputFormatter (digits only)', () {
      expect(
        PhoneInput.formatters.first,
        isA<FilteringTextInputFormatter>(),
      );
    });

    test('second formatter is LengthLimitingTextInputFormatter', () {
      expect(
        PhoneInput.formatters[1],
        isA<LengthLimitingTextInputFormatter>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // _LeadingZeroFormatter (tested via PhoneInput.formatters[2])
  // ---------------------------------------------------------------------------
  group('_LeadingZeroFormatter (via formatters[2])', () {
    late TextInputFormatter formatter;

    setUp(() {
      formatter = PhoneInput.formatters[2];
    });

    test('empty new value is allowed through unchanged', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(text: '');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });

    test('first character "0" is allowed', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(
        text: '0',
        selection: TextSelection.collapsed(offset: 1),
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '0');
    });

    test('first character "5" is rejected, returns old value', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(
        text: '5',
        selection: TextSelection.collapsed(offset: 1),
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      // Should reject and return oldValue (empty)
      expect(result.text, '');
    });

    test('first character "9" is rejected, returns old value', () {
      const oldValue = TextEditingValue(text: '');
      const newValue = TextEditingValue(
        text: '9',
        selection: TextSelection.collapsed(offset: 1),
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });

    test('continuing digits after leading "0" are accepted', () {
      const oldValue = TextEditingValue(
        text: '01',
        selection: TextSelection.collapsed(offset: 2),
      );
      const newValue = TextEditingValue(
        text: '012',
        selection: TextSelection.collapsed(offset: 3),
      );
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '012');
    });
  });
}
