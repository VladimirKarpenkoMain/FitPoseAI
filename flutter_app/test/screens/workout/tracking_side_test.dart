import 'package:fitness_ai/screens/workout/pose_detector_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preferRightTrackingSide hysteresis', () {
    test('with no previous side picks the larger score', () {
      expect(
        preferRightTrackingSide(
            leftScore: 10, rightScore: 20, previousRight: null),
        isTrue,
      );
      expect(
        preferRightTrackingSide(
            leftScore: 20, rightScore: 10, previousRight: null),
        isFalse,
      );
    });

    test('keeps the current side when scores are nearly equal (no flicker)', () {
      // Currently tracking the left side; right is only marginally larger.
      expect(
        preferRightTrackingSide(
            leftScore: 100, rightScore: 105, previousRight: false),
        isFalse,
      );
      // Currently tracking the right side; left is only marginally larger.
      expect(
        preferRightTrackingSide(
            leftScore: 105, rightScore: 100, previousRight: true),
        isTrue,
      );
    });

    test('switches side only when the other side is clearly larger', () {
      expect(
        preferRightTrackingSide(
            leftScore: 100, rightScore: 140, previousRight: false),
        isTrue,
      );
      expect(
        preferRightTrackingSide(
            leftScore: 140, rightScore: 100, previousRight: true),
        isFalse,
      );
    });
  });
}
