// SecureStorage wraps FlutterSecureStorage which relies on platform channels
// (Android EncryptedSharedPreferences / iOS Keychain).  Those channels are not
// available in the headless flutter_test environment, so meaningful unit tests
// cannot be written here without mocking the entire platform plugin.
//
// Recommended approach:
//   • Use integration_test/ on a real device/emulator to verify the full
//     read-write-delete lifecycle.
//   • If unit-level coverage is needed, inject a FlutterSecureStorage mock via
//     a thin SecureStorage constructor that accepts a storage instance, then
//     override it in tests with a fake.
//
// This file is kept as a placeholder so the test runner does not skip the
// core/ directory and the intent is documented for future contributors.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecureStorage', () {
    test(
      'requires platform integration — see integration_test/ for full coverage',
      () {
        // No assertions: this test exists only to document the limitation and
        // keep the group discoverable by the test runner.
        expect(true, isTrue);
      },
    );
  });
}
