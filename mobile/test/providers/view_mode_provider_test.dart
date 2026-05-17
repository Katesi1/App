import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/shared/providers/view_mode_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ViewMode enum', () {
    test('has management and customer values', () {
      expect(ViewMode.values.length, 2);
      expect(ViewMode.values, contains(ViewMode.management));
      expect(ViewMode.values, contains(ViewMode.customer));
    });
  });

  group('ViewModeNotifier', () {
    test('initial state is management when no persisted value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ViewModeNotifier(prefs);
      expect(notifier.state, ViewMode.management);
    });

    test('loads customer when persisted value is customer', () async {
      SharedPreferences.setMockInitialValues({'view_mode': 'customer'});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ViewModeNotifier(prefs);
      expect(notifier.state, ViewMode.customer);
    });

    test('loads management when no persisted value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ViewModeNotifier(prefs);
      expect(notifier.state, ViewMode.management);
    });

    test('toggle switches between modes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ViewModeNotifier(prefs);

      await notifier.toggle();
      expect(notifier.state, ViewMode.customer);

      await notifier.toggle();
      expect(notifier.state, ViewMode.management);
    });

    test('setMode sets exact mode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ViewModeNotifier(prefs);

      await notifier.setMode(ViewMode.customer);
      expect(notifier.state, ViewMode.customer);

      await notifier.setMode(ViewMode.management);
      expect(notifier.state, ViewMode.management);
    });

    test('persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = ViewModeNotifier(prefs);

      await notifier.setMode(ViewMode.customer);
      expect(prefs.getString('view_mode'), 'customer');
    });
  });
}
