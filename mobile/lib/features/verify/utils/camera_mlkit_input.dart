import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

const Map<DeviceOrientation, int> _orientationDegrees = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

/// Chuyển [CameraImage] từ stream → [InputImage] cho ML Kit (face/OCR/barcode).
///
/// Selfie scanner trước đây concat mọi plane → ML Kit không detect được mặt.
/// Dùng plane đầu (NV21/BGRA) hoặc convert YUV_420_888 → NV21 khi cần.
InputImage? cameraImageToMlKitInput(
  CameraController controller,
  CameraImage image,
) {
  final cam = controller.description;

  InputImageRotation? rotation;
  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(cam.sensorOrientation);
  } else {
    final deviceRotation =
        _orientationDegrees[controller.value.deviceOrientation] ?? 0;
    final rot = cam.lensDirection == CameraLensDirection.front
        ? (cam.sensorOrientation + deviceRotation) % 360
        : (cam.sensorOrientation - deviceRotation + 360) % 360;
    rotation = InputImageRotationValue.fromRawValue(rot);
  }
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null || image.planes.isEmpty) return null;

  if (Platform.isIOS) {
    if (format != InputImageFormat.bgra8888) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // Android — ưu tiên NV21 single plane (camera 0.11+ camerax).
  Uint8List? bytes;
  InputImageFormat? mlFormat;

  if (format == InputImageFormat.nv21 && image.planes.length == 1) {
    bytes = image.planes.first.bytes;
    mlFormat = InputImageFormat.nv21;
  } else if (image.planes.length >= 3) {
    bytes = _yuv420ToNv21(image);
    mlFormat = InputImageFormat.nv21;
  } else if (image.planes.length == 1) {
    bytes = image.planes.first.bytes;
    mlFormat = format == InputImageFormat.nv21
        ? InputImageFormat.nv21
        : InputImageFormat.yuv420;
  }

  if (bytes == null || mlFormat == null) return null;

  return InputImage.fromBytes(
    bytes: bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: mlFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    ),
  );
}

/// YUV_420_888 (3 plane) → NV21 — workaround khi camera bỏ qua `ImageFormatGroup.nv21`.
Uint8List? _yuv420ToNv21(CameraImage image) {
  if (image.planes.length < 3) return null;

  final yBuffer = image.planes[0].bytes;
  final uBuffer = image.planes[1].bytes;
  final vBuffer = image.planes[2].bytes;
  if (yBuffer.isEmpty) return null;

  final nv21 = Uint8List(yBuffer.length + uBuffer.length + vBuffer.length);
  nv21.setRange(0, yBuffer.length, yBuffer);

  var i = 0;
  while (i < uBuffer.length && i < vBuffer.length) {
    final base = yBuffer.length + i;
    if (base + 1 >= nv21.length) break;
    nv21[base] = vBuffer[i];
    nv21[base + 1] = uBuffer[i];
    i += 2;
  }
  return nv21;
}
