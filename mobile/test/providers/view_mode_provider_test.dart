import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/shared/providers/view_mode_provider.dart';

void main() {
  // SharedPreferences cần binding
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock SharedPreferences trống
    SharedPreferences.setMockInitialValues({});
  });

  group('ViewMode enum', () {
    test('has management and customer values', () {
      expect(ViewMode.values.length, 2);
      expect(ViewMode.values, contains(ViewMode.management));
      expect(ViewMode.values, contains(ViewMode.customer));
    });
  });

  group('ViewModeNotifier', () {
    test('initial state is management', () {
      final notifier = ViewModeNotifier();
      expect(notifier.state, ViewMode.management);
    });

    test('toggle switches between modes', () async {
      final notifier = ViewModeNotifier();

      // management → customer
      await notifier.toggle();
      expect(notifier.state, ViewMode.customer);

      // customer → management
      await notifier.toggle();
      expect(notifier.state, ViewMode.management);
    });

    test('setMode sets exact mode', () async {
      final notifier = ViewModeNotifier();

      await notifier.setMode(ViewMode.customer);
      expect(notifier.state, ViewMode.customer);

      await notifier.setMode(ViewMode.management);
      expect(notifier.state, ViewMode.management);
    });

    test('persists to SharedPreferences', () async {
      final notifier = ViewModeNotifier();

      await notifier.setMode(ViewMode.customer);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('view_mode'), 'customer');
    });

    test('loads persisted value', () async {
      SharedPreferences.setMockInitialValues({'view_mode': 'customer'});

      final notifier = ViewModeNotifier();
      // Đợi _load() async hoàn tất
      await Future.delayed(Duration.zero);

      expect(notifier.state, ViewMode.customer);
    });

    test('loads management when no persisted value', () async {
      SharedPreferences.setMockInitialValues({});

      final notifier = ViewModeNotifier();
      await Future.delayed(Duration.zero);

      expect(notifier.state, ViewMode.management);
    });
  });
}
