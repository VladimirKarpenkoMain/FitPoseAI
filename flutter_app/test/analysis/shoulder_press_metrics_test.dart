import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/shoulder_press_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'buildShoulderPressMetrics reaches lockout from the camera-facing side '
      'when the occluded far arm is unreliable', () {
    // Side view: the near (left) arm is fully pressed overhead, while the far
    // (right) arm is occluded and tracked with noisy, lowered landmarks.
    final landmarks = <Joint, FrameLandmark>{
      Joint.leftShoulder: const FrameLandmark(x: 0.50, y: 0.50, confidence: 0.9),
      Joint.leftElbow: const FrameLandmark(x: 0.50, y: 0.35, confidence: 0.9),
      Joint.leftWrist: const FrameLandmark(x: 0.50, y: 0.20, confidence: 0.9),
      Joint.leftHip: const FrameLandmark(x: 0.46, y: 0.80, confidence: 0.9),
      Joint.leftKnee: const FrameLandmark(x: 0.46, y: 1.10, confidence: 0.6),
      Joint.leftAnkle: const FrameLandmark(x: 0.46, y: 1.40, confidence: 0.6),
      Joint.rightShoulder:
          const FrameLandmark(x: 0.52, y: 0.52, confidence: 0.3),
      Joint.rightElbow: const FrameLandmark(x: 0.50, y: 0.55, confidence: 0.2),
      Joint.rightWrist: const FrameLandmark(x: 0.55, y: 0.55, confidence: 0.2),
      Joint.rightHip: const FrameLandmark(x: 0.52, y: 0.82, confidence: 0.3),
    };

    final metrics = buildShoulderPressMetrics(landmarks);

    expect(metrics['phase_shoulder_angle'], greaterThanOrEqualTo(150));
    expect(metrics['phase_elbow_angle'], greaterThanOrEqualTo(150));
    expect(metrics['phase_wrist_above_shoulder'], 1);
  });
}
