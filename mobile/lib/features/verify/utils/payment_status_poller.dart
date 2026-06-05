import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tiered polling cho bank-transfer manual reconcile (session TTL tới 24h).
///
/// - 0–5 phút: mỗi 5s (user vừa chuyển khoản)
/// - 5–30 phút: mỗi 15s
/// - 30 phút – hết hạn: mỗi 60s
/// - Khi `now > expiresAt`: dừng poll
class PaymentStatusPoller {
  PaymentStatusPoller({
    required this.expiresAt,
    required this.onPoll,
    this.onExpired,
  });

  final DateTime expiresAt;
  final Future<void> Function() onPoll;
  final VoidCallback? onExpired;

  Timer? _timer;
  DateTime? _startedAt;
  bool _running = false;
  bool _paused = false;

  bool get isRunning => _running;

  void start() {
    stop();
    _running = true;
    _paused = false;
    _startedAt = DateTime.now();
    unawaited(_tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _paused = false;
  }

  /// Dừng poll khi app vào background — chờ FCM + resume check.
  void pause() {
    if (!_running) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Tiếp tục poll khi app foreground lại.
  void resume() {
    if (!_running || !_paused) return;
    _paused = false;
    unawaited(_tick());
  }

  /// Poll ngay (resume / FCM foreground).
  Future<void> checkNow() async {
    if (!_running || _paused) return;
    await _tick();
  }

  Future<void> _tick() async {
    if (!_running || _paused) return;
    if (_isExpired) {
      _handleExpired();
      return;
    }

    try {
      await onPoll();
    } catch (_) {
      // silent retry — schedule tiếp
    }

    if (!_running || _paused) return;
    if (_isExpired) {
      _handleExpired();
      return;
    }

    _timer?.cancel();
    _timer = Timer(_nextInterval(), () => unawaited(_tick()));
  }

  bool get _isExpired => !DateTime.now().isBefore(expiresAt);

  void _handleExpired() {
    stop();
    onExpired?.call();
  }

  Duration _nextInterval() {
    final elapsed = DateTime.now().difference(_startedAt ?? DateTime.now());
    return intervalForElapsed(elapsed);
  }

  /// 0–5 phút: 5s · 5–30 phút: 15s · sau 30 phút: 60s
  static Duration intervalForElapsed(Duration elapsed) {
    if (elapsed < const Duration(minutes: 5)) {
      return const Duration(seconds: 5);
    }
    if (elapsed < const Duration(minutes: 30)) {
      return const Duration(seconds: 15);
    }
    return const Duration(seconds: 60);
  }
}
