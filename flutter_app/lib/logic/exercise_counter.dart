import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Result of processing a pose, containing count and feedback
class CounterResult {
  final int count;
  final String feedback;
  final bool countIncremented;

  CounterResult({
    required this.count,
    required this.feedback,
    this.countIncremented = false,
  });
}

/// Abstract base class for exercise counters
/// All exercise counters must implement this interface
abstract class ExerciseCounter {
  /// Minimum confidence threshold for pose landmarks
  static const double minLikelihood = 0.5;

  /// Current repetition count
  int get count;

  /// Current state/feedback string
  String get feedback;

  /// Processes a pose and updates the counter state
  /// Returns a CounterResult containing the updated count and feedback
  CounterResult calculate(Pose pose);

  /// Resets the counter to initial state
  void reset();

  /// Checks if all required landmarks are valid (not null and have sufficient likelihood)
  bool areLandmarksValid(List<PoseLandmark?> landmarks) {
    for (final landmark in landmarks) {
      if (landmark == null || landmark.likelihood < minLikelihood) {
        return false;
      }
    }
    return true;
  }
}
