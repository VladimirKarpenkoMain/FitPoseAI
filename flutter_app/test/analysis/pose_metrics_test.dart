import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/pose_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PoseMetrics.normalizedOffsetFromLine', () {
    test('returns positive values when the point is below the reference line',
        () {
      final offset = PoseMetrics.normalizedOffsetFromLine(
        lineStart: const FrameLandmark(x: 0, y: 0, confidence: 1),
        point: const FrameLandmark(x: 50, y: 20, confidence: 1),
        lineEnd: const FrameLandmark(x: 100, y: 0, confidence: 1),
      );

      expect(offset, closeTo(0.2, 0.001));
    });

    test('returns negative values when the point is above the reference line',
        () {
      final offset = PoseMetrics.normalizedOffsetFromLine(
        lineStart: const FrameLandmark(x: 0, y: 0, confidence: 1),
        point: const FrameLandmark(x: 50, y: -20, confidence: 1),
        lineEnd: const FrameLandmark(x: 100, y: 0, confidence: 1),
      );

      expect(offset, closeTo(-0.2, 0.001));
    });

    test('measures true perpendicular offset for a vertical reference line', () {
      // Body line along the Y axis (portrait standing pose). The point sits 20px
      // to the side, i.e. a perpendicular offset of 0.2 of the line length.
      final offset = PoseMetrics.normalizedOffsetFromLine(
        lineStart: const FrameLandmark(x: 0, y: 0, confidence: 1),
        point: const FrameLandmark(x: 20, y: 50, confidence: 1),
        lineEnd: const FrameLandmark(x: 0, y: 100, confidence: 1),
      );

      expect(offset.abs(), closeTo(0.2, 0.001));
    });

    test('offset magnitude is invariant to body orientation', () {
      // The same geometry rotated 90 degrees must yield the same magnitude.
      final horizontal = PoseMetrics.normalizedOffsetFromLine(
        lineStart: const FrameLandmark(x: 0, y: 0, confidence: 1),
        point: const FrameLandmark(x: 50, y: 20, confidence: 1),
        lineEnd: const FrameLandmark(x: 100, y: 0, confidence: 1),
      );
      final rotated = PoseMetrics.normalizedOffsetFromLine(
        lineStart: const FrameLandmark(x: 0, y: 0, confidence: 1),
        point: const FrameLandmark(x: -20, y: 50, confidence: 1),
        lineEnd: const FrameLandmark(x: 0, y: 100, confidence: 1),
      );

      expect(rotated.abs(), closeTo(horizontal.abs(), 0.001));
    });
  });
}
