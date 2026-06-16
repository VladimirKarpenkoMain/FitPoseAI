import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_counter.dart';
import '../utils/pose_geometry.dart';

/// State machine for squat exercise
enum SquatState {
  up,   // Standing straight (angle > 160°)
  down, // Squat position (angle < 90°)
}

/// Squat counter implementation
/// Tracks squats by measuring knee angle (Hip -> Knee -> Ankle).
/// All exercises are performed facing the camera.
class SquatCounter extends ExerciseCounter {
  int _count = 0;
  SquatState _currentState = SquatState.up;
  String _feedback = "Stand Straight";

  // Angle thresholds
  static const double upAngleThreshold = 155.0;   // Standing straight
  static const double downAngleThreshold = 100.0;  // Squat depth (relaxed from 85 for front view)

  // Anti-cheat: track hip Y-coordinate change from standing to squat
  double? _standingHipY; // Hip Y when person is standing upright
  static const double minHipMovement = 30.0; // Minimum pixels hip must move down

  // Smoothing and stabilization
  final AngleSmoother _leftKneeSmoother = AngleSmoother(alpha: 0.5);
  final AngleSmoother _rightKneeSmoother = AngleSmoother(alpha: 0.5);
  final FrameStabilizer _downStabilizer = FrameStabilizer(requiredFrames: 2);
  final FrameStabilizer _upStabilizer = FrameStabilizer(requiredFrames: 2);

  @override
  int get count => _count;

  @override
  String get feedback => _feedback;

  @override
  void reset() {
    _count = 0;
    _currentState = SquatState.up;
    _feedback = "Stand Straight";
    _standingHipY = null;
    _leftKneeSmoother.reset();
    _rightKneeSmoother.reset();
    _downStabilizer.reset();
    _upStabilizer.reset();
  }

  @override
  CounterResult calculate(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    double? leftAngle;
    double? rightAngle;
    double? avgHipY;

    if (areLandmarksValid([leftHip, leftKnee, leftAnkle])) {
      final raw = PoseGeometry.getAngle(
        Point(leftHip!.x, leftHip.y),
        Point(leftKnee!.x, leftKnee.y),
        Point(leftAnkle!.x, leftAnkle.y),
      );
      leftAngle = _leftKneeSmoother.update(raw);
    }

    if (areLandmarksValid([rightHip, rightKnee, rightAnkle])) {
      final raw = PoseGeometry.getAngle(
        Point(rightHip!.x, rightHip.y),
        Point(rightKnee!.x, rightKnee.y),
        Point(rightAnkle!.x, rightAnkle.y),
      );
      rightAngle = _rightKneeSmoother.update(raw);
    }

    // Calculate average hip Y position for anti-cheat
    if (leftHip != null && rightHip != null) {
      avgHipY = (leftHip.y + rightHip.y) / 2;
    } else if (leftHip != null) {
      avgHipY = leftHip.y;
    } else if (rightHip != null) {
      avgHipY = rightHip.y;
    }

    if (leftAngle == null && rightAngle == null) {
      _feedback = "Position yourself in frame";
      return CounterResult(count: _count, feedback: _feedback);
    }

    double kneeAngle;
    if (leftAngle != null && rightAngle != null) {
      kneeAngle = (leftAngle + rightAngle) / 2;
    } else {
      kneeAngle = leftAngle ?? rightAngle!;
    }

    bool repCounted = _updateState(kneeAngle, avgHipY);

    return CounterResult(
      count: _count,
      feedback: _feedback,
      countIncremented: repCounted,
    );
  }

  /// Updates the state machine based on knee angle
  /// Returns true if a repetition was counted
  bool _updateState(double angle, double? currentHipY) {
    bool repCounted = false;

    switch (_currentState) {
      case SquatState.up:
        // Capture standing hip Y position for anti-cheat reference
        if (angle > upAngleThreshold && currentHipY != null) {
          _standingHipY = currentHipY;
        }

        bool isDown = angle < downAngleThreshold;
        if (_downStabilizer.update(isDown)) {
          // Anti-cheat: hip must actually move down
          if (_standingHipY != null && currentHipY != null) {
            final hipMovement = currentHipY - _standingHipY!;
            if (hipMovement < minHipMovement) {
              _feedback = "Go Lower";
              break;
            }
          }
          _currentState = SquatState.down;
          _upStabilizer.reset();
          _feedback = "Good";
        } else if (angle < upAngleThreshold) {
          _feedback = "Go Lower";
        } else {
          _feedback = "Go Down";
        }
        break;

      case SquatState.down:
        bool isUp = angle > upAngleThreshold;
        if (_upStabilizer.update(isUp)) {
          _currentState = SquatState.up;
          _downStabilizer.reset();
          _count++;
          _feedback = "Good!";
          repCounted = true;
          // Reset standing reference for next rep
          _standingHipY = null;
        } else {
          _feedback = "Stand Up";
        }
        break;
    }

    return repCounted;
  }
}
