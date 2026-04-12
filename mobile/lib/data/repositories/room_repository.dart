import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/room_model.dart';

class RoomRepository {
  final _dio = ApiClient.instance;

  /// Lấy phòng scoped theo owner (dùng cho quản lý)
  Future<ApiResponse<List<RoomModel>>> getRooms({
    String? homestayId,
    bool includeInactive = true,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.properties,
        queryParameters: {
          if (homestayId != null) 'propertyId': homestayId,
          if (includeInactive) 'includeInactive': true,
        },
      );
      final list = (response.data['data'] as List)
          .map((e) => RoomModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Lấy TẤT CẢ phòng active (dùng cho danh sách phòng — mọi role đều thấy)
  Future<ApiResponse<List<RoomModel>>> getAllPublicRooms() async {
    try {
      final response = await _dio.get(ApiConstants.propertiesPublic);
      final list = (response.data['data'] as List)
          .map((e) => RoomModel.fromJson(e))
          .where((r) => r.isActive)
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<RoomModel>> getRoomDetail(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.properties}/$id');
      return ApiResponse(
        success: true,
        data: RoomModel.fromJson(response.data['data']),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<RoomModel>> createRoom(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.properties, data: data);
      return ApiResponse(
        success: true,
        data: RoomModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<RoomModel>> updateRoom(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.patch('${ApiConstants.properties}/$id', data: data);
      return ApiResponse(
        success: true,
        data: RoomModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> deleteRoom(String id) async {
    try {
      await _dio.delete('${ApiConstants.properties}/$id');
      return ApiResponse(success: true, message: 'Xoá phòng thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<List<RoomImageModel>>> uploadImages(
      String roomId, List<String> filePaths) async {
    try {
      final formData = FormData();
      for (final path in filePaths) {
        final fileName = path.split('/').last;
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(
            path,
            filename: fileName,
          ),
        ));
      }
      final response = await _dio.post(
        ApiConstants.propertyImages(roomId),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final list = (response.data['data'] as List)
          .map((e) => RoomImageModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> deleteImage(String roomId, String imageId) async {
    try {
      await _dio.delete('${ApiConstants.properties}/$roomId/images/$imageId');
      return ApiResponse(success: true, message: 'Xoá ảnh thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> setCoverImage(String roomId, String imageId) async {
    try {
      await _dio.patch('${ApiConstants.properties}/$roomId/images/$imageId/cover');
      return ApiResponse(success: true, message: 'Đặt ảnh cover thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> upsertPrice(
      String roomId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put('${ApiConstants.properties}/$roomId/prices', data: data);
      return ApiResponse(
        success: true,
        data: response.data['data'],
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
