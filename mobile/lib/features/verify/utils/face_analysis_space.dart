import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Map ML Kit face box → không gian preview (portrait + mirror front cam).
///
/// ML Kit trả tọa độ trong ảnh đã xoay theo [rotation]. Stream [CameraImage]
/// vẫn dùng width/height gốc (thường landscape). Preview front camera mirror
/// ngang — phải mirror X trước khi so với khung oval.
class FaceAnalysisSpace {
  const FaceAnalysisSpace({
    required this.width,
    required this.height,
    required this.mirrorX,
  });

  final double width;
  final double height;
  final bool mirrorX;

  factory FaceAnalysisSpace.fromStream({
    required int rawWidth,
    required int rawHeight,
    required InputImageRotation rotation,
    required bool isFrontCamera,
  }) {
    final swap = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    return FaceAnalysisSpace(
      width: (swap ? rawHeight : rawWidth).toDouble(),
      height: (swap ? rawWidth : rawHeight).toDouble(),
      mirrorX: isFrontCamera,
    );
  }

  /// Tâm mặt trong không gian người dùng nhìn (đã mirror nếu cần).
  Offset centerInPreviewSpace(Rect boundingBox) {
    var cx = boundingBox.center.dx;
    final cy = boundingBox.center.dy;
    if (mirrorX) {
      cx = width - cx;
    }
    return Offset(cx, cy);
  }

  /// Tỉ lệ kích thước mặt so với cạnh ngắn của frame upright.
  double faceSizeFraction(Rect boundingBox) {
    final faceSize = math.max(boundingBox.width, boundingBox.height);
    final frameMin = math.min(width, height);
    if (frameMin <= 0) return 0;
    return faceSize / frameMin;
  }
}
