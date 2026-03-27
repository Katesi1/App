import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kViewModeKey = 'view_mode';

/// Chế độ xem app: quản lý (ADMIN/STAFF) hoặc khách hàng
enum ViewMode { management, customer }

class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier() : super(ViewMode.management) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_kViewModeKey);
    if (value == 'customer') {
      state = ViewMode.customer;
    } else {
      state = ViewMode.management;
    }
  }

  Future<void> toggle() async {
    final next = state == ViewMode.management
        ? ViewMode.customer
        : ViewMode.management;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kViewModeKey,
      next == ViewMode.customer ? 'customer' : 'management',
    );
  }

  Future<void> setMode(ViewMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kViewModeKey,
      mode == ViewMode.customer ? 'customer' : 'management',
    );
  }
}

final viewModeProvider =
    StateNotifierProvider<ViewModeNotifier, ViewMode>(
  (ref) => ViewModeNotifier(),
);
