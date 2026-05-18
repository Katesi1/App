import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static late final Dio _dio;
  static bool _initialized = false;

  /// Broadcast event when token refresh fails → app must push user to login.
  ///
  /// Subscriber: `AuthNotifier` (see `auth_controller.dart`). On receive:
  /// 1. SecureStorage has already been cleared by the interceptor
  /// 2. AuthNotifier resets state → router auto-redirects to `/login`
  /// 3. Login screen shows snackbar "Session expired"
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

  // Queue: requests that get 401 while a refresh is in flight wait here.
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
    // Public auth endpoints don't need the 401 refresh flow.
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

    // Only handle 401 (Unauthorized).
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // If a refresh is already in flight → queue the request, don't retry now.
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

      final responseData = response.data['data'];
      if (responseData is! Map) {
        throw StateError('Refresh response data không hợp lệ');
      }
      final newAccessToken = responseData['accessToken'] as String?;
      if (newAccessToken == null || newAccessToken.isEmpty) {
        throw StateError('accessToken trống trong refresh response');
      }
      final newRefreshToken = responseData['refreshToken'] as String?;

      await SecureStorage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await SecureStorage.saveRefreshToken(newRefreshToken);
      }

      // Retry original request with the new token.
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch(err.requestOptions);
      handler.resolve(retryResponse);

      // Replay all queued requests.
      await _replayQueue(newAccessToken, err);
    } catch (_) {
      // Refresh failed → clear token + broadcast force-logout to AuthNotifier
      // (state reset → router redirects to /login + snackbar).
      await SecureStorage.clear();
      ApiClient._forceLogoutController.add(null);
      await _failAll(err);
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Replay all queued requests with the new token.
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

  /// Fail all queued requests (refresh failed).
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
