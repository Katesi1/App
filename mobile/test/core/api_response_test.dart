import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobile/core/network/api_failure.dart';
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
      final response =
          _makeResponse(data: <String, dynamic>{}, statusCode: 500);
      final e = _makeException(
        type: DioExceptionType.badResponse,
        response: response,
      );

      expect(parseDioError(e), contains('Lỗi máy chủ'));
    });

    test('returns badResponse with status code in fallback', () {
      final response =
          _makeResponse(data: <String, dynamic>{}, statusCode: 403);
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

    test(
        'returns generic unknown message when type is unknown and message is empty',
        () {
      final e = _makeException(
        type: DioExceptionType.unknown,
        message: '',
      );

      expect(parseDioError(e), 'Lỗi không xác định từ hệ thống mạng');
    });

    test(
        'returns generic unknown message when type is unknown and message is null',
        () {
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

  group('ApiResponse.fromDioError — trích code + statusCode (v1.12)', () {
    test('lấy code + statusCode từ body 403, giữ message', () {
      final response = _makeResponse(
        data: {
          'code': 'subscription.featureLocked',
          'message': 'Tài khoản chưa có quyền dùng tính năng này.',
        },
        statusCode: 403,
      );
      final e = _makeException(
        type: DioExceptionType.badResponse,
        response: response,
      );

      final res = ApiResponse.fromDioError(e);
      expect(res.success, isFalse);
      expect(res.code, 'subscription.featureLocked');
      expect(res.statusCode, 403);
      expect(res.message, 'Tài khoản chưa có quyền dùng tính năng này.');
    });

    test('giữ hành vi comma-split message khi nhiều lỗi', () {
      final response = _makeResponse(
        data: {'message': 'Lỗi A, Lỗi B', 'code': 'x.y'},
        statusCode: 400,
      );
      final e = _makeException(
        type: DioExceptionType.badResponse,
        response: response,
      );

      expect(ApiResponse.fromDioError(e).message, 'Lỗi A');
    });

    test('code null khi body không có code', () {
      final response = _makeResponse(
        data: {'message': 'Lỗi'},
        statusCode: 403,
      );
      final e = _makeException(
        type: DioExceptionType.badResponse,
        response: response,
      );

      expect(ApiResponse.fromDioError(e).code, isNull);
    });
  });

  group('ApiResponseErrorX', () {
    ApiResponse<void> err({String? code, int? statusCode}) => ApiResponse<void>(
          success: false,
          message: 'x',
          code: code,
          statusCode: statusCode,
        );

    test('isFeatureLocked khi code khớp', () {
      expect(err(code: ApiErrorCodes.featureLocked).isFeatureLocked, isTrue);
    });

    test('isFeatureLocked fallback khi codeless 403', () {
      expect(err(statusCode: 403).isFeatureLocked, isTrue);
    });

    test('không featureLocked khi codeless 400', () {
      expect(err(statusCode: 400).isFeatureLocked, isFalse);
    });

    test('isKycRequired khi code khớp', () {
      expect(
        err(code: ApiErrorCodes.kycPropertyRequiresKyc).isKycRequired,
        isTrue,
      );
    });
  });

  group('ApiFailure', () {
    test('toString trả message thuần (giữ UX cũ)', () {
      expect(const ApiFailure('Lỗi rồi').toString(), 'Lỗi rồi');
    });

    test('isFeatureLocked / isKycRequired theo code', () {
      const locked = ApiFailure('x', code: ApiErrorCodes.featureLocked);
      expect(locked.isFeatureLocked, isTrue);
      expect(locked.isKycRequired, isFalse);

      const kyc = ApiFailure('x', code: ApiErrorCodes.kycPropertyRequiresKyc);
      expect(kyc.isKycRequired, isTrue);

      const codeless403 = ApiFailure('x', statusCode: 403);
      expect(codeless403.isFeatureLocked, isTrue);
    });

    test('fromResponse copy code + statusCode', () {
      final f = ApiFailure.fromResponse(
        ApiResponse<void>(
          success: false,
          message: 'm',
          code: ApiErrorCodes.featureLocked,
          statusCode: 403,
        ),
      );
      expect(f.message, 'm');
      expect(f.code, ApiErrorCodes.featureLocked);
      expect(f.statusCode, 403);
    });
  });
}
