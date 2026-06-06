import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/widgets/app_toast.dart';

/// Wrap [ImagePicker] để xử lý permission denied một cách user-friendly.
///
/// Behavior:
/// - User denied lần đầu → image_picker tự retry next call (iOS sẽ pop dialog).
/// - User permanently denied (đã chọn "Don't Allow" / disable trong Settings):
///   image_picker throw `PlatformException(code: 'camera_access_denied'
///   | 'photo_access_denied')`. Wrapper bắt → show dialog "Vào cài đặt".
/// - User cancel picker (back/swipe) → returns `null` (không show dialog).
///
/// Cách dùng:
/// ```dart
/// final file = await CameraPicker.fromCamera(context);
/// if (file != null) await _upload(file);
/// ```
class CameraPicker {
  CameraPicker._();

  static final ImagePicker _picker = ImagePicker();

  /// Mở camera. Front-facing nếu [front] = true (cho selfie).
  static Future<XFile?> fromCamera(
    BuildContext context, {
    bool front = false,
    int imageQuality = 85,
    double maxWidth = 1920,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: front ? CameraDevice.front : CameraDevice.rear,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
    } on PlatformException catch (e) {
      if (!context.mounted) return null;
      if (e.code == 'camera_access_denied') {
        await _showPermissionDialog(
          context,
          title: 'Cần quyền truy cập camera',
          message:
              'Halong24h cần quyền camera để bạn chụp CCCD và selfie xác minh. '
              'Vui lòng vào Cài đặt → Halong24h → bật Camera.',
        );
      } else {
        _showError(context, 'Không mở được camera: ${e.message ?? e.code}');
      }
      return null;
    } catch (e) {
      if (context.mounted) _showError(context, 'Lỗi: $e');
      return null;
    }
  }

  /// Mở thư viện ảnh.
  static Future<XFile?> fromGallery(
    BuildContext context, {
    int imageQuality = 85,
    double maxWidth = 1920,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
    } on PlatformException catch (e) {
      if (!context.mounted) return null;
      if (e.code == 'photo_access_denied') {
        await _showPermissionDialog(
          context,
          title: 'Cần quyền truy cập thư viện ảnh',
          message:
              'Halong24h cần quyền truy cập thư viện ảnh để bạn chọn ảnh CCCD/selfie có sẵn. '
              'Vui lòng vào Cài đặt → Halong24h → bật Photos.',
        );
      } else {
        _showError(context, 'Không mở được thư viện: ${e.message ?? e.code}');
      }
      return null;
    } catch (e) {
      if (context.mounted) _showError(context, 'Lỗi: $e');
      return null;
    }
  }

  static Future<void> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final colors = context.colors;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgSurfaceElevated,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Để sau'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.settings, size: 16),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _openAppSettings();
            },
            label: const Text('Vào cài đặt'),
          ),
        ],
      ),
    );
  }

  /// Mở Settings app — iOS dùng `app-settings:`, Android dùng intent action
  /// vào ứng dụng thông qua `package:` URI.
  ///
  /// Note: iOS Apple cho phép deeplink `app-settings:` chỉ trỏ về Settings
  /// chính của app này, không bị reject store. Trên Android cần biết package
  /// id, ở đây dùng `app-settings:` fallback và để Android xử lý.
  static Future<void> _openAppSettings() async {
    final uri = Platform.isIOS
        ? Uri.parse('app-settings:')
        : Uri.parse('package:'); // Android tự resolve về app settings
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static void _showError(BuildContext context, String msg) {
    AppToast.error(context, msg);
  }
}
