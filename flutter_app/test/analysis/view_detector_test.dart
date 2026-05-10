import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/view_detector.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('view detector returns front view for wide shoulder and hip positions',
      () {
    const frame = PoseFrame(
      landmarks: {
        Joint.leftShoulder: FrameLandmark(x: 120, y: 100, confidence: 0.99),
        Joint.rightShoulder: FrameLandmark(x: 182, y: 102, confidence: 0.98),
        Joint.leftHip: FrameLandmark(x: 130, y: 220, confidence: 0.99),
        Joint.rightHip: FrameLandmark(x: 188, y: 224, confidence: 0.97),
      },
    );

    final result = const ViewDetector().detect(frame);

    expect(result.view, ExerciseView.front);
    expect(result.confidence, greaterThan(0.7));
  });

  test('view detector returns front view for scaled down front positions', () {
    const frame = PoseFrame(
      landmarks: {
        Joint.leftShoulder: FrameLandmark(x: 120, y: 100, confidence: 0.99),
        Joint.rightShoulder: FrameLandmark(x: 156, y: 102, confidence: 0.98),
        Joint.leftHip: FrameLandmark(x: 124, y: 220, confidence: 0.99),
        Joint.rightHip: FrameLandmark(x: 158, y: 224, confidence: 0.97),
      },
    );

    final result = const ViewDetector().detect(frame);

    expect(result.view, ExerciseView.front);
    expect(result.confidence, greaterThan(0.7));
  });

  test('view detector returns side view for narrow shoulder and hip positions',
      () {
    const frame = PoseFrame(
      landmarks: {
        Joint.leftShoulder: FrameLandmark(x: 120, y: 100, confidence: 0.99),
        Joint.rightShoulder: FrameLandmark(x: 132, y: 102, confidence: 0.98),
        Joint.leftHip: FrameLandmark(x: 123, y: 220, confidence: 0.99),
        Joint.rightHip: FrameLandmark(x: 134, y: 224, confidence: 0.97),
      },
    );

    final result = const ViewDetector().detect(frame);

    expect(result.view, ExerciseView.side);
    expect(result.confidence, greaterThan(0.7));
  });

  test('view detector returns unknown for transition between front and side',
      () {
    const frame = PoseFrame(
      landmarks: {
        Joint.leftShoulder: FrameLandmark(x: 120, y: 100, confidence: 0.99),
        Joint.rightShoulder: FrameLandmark(x: 146, y: 102, confidence: 0.98),
        Joint.leftHip: FrameLandmark(x: 124, y: 220, confidence: 0.99),
        Joint.rightHip: FrameLandmark(x: 151, y: 224, confidence: 0.97),
      },
    );

    final result = const ViewDetector().detect(frame);

    expect(result.view, ExerciseView.unknown);
    expect(result.confidence, lessThan(0.7));
  });
}
