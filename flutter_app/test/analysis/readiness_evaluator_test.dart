import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/readiness_evaluator.dart';
import 'package:fitness_ai/analysis/readiness_requirements.dart';
import 'package:fitness_ai/models/exercise_type.dart';
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

    const invalidFrame = PoseFrame(
      landmarks: {},
      derivedMetrics: {
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

    const validFrame = PoseFrame(
      landmarks: {
        Joint.leftShoulder: FrameLandmark(x: 0, y: 0, confidence: 1),
        Joint.rightShoulder: FrameLandmark(x: 12, y: 0, confidence: 1),
        Joint.leftHip: FrameLandmark(x: 0, y: 100, confidence: 1),
        Joint.rightHip: FrameLandmark(x: 12, y: 100, confidence: 1),
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

    const validRightSideFrame = PoseFrame(
      landmarks: {
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

  test('readiness evaluator rejects front view for side-view exercises', () {
    final evaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 0,
      requiredJoints: const {},
      visibilityJointGroups: const [
        {
          Joint.leftShoulder,
          Joint.leftHip,
          Joint.leftAnkle,
        },
        {
          Joint.rightShoulder,
          Joint.rightHip,
          Joint.rightAnkle,
        },
      ],
    );

    const frontFrame = PoseFrame(
      landmarks: {
        Joint.leftShoulder: FrameLandmark(x: 0, y: 0, confidence: 1),
        Joint.rightShoulder: FrameLandmark(x: 120, y: 0, confidence: 1),
        Joint.leftHip: FrameLandmark(x: 0, y: 100, confidence: 1),
        Joint.rightHip: FrameLandmark(x: 120, y: 100, confidence: 1),
        Joint.leftAnkle: FrameLandmark(x: 0, y: 260, confidence: 1),
        Joint.rightAnkle: FrameLandmark(x: 120, y: 260, confidence: 1),
      },
      derivedMetrics: {
        'start_pose_valid': 1,
      },
    );

    final result = evaluator.evaluate(frame: frontFrame, elapsedSeconds: 0);

    expect(result.state, ReadinessState.viewAlignment);
    expect(result.canStartTracking, isFalse);
    expect(result.blocker, 'Turn to your side');
  });

  test('readiness evaluator keeps last stable view during transition frames',
      () {
    final evaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 0,
      requiredJoints: const {},
      visibilityJointGroups: const [
        {
          Joint.leftShoulder,
          Joint.leftHip,
          Joint.leftAnkle,
        },
        {
          Joint.rightShoulder,
          Joint.rightHip,
          Joint.rightAnkle,
        },
      ],
    );

    final sideResult = evaluator.evaluate(
      frame: _frameWithBodyWidth(12),
      elapsedSeconds: 0,
    );
    final transitionResult = evaluator.evaluate(
      frame: _frameWithBodyWidth(26),
      elapsedSeconds: 1,
    );

    expect(sideResult.state, ReadinessState.activeTracking);
    expect(transitionResult.state, ReadinessState.activeTracking);
    expect(transitionResult.canStartTracking, isTrue);
  });

  test('readiness evaluator switches view only after stable repeated frames',
      () {
    final evaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 0,
      requiredJoints: const {},
      visibilityJointGroups: const [
        {
          Joint.leftShoulder,
          Joint.leftHip,
          Joint.leftAnkle,
        },
        {
          Joint.rightShoulder,
          Joint.rightHip,
          Joint.rightAnkle,
        },
      ],
    );

    final initialSide = evaluator.evaluate(
      frame: _frameWithBodyWidth(12),
      elapsedSeconds: 0,
    );
    final firstFront = evaluator.evaluate(
      frame: _frameWithBodyWidth(120),
      elapsedSeconds: 1,
    );
    final secondFront = evaluator.evaluate(
      frame: _frameWithBodyWidth(120),
      elapsedSeconds: 2,
    );
    final thirdFront = evaluator.evaluate(
      frame: _frameWithBodyWidth(120),
      elapsedSeconds: 3,
    );

    expect(initialSide.state, ReadinessState.activeTracking);
    expect(firstFront.state, ReadinessState.activeTracking);
    expect(secondFront.state, ReadinessState.activeTracking);
    expect(thirdFront.state, ReadinessState.viewAlignment);
    expect(thirdFront.canStartTracking, isFalse);
  });

  test(
      'shoulder press readiness does not require knees or ankles when upper body is visible',
      () {
    final requirements = readinessRequirementsFor(ExerciseType.shoulderPress);
    final evaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 0,
      requiredJoints: requirements.requiredJoints,
      visibilityJointGroups: requirements.visibilityJointGroups,
    );

    const upperBodyPressFrame = PoseFrame(
      landmarks: {
        Joint.leftShoulder: FrameLandmark(x: 0, y: 0, confidence: 0.9),
        Joint.rightShoulder: FrameLandmark(x: 12, y: 0, confidence: 0.9),
        Joint.leftElbow: FrameLandmark(x: -8, y: 32, confidence: 0.9),
        Joint.rightElbow: FrameLandmark(x: 20, y: 32, confidence: 0.9),
        Joint.leftWrist: FrameLandmark(x: -10, y: 64, confidence: 0.9),
        Joint.rightWrist: FrameLandmark(x: 22, y: 64, confidence: 0.9),
        Joint.leftHip: FrameLandmark(x: 0, y: 100, confidence: 0.9),
        Joint.rightHip: FrameLandmark(x: 12, y: 100, confidence: 0.9),
        Joint.leftKnee: FrameLandmark(x: 0, y: 180, confidence: 0.2),
        Joint.rightKnee: FrameLandmark(x: 12, y: 180, confidence: 0.2),
        Joint.leftAnkle: FrameLandmark(x: 0, y: 260, confidence: 0.2),
        Joint.rightAnkle: FrameLandmark(x: 12, y: 260, confidence: 0.2),
      },
      derivedMetrics: {
        'start_pose_valid': 1,
      },
    );

    final result = evaluator.evaluate(
      frame: upperBodyPressFrame,
      elapsedSeconds: 0,
    );

    expect(result.state, ReadinessState.activeTracking);
    expect(result.canStartTracking, isTrue);
  });

  test('jumping jack readiness requires both ankles for front-view width', () {
    final requirements = readinessRequirementsFor(ExerciseType.jumpingJack);

    expect(requirements.requiredJoints, contains(Joint.leftAnkle));
    expect(requirements.requiredJoints, contains(Joint.rightAnkle));
  });
}

PoseFrame _frameWithBodyWidth(double bodyWidth) {
  return PoseFrame(
    landmarks: {
      Joint.leftShoulder: const FrameLandmark(x: 0, y: 0, confidence: 1),
      Joint.rightShoulder: FrameLandmark(x: bodyWidth, y: 0, confidence: 1),
      Joint.leftHip: const FrameLandmark(x: 0, y: 100, confidence: 1),
      Joint.rightHip: FrameLandmark(x: bodyWidth, y: 100, confidence: 1),
      Joint.leftAnkle: const FrameLandmark(x: 0, y: 260, confidence: 1),
      Joint.rightAnkle: FrameLandmark(x: bodyWidth, y: 260, confidence: 1),
    },
    derivedMetrics: const {
      'start_pose_valid': 1,
    },
  );
}
