import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mobile/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/views/role_picker_screen.dart';

/// Smoke tests cho RolePickerScreen — happy path render + 2 cards visible.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Role picker screen', () {
    testWidgets('shows greeting + customer + owner cards', (tester) async {
      const args = RolePickerArgs(
        idToken: 'fake-id-token',
        profile: GoogleProfile(
          email: 'test@example.com',
          name: 'Nguyen Test',
          sub: 'fake-sub',
        ),
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RolePickerScreen(args: args),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Nguyen Test'), findsOneWidget);
      expect(find.text('Tôi là khách đặt phòng'), findsOneWidget);
      expect(find.text('Tôi là chủ homestay'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });
}
