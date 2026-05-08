import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/pose_tracking_stabilizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pose stabilizer keeps last frame during brief detection dropout', () {
    final stabilizer = PoseTrackingStabilizer(
      missingPoseTolerance: const Duration(milliseconds: 300),
    );
    final frame = PoseFrame(
      landmarks: const {
        Joint.leftShoulder: FrameLandmark(x: 0, y: 0, confidence: 1),
      },
    );

    final first = stabilizer.stabilize(
      frame: frame,
      elapsed: const Duration(milliseconds: 100),
    );
    final recovered = stabilizer.stabilize(
      frame: null,
      elapsed: const Duration(milliseconds: 320),
    );

    expect(first, same(frame));
    expect(recovered, same(frame));
  });

  test('pose stabilizer clears cached frame after tolerance expires', () {
    final stabilizer = PoseTrackingStabilizer(
      missingPoseTolerance: const Duration(milliseconds: 300),
    );
    final frame = PoseFrame(
      landmarks: const {
        Joint.leftShoulder: FrameLandmark(x: 0, y: 0, confidence: 1),
      },
    );

    stabilizer.stabilize(
      frame: frame,
      elapsed: const Duration(milliseconds: 100),
    );
    final expired = stabilizer.stabilize(
      frame: null,
      elapsed: const Duration(milliseconds: 450),
    );

    expect(expired, isNull);
  });
}
