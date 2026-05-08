import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_counter.dart';
import '../utils/pose_geometry.dart';

/// State machine for jumping jack exercise
enum JumpingJackState {
  closed, // Feet together, arms down
  open,   // Star shape - feet apart, arms up
}

/// Jumping Jack counter implementation
/// Tracks jumping jacks by measuring arm elevation and leg spread.
///
/// Arms: Hip -> Shoulder -> Wrist angle (arm elevation relative to torso)
///   - Arms down: angle is small (~10-30°)
///   - Arms up: angle is large (~150-180°)
/// Legs: LeftKnee -> MidHip -> RightKnee angle (spread between legs)
///   - Feet together: angle is small (~5-15°)
///   - Feet apart: angle is large (~40-60°)
class JumpingJackCounter extends ExerciseCounter {
  int _count = 0;
  JumpingJackState _currentState = JumpingJackState.closed;
  String _feedback = "Ready";

  // Arm elevation thresholds (Hip -> Shoulder -> Wrist angle)
  static const double armClosedThreshold = 40.0;   // Arms at sides
  static const double armOpenThreshold = 130.0;     // Arms raised overhead

  // Leg spread thresholds (LeftKnee -> MidHip -> RightKnee)
  static const double legClosedThreshold = 25.0;   // Feet together
  static const double legOpenThreshold = 40.0;     // Feet apart

  // Smoothers to filter out noise
  final AngleSmoother _leftArmSmoother = AngleSmoother(alpha: 0.5);
  final AngleSmoother _rightArmSmoother = AngleSmoother(alpha: 0.5);
  final AngleSmoother _legSmoother = AngleSmoother(alpha: 0.5);

  // Stabilizers to prevent single-frame false triggers
  final FrameStabilizer _openStabilizer = FrameStabilizer(requiredFrames: 2);
  final FrameStabilizer _closedStabilizer = FrameStabilizer(requiredFrames: 2);

  @override
  int get count => _count;

  @override
  String get feedback => _feedback;

  @override
  void reset() {
    _count = 0;
    _currentState = JumpingJackState.closed;
    _feedback = "Ready";
    _leftArmSmoother.reset();
    _rightArmSmoother.reset();
    _legSmoother.reset();
    _openStabilizer.reset();
    _closedStabilizer.reset();
  }

  @override
  CounterResult calculate(Pose pose) {
    // Get landmarks
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];

    // Calculate arm elevation angles: Hip -> Shoulder -> Wrist
    // This measures how high the arm is raised relative to the torso
    double? leftArmAngle;
    double? rightArmAngle;

    if (areLandmarksValid([leftHip, leftShoulder, leftWrist])) {
      final raw = PoseGeometry.getAngle(
        Point(leftHip!.x, leftHip.y),
        Point(leftShoulder!.x, leftShoulder.y),
        Point(leftWrist!.x, leftWrist.y),
      );
      leftArmAngle = _leftArmSmoother.update(raw);
    }

    if (areLandmarksValid([rightHip, rightShoulder, rightWrist])) {
      final raw = PoseGeometry.getAngle(
        Point(rightHip!.x, rightHip.y),
        Point(rightShoulder!.x, rightShoulder.y),
        Point(rightWrist!.x, rightWrist.y),
      );
      rightArmAngle = _rightArmSmoother.update(raw);
    }

    // Calculate leg angle: LeftKnee -> MidHip -> RightKnee
    double? legAngle;

    if (areLandmarksValid([leftHip, leftKnee]) &&
        areLandmarksValid([rightHip, rightKnee])) {
      final midHipX = (leftHip!.x + rightHip!.x) / 2;
      final midHipY = (leftHip.y + rightHip.y) / 2;

      final raw = PoseGeometry.getAngle(
        Point(leftKnee!.x, leftKnee.y),
        Point(midHipX, midHipY),
        Point(rightKnee!.x, rightKnee.y),
      );
      legAngle = _legSmoother.update(raw);
    }

    // Check if we have valid data
    if ((leftArmAngle == null && rightArmAngle == null) || legAngle == null) {
      _feedback = "Position yourself in frame";
      return CounterResult(count: _count, feedback: _feedback);
    }

    // Use average arm angle or single available angle
    double armAngle;
    if (leftArmAngle != null && rightArmAngle != null) {
      armAngle = (leftArmAngle + rightArmAngle) / 2;
    } else {
      armAngle = leftArmAngle ?? rightArmAngle!;
    }

    // Update state machine and check for rep
    bool repCounted = _updateState(armAngle, legAngle);

    return CounterResult(
      count: _count,
      feedback: _feedback,
      countIncremented: repCounted,
    );
  }

  /// Updates the state machine based on arm elevation and leg spread angles
  /// Returns true if a repetition was counted
  bool _updateState(double armAngle, double legAngle) {
    bool repCounted = false;

    bool armsOpen = armAngle > armOpenThreshold;
    bool armsClosed = armAngle < armClosedThreshold;
    bool legsOpen = legAngle > legOpenThreshold;
    bool legsClosed = legAngle < legClosedThreshold;

    switch (_currentState) {
      case JumpingJackState.closed:
        // Waiting for OPEN position (arms up, legs apart)
        bool isOpen = armsOpen && legsOpen;
        if (_openStabilizer.update(isOpen)) {
          _currentState = JumpingJackState.open;
          _closedStabilizer.reset();
          _feedback = "Good";
        } else if (!armsOpen && !legsOpen) {
          _feedback = "Jump!";
        } else if (!armsOpen) {
          _feedback = "Raise arms";
        } else if (!legsOpen) {
          _feedback = "Spread legs";
        }
        break;

      case JumpingJackState.open:
        // Waiting for CLOSED position (arms down, feet together)
        bool isClosed = armsClosed && legsClosed;
        if (_closedStabilizer.update(isClosed)) {
          _currentState = JumpingJackState.closed;
          _openStabilizer.reset();
          _count++;
          _feedback = "Good!";
          repCounted = true;
        } else if (!armsClosed && !legsClosed) {
          _feedback = "Return to start";
        } else if (!armsClosed) {
          _feedback = "Lower arms";
        } else if (!legsClosed) {
          _feedback = "Feet together";
        }
        break;
    }

    return repCounted;
  }
}
