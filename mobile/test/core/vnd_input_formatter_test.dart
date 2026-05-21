import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/vnd_input_formatter.dart';

// ---------------------------------------------------------------------------
// Helper — builds a new TextEditingValue as if the user typed [newText].
// ---------------------------------------------------------------------------
TextEditingValue _input(String newText) {
  return TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newText.length),
  );
}

TextEditingValue _old(String text) =>
    TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

void main() {
  late VndInputFormatter formatter;

  setUp(() {
    formatter = VndInputFormatter();
  });

  // ---------------------------------------------------------------------------
  // Empty / single-character inputs
  // ---------------------------------------------------------------------------
  group('VndInputFormatter — empty / short inputs', () {
    test('empty string → empty string', () {
      final result = formatter.formatEditUpdate(
        _old(''),
        _input(''),
      );
      expect(result.text, '');
    });

    test('"1" → "1" (no separator needed)', () {
      final result = formatter.formatEditUpdate(_old(''), _input('1'));
      expect(result.text, '1');
    });

    test('"12" → "12"', () {
      final result = formatter.formatEditUpdate(_old('1'), _input('12'));
      expect(result.text, '12');
    });

    test('"123" → "123"', () {
      final result = formatter.formatEditUpdate(_old('12'), _input('123'));
      expect(result.text, '123');
    });
  });

  // ---------------------------------------------------------------------------
  // Thousands-separator insertion
  // ---------------------------------------------------------------------------
  group('VndInputFormatter — thousands separators', () {
    test('"1000" → "1.000"', () {
      final result = formatter.formatEditUpdate(_old(''), _input('1000'));
      expect(result.text, '1.000');
    });

    test('"1234" → "1.234"', () {
      final result = formatter.formatEditUpdate(_old(''), _input('1234'));
      expect(result.text, '1.234');
    });

    test('"500" → "500" (below thousands threshold)', () {
      final result = formatter.formatEditUpdate(_old(''), _input('500'));
      expect(result.text, '500');
    });

    test('"1000000" → "1.000.000"', () {
      final result = formatter.formatEditUpdate(_old(''), _input('1000000'));
      expect(result.text, '1.000.000');
    });

    test('"1234567" → "1.234.567"', () {
      final result = formatter.formatEditUpdate(_old(''), _input('1234567'));
      expect(result.text, '1.234.567');
    });

    test('"100000" → "100.000"', () {
      final result = formatter.formatEditUpdate(_old(''), _input('100000'));
      expect(result.text, '100.000');
    });

    test('"10000000" → "10.000.000"', () {
      final result = formatter.formatEditUpdate(_old(''), _input('10000000'));
      expect(result.text, '10.000.000');
    });
  });

  // ---------------------------------------------------------------------------
  // Already-formatted input (dots present) is re-processed correctly
  // ---------------------------------------------------------------------------
  group('VndInputFormatter — re-processing pre-formatted text', () {
    test('"1.000" → "1.000" (dots stripped, digits re-formatted)', () {
      // Simulates pasting or incremental input where dots are present
      final result = formatter.formatEditUpdate(
        _old('100'),
        _input('1.000'),
      );
      expect(result.text, '1.000');
    });

    test('"1.234.567" re-processed → "1.234.567"', () {
      final result = formatter.formatEditUpdate(
        _old('1.234.56'),
        _input('1.234.567'),
      );
      expect(result.text, '1.234.567');
    });
  });

  // ---------------------------------------------------------------------------
  // Invalid (non-digit, non-dot) input → rejected, returns oldValue
  // ---------------------------------------------------------------------------
  group('VndInputFormatter — invalid characters rejected', () {
    test('letters in input → returns old value', () {
      const old = TextEditingValue(text: '1.000');
      final newVal = _input('1.000a');
      final result = formatter.formatEditUpdate(old, newVal);
      // After stripping dots from "1.000a" we get "1000a" which fails
      // the digits-only regex → formatter returns oldValue.
      expect(result.text, '1.000');
    });

    test('"abc" → returns old value (empty)', () {
      final result = formatter.formatEditUpdate(_old(''), _input('abc'));
      expect(result.text, '');
    });

    test('"12e4" → returns old value', () {
      final result = formatter.formatEditUpdate(_old('12'), _input('12e4'));
      expect(result.text, '12');
    });

    test('"1 000" (space) → returns old value', () {
      final result = formatter.formatEditUpdate(_old(''), _input('1 000'));
      expect(result.text, '');
    });
  });

  // ---------------------------------------------------------------------------
  // Cursor position — selection should be at end of formatted text
  // ---------------------------------------------------------------------------
  group('VndInputFormatter — cursor at end after format', () {
    test('"1000" selection collapses to end of "1.000" (offset 5)', () {
      final result = formatter.formatEditUpdate(_old(''), _input('1000'));
      expect(result.selection.baseOffset, 5); // "1.000".length == 5
      expect(result.selection.extentOffset, 5);
      expect(result.selection.isCollapsed, isTrue);
    });

    test('"1000000" selection collapses to end of "1.000.000" (offset 9)', () {
      final result = formatter.formatEditUpdate(_old(''), _input('1000000'));
      expect(result.selection.baseOffset, 9); // "1.000.000".length == 9
      expect(result.selection.isCollapsed, isTrue);
    });

    test('empty input selection is at offset 0', () {
      final result = formatter.formatEditUpdate(_old(''), _input(''));
      expect(result.selection.baseOffset, 0);
    });
  });
}
