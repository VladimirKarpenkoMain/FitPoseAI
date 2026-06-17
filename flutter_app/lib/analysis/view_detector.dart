import '../models/workout_analysis.dart';
import 'pose_frame.dart';
import 'pose_metrics.dart';

class ViewDetectionResult {
  final ExerciseView view;
  final double confidence;

  const ViewDetectionResult(this.view, this.confidence);
}

class ViewDetector {
  static const double _sideWidthRatio = 0.18;
  static const double _frontWidthRatio = 0.28;

  const ViewDetector();

  ViewDetectionResult detect(PoseFrame frame) {
    final leftShoulder = frame[Joint.leftShoulder];
    final rightShoulder = frame[Joint.rightShoulder];
    final leftHip = frame[Joint.leftHip];
    final rightHip = frame[Joint.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return const ViewDetectionResult(ExerciseView.unknown, 0);
    }

    // Use full 2D distances so the ratio is independent of body orientation in
    // the frame. A side view always has the left/right joints close together
    // relative to the torso length, whether the person is standing (vertical
    // torso) or in a push-up/plank (horizontal torso, landscape).
    final shoulderWidth = PoseMetrics.distance(leftShoulder, rightShoulder);
    final hipWidth = PoseMetrics.distance(leftHip, rightHip);
    final averageWidth = (shoulderWidth + hipWidth) / 2;
    final leftTorsoLength = PoseMetrics.distance(leftShoulder, leftHip);
    final rightTorsoLength = PoseMetrics.distance(rightShoulder, rightHip);
    final averageTorsoLength = (leftTorsoLength + rightTorsoLength) / 2;

    if (averageTorsoLength <= 0) {
      return const ViewDetectionResult(ExerciseView.unknown, 0);
    }

    final widthRatio = averageWidth / averageTorsoLength;

    if (widthRatio >= _frontWidthRatio) {
      return const ViewDetectionResult(ExerciseView.front, 0.85);
    }

    if (widthRatio <= _sideWidthRatio) {
      return const ViewDetectionResult(ExerciseView.side, 0.8);
    }

    return const ViewDetectionResult(ExerciseView.unknown, 0.45);
  }
}
