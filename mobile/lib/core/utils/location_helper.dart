import 'package:geolocator/geolocator.dart';

/// Kết quả lấy vị trí GPS — sealed để UI xử lý exhaustive.
sealed class LocationResult {
  const LocationResult();
}

/// Lấy được toạ độ thành công.
final class LocationSuccess extends LocationResult {
  const LocationSuccess(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Link Google Maps chuẩn — mở được cả app Google Maps lẫn trình duyệt.
  String get mapsLink =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}

/// Lấy vị trí thất bại — kèm thông báo thân thiện cho user.
final class LocationFailure extends LocationResult {
  const LocationFailure(this.message);

  final String message;
}

/// Tiện ích định vị: xin quyền + lấy toạ độ GPS hiện tại của điện thoại.
class LocationHelper {
  const LocationHelper._();

  /// Kiểm tra dịch vụ định vị, xin quyền nếu cần, rồi trả về vị trí hiện tại.
  static Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationFailure(
          'Dịch vụ định vị đang tắt. Vui lòng bật GPS rồi thử lại.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationFailure('Bạn đã từ chối quyền truy cập vị trí.');
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationFailure(
          'Quyền vị trí bị chặn. Vui lòng bật lại trong Cài đặt ứng dụng.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationSuccess(position.latitude, position.longitude);
    } on Exception {
      return const LocationFailure('Không lấy được vị trí. Vui lòng thử lại.');
    }
  }
}
