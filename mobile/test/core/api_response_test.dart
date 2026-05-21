import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/network/api_response.dart';

class _MockDioException extends Mock implements DioException {}

class _MockResponse extends Mock implements Response<dynamic> {}

/// Tạo DioException với type và response tuỳ ý.
DioException _makeException({
  required DioExceptionType type,
  Response<dynamic>? response,
  String? message,
}) {
  final e = _MockDioException();
  when(() => e.type).thenReturn(type);
  when(() => e.response).thenReturn(response);
  when(() => e.message).thenReturn(message);
  return e;
}

Response<dynamic> _makeResponse({dynamic data, int? statusCode}) {
  final r = _MockResponse();
  when(() => r.data).thenReturn(data);
  when(() => r.statusCode).thenReturn(statusCode);
  return r;
}

void main() {
  group('ApiResponse', () {
    test('success carries data and success flag', () {
      final response = ApiResponse<String>(
        success: true,
        data: 'hello',
        message: 'OK',
      );

      expect(response.success, true);
      expect(response.data, 'hello');
      expect(response.message, 'OK');
    });

    test('error has null data and success is false', () {
      final response = ApiResponse<String>(
        success: false,
        message: 'Something went wrong',
      );

      expect(response.success, false);
      expect(response.data, isNull);
      expect(response.message, 'Something went wrong');
    });

    test('success with null data is still valid', () {
      final response = ApiResponse<String>(
        success: true,
        message: 'No content',
      );

      expect(response.success, true);
      expect(response.data, isNull);
    });
  });

  group('parseDioError — server message', () {
    test('returns message from server response body', () {
      final response = _makeResponse(
        data: {'message': 'Email không hợp lệ'},
      );
      final e = _makeException(
        type: DioExceptionType.badResponse,
        response: response,
      );

      expect(parseDioError(e), 'Email không hợp lệ');
    });

    test('returns only first part when message contains comma', () {
      final response = _makeResponse(
        data: {
          'message':
              'Email không được để trống, Email không hợp lệ, Mật khẩu tối thiểu 6 ký tự',
        },
      );
      final e = _makeException(
        type: DioExceptionType.badResponse,
        response: response,
      );

      expect(parseDioError(e), 'Email không được để trống');
    });
  });

  group('parseDioError — no server response', () {
    test('returns connection timeout message', () {
      final e = _makeException(type: DioExceptionType.connectionTimeout);

      expect(
        parseDioError(e),
        'Kết nối quá thời gian, vui lòng thử lại',
      );
    });

    test('returns receive timeout message', () {
      final e = _makeException(type: DioExceptionType.receiveTimeout);

      expect(
        parseDioError(e),
        'Kết nối quá thời gian, vui lòng thử lại',
      );
    });

    test('returns send timeout message', () {
      final e = _makeException(type: DioExceptionType.sendTimeout);

      expect(
        parseDioError(e),
        'Kết nối quá thời gian, vui lòng thử lại',
      );
    });

    test('returns connectionError message when response is null', () {
      final e = _makeException(type: DioExceptionType.connectionError);

      expect(parseDioError(e), 'Không kết nối được server');
    });

    test('returns badResponse fallback when response data has no message', () {
      final response = _makeResponse(data: <String, dynamic>{}, statusCode: 500);
      final e = _makeException(
        type: DioExceptionType.badResponse,
        response: response,
      );

      expect(parseDioError(e), contains('Lỗi máy chủ'));
    });

    test('returns badResponse with status code in fallback', () {
      final response = _makeResponse(data: <String, dynamic>{}, statusCode: 403);
      final e = _makeException(
        type: DioExceptionType.badResponse,
        response: response,
      );

      expect(parseDioError(e), contains('403'));
    });

    test('returns unknown error with message when type is unknown', () {
      final e = _makeException(
        type: DioExceptionType.unknown,
        message: 'Connection reset by peer',
      );

      expect(parseDioError(e), contains('Connection reset by peer'));
    });

    test('returns generic unknown message when type is unknown and message is empty', () {
      final e = _makeException(
        type: DioExceptionType.unknown,
        message: '',
      );

      expect(parseDioError(e), 'Lỗi không xác định từ hệ thống mạng');
    });

    test('returns generic unknown message when type is unknown and message is null', () {
      final e = _makeException(
        type: DioExceptionType.unknown,
        message: null,
      );

      expect(parseDioError(e), 'Lỗi không xác định từ hệ thống mạng');
    });

    test('returns cancel message when request was cancelled', () {
      final e = _makeException(type: DioExceptionType.cancel);

      expect(parseDioError(e), 'Yêu cầu đã bị huỷ');
    });

    test('returns SSL message on badCertificate', () {
      final e = _makeException(type: DioExceptionType.badCertificate);

      expect(parseDioError(e), contains('SSL'));
    });
  });
}
