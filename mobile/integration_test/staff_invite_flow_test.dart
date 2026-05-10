import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mobile/features/staff/views/invite_accept_screen.dart';

/// Smoke tests cho flow Staff invite accept.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Invite accept screen', () {
    testWidgets('renders short-code input when no initial token',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: InviteAcceptScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nhập mã mời từ chủ homestay'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
    });

    testWidgets('shows error when submitting empty short code',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: InviteAcceptScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập mã mời'), findsOneWidget);
    });
  });
}
