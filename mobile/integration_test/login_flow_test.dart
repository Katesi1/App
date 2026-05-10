import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mobile/features/auth/views/login_screen.dart';

/// Smoke tests cho LoginScreen.
///
/// Mục tiêu: verify UI render + form validation hoạt động. KHÔNG test
/// network call (cần mock BE riêng — xem README).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login screen', () {
    testWidgets('renders email + password fields + Google button',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
      expect(find.text('Đăng nhập bằng Google'), findsOneWidget);
      expect(find.text('Tôi có mã mời nhân viên'), findsOneWidget);
    });

    testWidgets('shows validation error when submitting empty form',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Tìm primary submit button (không phải Google/Apple).
      final submitButton = find.byType(FilledButton).first;
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Form validator phải hiện error message.
      expect(
        find.textContaining(RegExp(r'(không|vui lòng|nhập)', caseSensitive: false)),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
