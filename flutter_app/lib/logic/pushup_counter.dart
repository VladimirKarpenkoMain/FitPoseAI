import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_counter.dart';
import '../utils/pose_geometry.dart';

/// State machine for push-up exercise
enum PushUpState {
  up,   // Arms extended (angle > 150°)
  down, // Chest close to floor (angle < 90°)
}

/// Push-up counter implementation
/// Tracks push-ups using elbow angle AND vertical shoulder movement.
///
/// Primary: Shoulder -> Elbow -> Wrist angle at the elbow
/// Secondary: Shoulder Y-position tracking for front-facing camera
///   (when facing camera, vertical movement is the most reliable signal)
///
/// Body alignment check is only applied when a side-view is detected
/// (shoulder-hip horizontal distance is large enough).
class PushUpCounter extends ExerciseCounter {
  int _count = 0;
  PushUpState _currentState = PushUpState.up;
  String _feedback = "Ready";

  // Elbow angle thresholds
  static const double upAngleThreshold = 150.0;   // Arms extended
  static const double downAngleThreshold = 100.0;  // Arms bent

  // Vertical movement thresholds (for front-facing supplement)
  double? _upShoulderY;  // Shoulder Y when in UP position
  static const double minVerticalMovement = 30.0; // Min pixels shoulder must move down

  // Smoothing
  final AngleSmoother _leftArmSmoother = AngleSmoother(alpha: 0.5);
  final AngleSmoother _rightArmSmoother = AngleSmoother(alpha: 0.5);
  final FrameStabilizer _downStabilizer = FrameStabilizer(requiredFrames: 2);
  final FrameStabilizer _upStabilizer = FrameStabilizer(requiredFrames: 2);

  @override
  int get count => _count;

  @override
  String get feedback => _feedback;

  @override
  void reset() {
    _count = 0;
    _currentState = PushUpState.up;
    _feedback = "Ready";
    _upShoulderY = null;
    _leftArmSmoother.reset();
    _rightArmSmoother.reset();
    _downStabilizer.reset();
    _upStabilizer.reset();
  }

  @override
  CounterResult calculate(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // Body alignment landmarks
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    double? leftArmAngle;
    double? rightArmAngle;

    if (areLandmarksValid([leftShoulder, leftElbow, leftWrist])) {
      final raw = PoseGeometry.getAngle(
        Point(leftShoulder!.x, leftShoulder.y),
        Point(leftElbow!.x, leftElbow.y),
        Point(leftWrist!.x, leftWrist.y),
      );
      leftArmAngle = _leftArmSmoother.update(raw);
    }

    if (areLandmarksValid([rightShoulder, rightElbow, rightWrist])) {
      final raw = PoseGeometry.getAngle(
        Point(rightShoulder!.x, rightShoulder.y),
        Point(rightElbow!.x, rightElbow.y),
        Point(rightWrist!.x, rightWrist.y),
      );
      rightArmAngle = _rightArmSmoother.update(raw);
    }

    if (leftArmAngle == null && rightArmAngle == null) {
      _feedback = "Position yourself in frame";
      return CounterResult(count: _count, feedback: _feedback);
    }

    double armAngle;
    if (leftArmAngle != null && rightArmAngle != null) {
      armAngle = (leftArmAngle + rightArmAngle) / 2;
    } else {
      armAngle = leftArmAngle ?? rightArmAngle!;
    }

    // Calculate average shoulder Y for vertical movement tracking
    double? shoulderY;
    if (leftShoulder != null && rightShoulder != null) {
      shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    } else if (leftShoulder != null) {
      shoulderY = leftShoulder.y;
    } else if (rightShoulder != null) {
      shoulderY = rightShoulder.y;
    }

    // Body alignment check - only apply when we have a good side view
    // Detect side view: large horizontal distance between shoulder and hip
    bool isSideView = false;
    double? bodyAlignment;

    if (areLandmarksValid([leftShoulder, leftHip, leftAnkle])) {
      final shoulderHipDist = (leftShoulder!.x - leftHip!.x).abs();
      if (shoulderHipDist > 50) {
        isSideView = true;
        bodyAlignment = PoseGeometry.getAngle(
          Point(leftShoulder.x, leftShoulder.y),
          Point(leftHip.x, leftHip.y),
          Point(leftAnkle!.x, leftAnkle.y),
        );
      }
    } else if (areLandmarksValid([rightShoulder, rightHip, rightAnkle])) {
      final shoulderHipDist = (rightShoulder!.x - rightHip!.x).abs();
      if (shoulderHipDist > 50) {
        isSideView = true;
        bodyAlignment = PoseGeometry.getAngle(
          Point(rightShoulder.x, rightShoulder.y),
          Point(rightHip.x, rightHip.y),
          Point(rightAnkle!.x, rightAnkle.y),
        );
      }
    }

    // Only check alignment from side view
    if (isSideView && bodyAlignment != null && bodyAlignment < 150.0) {
      _feedback = "Fix your back!";
      return CounterResult(count: _count, feedback: _feedback);
    }

    bool repCounted = _updateState(armAngle, shoulderY);

    return CounterResult(
      count: _count,
      feedback: _feedback,
      countIncremented: repCounted,
    );
  }

  /// Updates the state machine based on arm angle and vertical movement
  bool _updateState(double angle, double? shoulderY) {
    bool repCounted = false;

    switch (_currentState) {
      case PushUpState.up:
        // Capture shoulder Y position when standing in UP position
        if (angle > upAngleThreshold && shoulderY != null) {
          _upShoulderY = shoulderY;
        }

        // Check if going down: arm angle decreases AND shoulder moves down
        bool angleDown = angle < downAngleThreshold;
        bool verticalDown = true;
        if (_upShoulderY != null && shoulderY != null) {
          // Shoulder Y increases when moving down in screen coordinates
          verticalDown = (shoulderY - _upShoulderY!) > minVerticalMovement;
        }

        // For front-facing: require both angle and vertical movement
        // For side-facing: angle alone is sufficient
        bool isDown = angleDown;
        if (_upShoulderY != null) {
          isDown = angleDown || (verticalDown && angle < upAngleThreshold);
        }

        if (_downStabilizer.update(isDown)) {
          _currentState = PushUpState.down;
          _upStabilizer.reset();
          _feedback = "Good";
        } else if (angle < upAngleThreshold) {
          _feedback = "Go Lower";
        } else {
          _feedback = "Go Down";
        }
        break;

      case PushUpState.down:
        bool isUp = angle > upAngleThreshold;
        if (_upStabilizer.update(isUp)) {
          _currentState = PushUpState.up;
          _downStabilizer.reset();
          _count++;
          _feedback = "Good!";
          repCounted = true;
          _upShoulderY = null; // Reset for next rep
        } else {
          _feedback = "Push Up";
        }
        break;
    }

    return repCounted;
  }
}
