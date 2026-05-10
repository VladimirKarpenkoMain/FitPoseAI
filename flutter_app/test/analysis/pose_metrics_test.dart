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
  });
}
