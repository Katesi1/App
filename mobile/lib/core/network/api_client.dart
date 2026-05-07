import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static late final Dio _dio;
  static bool _initialized = false;

  /// Broadcast event khi token refresh fail → app phải đẩy user về login.
  ///
  /// Subscriber: `AuthNotifier` (xem `auth_controller.dart`). Khi nhận:
  /// 1. SecureStorage đã được clear bởi interceptor
  /// 2. AuthNotifier reset state → router tự redirect `/login`
  /// 3. Login screen show snackbar "Phiên đăng nhập đã hết hạn"
  static final StreamController<void> _forceLogoutController =
      StreamController<void>.broadcast();

  static Stream<void> get onForceLogout => _forceLogoutController.stream;

  static Dio get instance {
    if (!_initialized) _init();
    return _dio;
  }

  static void _init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(_AuthInterceptor(_dio));
    _initialized = true;
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  static const Set<String> _publicAuthPaths = {
    ApiConstants.login,
    ApiConstants.register,
    ApiConstants.googleLogin,
    ApiConstants.forgotPassword,
    ApiConstants.resetPassword,
    ApiConstants.refresh,
  };

  // Hàng chờ: các request nhận 401 trong khi đang refresh sẽ đợi ở đây
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
      _queue = [];

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_publicAuthPaths.contains(options.path)) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Public auth endpoints không cần refresh luồng 401.
    if (_publicAuthPaths.contains(err.requestOptions.path)) {
      handler.next(err);
      return;
    }
    final shouldRetry = _shouldRetry(err);
    final retries = (err.requestOptions.extra['retry_count'] as int?) ?? 0;
    if (shouldRetry && retries < 2) {
      final waitMs = _retryDelayMs(err, retries);
      await Future<void>.delayed(Duration(milliseconds: waitMs));
      final retryOptions = err.requestOptions
        ..extra['retry_count'] = retries + 1;
      try {
        final response = await _dio.fetch(retryOptions);
        handler.resolve(response);
        return;
      } catch (_) {}
    }

    // Chỉ xử lý 401 (Unauthorized)
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Nếu đang refresh → đưa request vào hàng chờ, không retry ngay
    if (_isRefreshing) {
      _queue.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        await _failAll(err);
        handler.next(err);
        return;
      }

      final response = await _dio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      final newAccessToken = response.data['data']['accessToken'];
      final newRefreshToken = response.data['data']['refreshToken'];

      await SecureStorage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await SecureStorage.saveRefreshToken(newRefreshToken);
      }

      // Retry request gốc với token mới
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(err.requestOptions);
      handler.resolve(retryResponse);

      // Replay tất cả request đang chờ trong hàng
      await _replayQueue(newAccessToken, err);
    } catch (_) {
      // Refresh thất bại → xoá token + broadcast force-logout cho AuthNotifier
      // (state reset → router redirect /login + snackbar).
      await SecureStorage.clear();
      ApiClient._forceLogoutController.add(null);
      await _failAll(err);
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Replay tất cả request trong hàng chờ với token mới
  Future<void> _replayQueue(String newToken, DioException originalErr) async {
    final pending = List.of(_queue);
    _queue.clear();
    for (final item in pending) {
      item.options.headers['Authorization'] = 'Bearer $newToken';
      try {
        final r = await _dio.fetch(item.options);
        item.handler.resolve(r);
      } catch (e) {
        item.handler.next(originalErr);
      }
    }
  }

  /// Fail tất cả request đang chờ (refresh thất bại)
  Future<void> _failAll(DioException err) async {
    final pending = List.of(_queue);
    _queue.clear();
    for (final item in pending) {
      item.handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.response?.statusCode == 429) {
      return true;
    }
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.receiveTimeout;
  }

  int _retryDelayMs(DioException err, int retries) {
    final retryAfter = err.response?.headers.value('retry-after');
    final parsedSeconds = int.tryParse(retryAfter ?? '');
    if (parsedSeconds != null && parsedSeconds > 0) {
      return parsedSeconds * 1000;
    }
    final jitter = Random().nextInt(400);
    return ((pow(2, retries).toInt()) * 600) + jitter;
  }
}
