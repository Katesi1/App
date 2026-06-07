import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:mobile/features/verify/utils/face_analysis_space.dart';

void main() {
  group('FaceAnalysisSpace', () {
    test('swaps dimensions when rotation is 90deg', () {
      final space = FaceAnalysisSpace.fromStream(
        rawWidth: 1920,
        rawHeight: 1080,
        rotation: InputImageRotation.rotation90deg,
        isFrontCamera: true,
      );
      expect(space.width, 1080);
      expect(space.height, 1920);
      expect(space.mirrorX, isTrue);
    });

    test('mirrors X for front camera centering', () {
      const space = FaceAnalysisSpace(
        width: 1080,
        height: 1920,
        mirrorX: true,
      );
      final center = space.centerInPreviewSpace(
        const Rect.fromLTWH(800, 400, 200, 260),
      );
      expect(center.dx, closeTo(180, 0.01));
      expect(center.dy, closeTo(530, 0.01));
    });

    test('keeps X for back camera', () {
      const space = FaceAnalysisSpace(
        width: 1080,
        height: 1920,
        mirrorX: false,
      );
      final center = space.centerInPreviewSpace(
        const Rect.fromLTWH(800, 400, 200, 260),
      );
      expect(center.dx, closeTo(900, 0.01));
    });
  });
}
