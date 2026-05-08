import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/readiness_evaluator.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('readiness evaluator can run fixed start countdown without pose checks',
      () {
    final evaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 10,
      enforceReadinessChecks: false,
      requiredJoints: const {
        Joint.leftShoulder,
        Joint.leftHip,
        Joint.leftKnee,
        Joint.leftAnkle,
      },
    );

    final warmup = evaluator.evaluate(frame: null, elapsedSeconds: 0);
    final afterTenSeconds = evaluator.evaluate(frame: null, elapsedSeconds: 10);

    expect(warmup.state, ReadinessState.countdownReady);
    expect(afterTenSeconds.canStartTracking, isTrue);
    expect(afterTenSeconds.remainingSeconds, 0);
  });

  test('fixed start countdown is not reset by an invalid pose frame', () {
    final evaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 10,
      enforceReadinessChecks: false,
      requiredJoints: const {
        Joint.leftShoulder,
        Joint.leftHip,
        Joint.leftKnee,
        Joint.leftAnkle,
      },
    );

    final invalidFrame = PoseFrame(
      landmarks: const {},
      derivedMetrics: const {
        'start_pose_valid': 0,
      },
    );

    final warmup = evaluator.evaluate(frame: invalidFrame, elapsedSeconds: 4);
    final afterTenSeconds =
        evaluator.evaluate(frame: invalidFrame, elapsedSeconds: 10);

    expect(warmup.state, ReadinessState.countdownReady);
    expect(warmup.remainingSeconds, 6);
    expect(afterTenSeconds.state, ReadinessState.activeTracking);
    expect(afterTenSeconds.canStartTracking, isTrue);
  });

  test('readiness evaluator advances when a valid pose frame is provided', () {
    final evaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 3,
      requiredJoints: const {
        Joint.leftShoulder,
        Joint.leftHip,
        Joint.leftKnee,
        Joint.leftAnkle,
      },
    );

    final validFrame = PoseFrame(
      landmarks: const {
        Joint.leftShoulder: FrameLandmark(x: 0, y: 0, confidence: 1),
        Joint.rightShoulder: FrameLandmark(x: 120, y: 0, confidence: 1),
        Joint.leftHip: FrameLandmark(x: 0, y: 100, confidence: 1),
        Joint.rightHip: FrameLandmark(x: 120, y: 100, confidence: 1),
        Joint.leftKnee: FrameLandmark(x: 0, y: 180, confidence: 1),
        Joint.leftAnkle: FrameLandmark(x: 0, y: 260, confidence: 1),
      },
      derivedMetrics: {
        'start_pose_valid': 1,
      },
    );

    final warmup = evaluator.evaluate(frame: validFrame, elapsedSeconds: 0);
    final active = evaluator.evaluate(frame: validFrame, elapsedSeconds: 3);

    expect(warmup.state, ReadinessState.countdownReady);
    expect(warmup.remainingSeconds, 3);
    expect(active.state, ReadinessState.activeTracking);
    expect(active.canStartTracking, isTrue);
  });

  test(
      'readiness evaluator accepts a full right-side profile for side-view exercises',
      () {
    final evaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 0,
      requiredJoints: const {},
      visibilityJointGroups: const [
        {
          Joint.leftShoulder,
          Joint.leftHip,
          Joint.leftKnee,
          Joint.leftAnkle,
        },
        {
          Joint.rightShoulder,
          Joint.rightHip,
          Joint.rightKnee,
          Joint.rightAnkle,
        },
      ],
    );

    final validRightSideFrame = PoseFrame(
      landmarks: const {
        Joint.leftShoulder: FrameLandmark(x: 0, y: 0, confidence: 1),
        Joint.leftHip: FrameLandmark(x: 0, y: 100, confidence: 1),
        Joint.rightShoulder: FrameLandmark(x: 120, y: 0, confidence: 1),
        Joint.rightHip: FrameLandmark(x: 120, y: 100, confidence: 1),
        Joint.rightKnee: FrameLandmark(x: 120, y: 180, confidence: 1),
        Joint.rightAnkle: FrameLandmark(x: 120, y: 260, confidence: 1),
      },
      derivedMetrics: {
        'start_pose_valid': 1,
      },
    );

    final result = evaluator.evaluate(
      frame: validRightSideFrame,
      elapsedSeconds: 0,
    );

    expect(result.state, ReadinessState.activeTracking);
    expect(result.canStartTracking, isTrue);
  });
}
