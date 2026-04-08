import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/room_model.dart';

class RoomRepository {
  final _dio = ApiClient.instance;

  Future<ApiResponse<List<RoomModel>>> getRooms({String? homestayId}) async {
    try {
      final response = await _dio.get(
        ApiConstants.rooms,
        // API mới dùng propertyId, fallback tên cũ homestayId
        queryParameters:
            homestayId != null ? {'propertyId': homestayId} : null,
      );
      final list = (response.data['data'] as List)
          .map((e) => RoomModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<RoomModel>> getRoomDetail(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.rooms}/$id');
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
      final response = await _dio.post(ApiConstants.rooms, data: data);
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
      final response = await _dio.put('${ApiConstants.rooms}/$id', data: data);
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
      await _dio.delete('${ApiConstants.rooms}/$id');
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
        formData.files.add(MapEntry(
          'images',
          await MultipartFile.fromFile(path),
        ));
      }
      final response = await _dio.post(
        '${ApiConstants.rooms}/$roomId/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
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
      await _dio.delete('${ApiConstants.rooms}/$roomId/images/$imageId');
      return ApiResponse(success: true, message: 'Xoá ảnh thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> setCoverImage(String roomId, String imageId) async {
    try {
      await _dio.patch('${ApiConstants.rooms}/$roomId/images/$imageId/cover');
      return ApiResponse(success: true, message: 'Đặt ảnh cover thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> upsertPrice(
      String roomId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put('${ApiConstants.rooms}/$roomId/prices', data: data);
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
