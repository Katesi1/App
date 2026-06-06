import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/trial_snapshot.dart';
import 'admin_trial_repository.dart';

class AdminTrialRepositoryImpl implements AdminTrialRepository {
  final Dio _dio;

  AdminTrialRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  @override
  Future<TrialSnapshot> fetchSubscription(String userId) async {
    try {
      final res = await _dio.get(ApiConstants.adminUserSubscription(userId));
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null)
        throw Exception('Không lấy được thông tin subscription');
      // Backend có thể trả user object lồng bên trong hoặc flat
      final merged = <String, dynamic>{...data};
      return TrialSnapshot.fromJson(merged);
    } on DioException catch (e) {
      throw Exception(parseDioError(e));
    }
  }

  @override
  Future<TrialActionResult> grantTrial({
    required String userId,
    required int days,
    String? planId,
    String? cycle,
    int? rooms,
    String? reason,
  }) async {
    try {
      final body = <String, dynamic>{'days': days};
      if (planId != null && planId.isNotEmpty) body['planId'] = planId;
      if (cycle != null && cycle.isNotEmpty) body['cycle'] = cycle;
      if (rooms != null) body['rooms'] = rooms;
      if (reason != null && reason.isNotEmpty) body['reason'] = reason;

      final res = await _dio.post(
        ApiConstants.adminUserTrial(userId),
        data: body,
      );
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Phản hồi không hợp lệ từ server');
      return TrialActionResult.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception(
          'Tài khoản đang có subscription active, không thể cấp trial.',
        );
      }
      throw Exception(parseDioError(e));
    }
  }

  @override
  Future<TrialActionResult> revokeTrial({
    required String userId,
    String? reason,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        queryParams['reason'] = reason;
      }
      final res = await _dio.delete(
        ApiConstants.adminUserTrial(userId),
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Phản hồi không hợp lệ từ server');
      return TrialActionResult.fromJson(data);
    } on DioException catch (e) {
      throw Exception(parseDioError(e));
    }
  }
}
