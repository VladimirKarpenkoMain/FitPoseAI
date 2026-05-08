import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/view_detector.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('view detector returns side view for staggered shoulder and hip x positions', () {
    final frame = PoseFrame(
      landmarks: {
        Joint.leftShoulder: const FrameLandmark(x: 120, y: 100, confidence: 0.99),
        Joint.rightShoulder: const FrameLandmark(x: 182, y: 102, confidence: 0.98),
        Joint.leftHip: const FrameLandmark(x: 130, y: 220, confidence: 0.99),
        Joint.rightHip: const FrameLandmark(x: 188, y: 224, confidence: 0.97),
      },
    );

    final result = ViewDetector().detect(frame);

    expect(result.view, ExerciseView.side);
    expect(result.confidence, greaterThan(0.7));
  });
}
