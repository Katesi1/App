import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kViewModeKey = 'view_mode';

/// Chế độ xem app: quản lý (ADMIN/STAFF) hoặc khách hàng
enum ViewMode { management, customer }

/// Pre-initialized SharedPreferences — overridden in main() trước runApp
/// để ViewModeNotifier đọc synchronously, tránh redirect flash khi cold start.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(prefs.getString(_kViewModeKey) == 'customer'
            ? ViewMode.customer
            : ViewMode.management);

  final SharedPreferences _prefs;

  Future<void> toggle() async {
    final next =
        state == ViewMode.management ? ViewMode.customer : ViewMode.management;
    state = next;
    await _prefs.setString(
      _kViewModeKey,
      next == ViewMode.customer ? 'customer' : 'management',
    );
  }

  Future<void> setMode(ViewMode mode) async {
    state = mode;
    await _prefs.setString(
      _kViewModeKey,
      mode == ViewMode.customer ? 'customer' : 'management',
    );
  }
}

final viewModeProvider = StateNotifierProvider<ViewModeNotifier, ViewMode>(
  (ref) => ViewModeNotifier(ref.watch(sharedPreferencesProvider)),
);
