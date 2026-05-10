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

    final shoulderWidth =
        PoseMetrics.horizontalDistance(leftShoulder, rightShoulder);
    final hipWidth = PoseMetrics.horizontalDistance(leftHip, rightHip);
    final averageWidth = (shoulderWidth + hipWidth) / 2;
    final leftTorsoHeight = PoseMetrics.verticalDistance(leftShoulder, leftHip);
    final rightTorsoHeight =
        PoseMetrics.verticalDistance(rightShoulder, rightHip);
    final averageTorsoHeight = (leftTorsoHeight + rightTorsoHeight) / 2;

    if (averageTorsoHeight <= 0) {
      return const ViewDetectionResult(ExerciseView.unknown, 0);
    }

    final widthRatio = averageWidth / averageTorsoHeight;

    if (widthRatio >= _frontWidthRatio) {
      return const ViewDetectionResult(ExerciseView.front, 0.85);
    }

    if (widthRatio <= _sideWidthRatio) {
      return const ViewDetectionResult(ExerciseView.side, 0.8);
    }

    return const ViewDetectionResult(ExerciseView.unknown, 0.45);
  }
}
