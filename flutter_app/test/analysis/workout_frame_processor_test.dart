import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/readiness_evaluator.dart';
import 'package:fitness_ai/analysis/workout_analyzer.dart';
import 'package:fitness_ai/analysis/workout_frame_processor.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('processor passes stabilized frame into workout analysis', () {
    final readinessEvaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 0,
      requiredJoints: const {},
      enforceReadinessChecks: false,
    );

    PoseFrame? processedFrame;
    final processor = WorkoutFrameProcessor(
      readinessEvaluator: readinessEvaluator,
      analyzeFrame: (frame, {required readiness}) {
        processedFrame = frame;
        return WorkoutFrameResult(
          readiness: readiness,
          systemStatus: 'Tracking active',
        );
      },
      missingPoseTolerance: const Duration(milliseconds: 300),
    );

    const stableFrame = PoseFrame(
      frameIndex: 7,
      timestampMs: 700,
      landmarks: {},
      derivedMetrics: {'start_pose_valid': 1},
    );

    processor.process(
        rawFrame: stableFrame, elapsed: const Duration(milliseconds: 700));
    processedFrame = null;

    processor.process(
        rawFrame: null, elapsed: const Duration(milliseconds: 850));

    expect(processedFrame, same(stableFrame));
  });

  test('processor returns debug info with frame and readiness context', () {
    final readinessEvaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 0,
      requiredJoints: const {},
      enforceReadinessChecks: false,
    );

    final processor = WorkoutFrameProcessor(
      readinessEvaluator: readinessEvaluator,
      analyzeFrame: (frame, {required readiness}) {
        return WorkoutFrameResult(
          readiness: readiness,
          systemStatus: 'Tracking active',
        );
      },
      missingPoseTolerance: const Duration(milliseconds: 300),
    );

    const frame = PoseFrame(
      frameIndex: 11,
      timestampMs: 990,
      landmarks: {},
      derivedMetrics: {
        'phase_knee_angle': 132,
        'start_pose_valid': 1,
      },
    );

    final result = processor.process(
      rawFrame: frame,
      elapsed: const Duration(milliseconds: 990),
    );

    expect(result.debugInfo, isNotNull);
    expect(result.debugInfo!.frameIndex, 11);
    expect(result.debugInfo!.timestampMs, 990);
    expect(result.debugInfo!.readinessState, ReadinessState.activeTracking);
    expect(result.debugInfo!.metrics['phase_knee_angle'], 132);
    expect(result.debugInfo!.toLogLine(), contains('frame=11'));
  });

  test(
      'processor keeps tracking active after workout starts while pose leaves start position',
      () {
    final readinessEvaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 0,
      requiredJoints: const {
        Joint.leftShoulder,
        Joint.leftHip,
        Joint.leftKnee,
        Joint.leftAnkle,
      },
      visibilityJointGroups: const [
        {
          Joint.leftShoulder,
          Joint.leftHip,
          Joint.leftKnee,
          Joint.leftAnkle,
        },
      ],
    );

    final observedReadiness = <ReadinessResult>[];
    final processor = WorkoutFrameProcessor(
      readinessEvaluator: readinessEvaluator,
      analyzeFrame: (frame, {required readiness}) {
        observedReadiness.add(readiness);
        return WorkoutFrameResult(
          readiness: readiness,
          systemStatus:
              readiness.canStartTracking ? 'Tracking active' : 'Get ready',
        );
      },
    );

    final startFrame = _sideFrame(
      frameIndex: 1,
      timestampMs: 100,
      startPoseValid: true,
    );
    final descendingFrame = _sideFrame(
      frameIndex: 2,
      timestampMs: 200,
      startPoseValid: false,
    );

    final activeResult = processor.process(
      rawFrame: startFrame,
      elapsed: const Duration(milliseconds: 100),
    );
    final descendingResult = processor.process(
      rawFrame: descendingFrame,
      elapsed: const Duration(milliseconds: 200),
    );

    expect(activeResult.readiness.state, ReadinessState.activeTracking);
    expect(descendingResult.readiness.state, ReadinessState.activeTracking);
    expect(descendingResult.readiness.canStartTracking, isTrue);
    expect(observedReadiness.last.canStartTracking, isTrue);
  });

  test(
      'processor keeps tracking active after workout starts during transient view mismatch',
      () {
    final readinessEvaluator = ReadinessEvaluator(
      requiredView: ExerciseView.front,
      countdownSeconds: 0,
      requiredJoints: const {
        Joint.leftShoulder,
        Joint.rightShoulder,
        Joint.leftHip,
        Joint.rightHip,
      },
    );

    final observedReadiness = <ReadinessResult>[];
    final processor = WorkoutFrameProcessor(
      readinessEvaluator: readinessEvaluator,
      analyzeFrame: (frame, {required readiness}) {
        observedReadiness.add(readiness);
        return WorkoutFrameResult(
          readiness: readiness,
          systemStatus:
              readiness.canStartTracking ? 'Tracking active' : 'Get ready',
        );
      },
    );

    final startFrame = _frontFrame(
      frameIndex: 1,
      timestampMs: 100,
      bodyWidth: 120,
      startPoseValid: true,
    );
    final movingFrame = _frontFrame(
      frameIndex: 2,
      timestampMs: 200,
      bodyWidth: 36,
      startPoseValid: false,
    );

    final activeResult = processor.process(
      rawFrame: startFrame,
      elapsed: const Duration(milliseconds: 100),
    );
    final movingResult = processor.process(
      rawFrame: movingFrame,
      elapsed: const Duration(milliseconds: 200),
    );

    expect(activeResult.readiness.state, ReadinessState.activeTracking);
    expect(movingResult.readiness.state, ReadinessState.activeTracking);
    expect(movingResult.readiness.canStartTracking, isTrue);
    expect(observedReadiness.last.canStartTracking, isTrue);
  });

  test(
      'processor pauses front-view exercise after repeated real side-view frames',
      () {
    final readinessEvaluator = ReadinessEvaluator(
      requiredView: ExerciseView.front,
      countdownSeconds: 0,
      requiredJoints: const {
        Joint.leftShoulder,
        Joint.rightShoulder,
        Joint.leftHip,
        Joint.rightHip,
      },
    );

    final processor = WorkoutFrameProcessor(
      readinessEvaluator: readinessEvaluator,
      analyzeFrame: (frame, {required readiness}) {
        return WorkoutFrameResult(
          readiness: readiness,
          systemStatus:
              readiness.canStartTracking ? 'Tracking active' : 'Get ready',
        );
      },
    );

    final activeResult = processor.process(
      rawFrame: _frontFrame(
        frameIndex: 1,
        timestampMs: 100,
        bodyWidth: 120,
        startPoseValid: true,
      ),
      elapsed: const Duration(milliseconds: 100),
    );
    final firstSideResult = processor.process(
      rawFrame: _frontFrame(
        frameIndex: 2,
        timestampMs: 200,
        bodyWidth: 12,
        startPoseValid: false,
      ),
      elapsed: const Duration(milliseconds: 200),
    );
    final secondSideResult = processor.process(
      rawFrame: _frontFrame(
        frameIndex: 3,
        timestampMs: 300,
        bodyWidth: 12,
        startPoseValid: false,
      ),
      elapsed: const Duration(milliseconds: 300),
    );
    final thirdSideResult = processor.process(
      rawFrame: _frontFrame(
        frameIndex: 4,
        timestampMs: 400,
        bodyWidth: 12,
        startPoseValid: false,
      ),
      elapsed: const Duration(milliseconds: 400),
    );

    expect(activeResult.readiness.state, ReadinessState.activeTracking);
    expect(firstSideResult.readiness.state, ReadinessState.activeTracking);
    expect(secondSideResult.readiness.state, ReadinessState.activeTracking);
    expect(thirdSideResult.readiness.state, ReadinessState.viewAlignment);
    expect(thirdSideResult.readiness.canStartTracking, isFalse);
  });

  test('processor pauses tracking after start when required joints are lost',
      () {
    final readinessEvaluator = ReadinessEvaluator(
      requiredView: ExerciseView.side,
      countdownSeconds: 0,
      requiredJoints: const {
        Joint.leftShoulder,
        Joint.leftHip,
        Joint.leftKnee,
        Joint.leftAnkle,
      },
      visibilityJointGroups: const [
        {
          Joint.leftShoulder,
          Joint.leftHip,
          Joint.leftKnee,
          Joint.leftAnkle,
        },
      ],
    );

    var analyzeCalls = 0;
    final processor = WorkoutFrameProcessor(
      readinessEvaluator: readinessEvaluator,
      analyzeFrame: (frame, {required readiness}) {
        analyzeCalls++;
        return WorkoutFrameResult(
          readiness: readiness,
          systemStatus:
              readiness.canStartTracking ? 'Tracking active' : 'Get ready',
        );
      },
    );

    final activeResult = processor.process(
      rawFrame: _sideFrame(
        frameIndex: 1,
        timestampMs: 100,
        startPoseValid: true,
      ),
      elapsed: const Duration(milliseconds: 100),
    );
    final lostVisibilityResult = processor.process(
      rawFrame: const PoseFrame(
        frameIndex: 2,
        timestampMs: 200,
        landmarks: {},
        derivedMetrics: {'start_pose_valid': 1},
      ),
      elapsed: const Duration(milliseconds: 200),
    );

    expect(activeResult.readiness.canStartTracking, isTrue);
    expect(lostVisibilityResult.readiness.state,
        isNot(ReadinessState.activeTracking));
    expect(lostVisibilityResult.readiness.canStartTracking, isFalse);
    expect(lostVisibilityResult.systemStatus, 'Get ready');
    expect(analyzeCalls, 2);
  });
}

PoseFrame _sideFrame({
  required int frameIndex,
  required int timestampMs,
  required bool startPoseValid,
}) {
  return PoseFrame(
    frameIndex: frameIndex,
    timestampMs: timestampMs,
    landmarks: const {
      Joint.leftShoulder: FrameLandmark(x: 0, y: 0, confidence: 1),
      Joint.leftHip: FrameLandmark(x: 0, y: 100, confidence: 1),
      Joint.leftKnee: FrameLandmark(x: 0, y: 180, confidence: 1),
      Joint.leftAnkle: FrameLandmark(x: 0, y: 260, confidence: 1),
    },
    derivedMetrics: {
      'start_pose_valid': startPoseValid ? 1 : 0,
    },
  );
}

PoseFrame _frontFrame({
  required int frameIndex,
  required int timestampMs,
  required double bodyWidth,
  required bool startPoseValid,
}) {
  return PoseFrame(
    frameIndex: frameIndex,
    timestampMs: timestampMs,
    landmarks: {
      Joint.leftShoulder: const FrameLandmark(x: 0, y: 0, confidence: 1),
      Joint.rightShoulder: FrameLandmark(x: bodyWidth, y: 0, confidence: 1),
      Joint.leftHip: const FrameLandmark(x: 0, y: 100, confidence: 1),
      Joint.rightHip: FrameLandmark(x: bodyWidth, y: 100, confidence: 1),
    },
    derivedMetrics: {
      'start_pose_valid': startPoseValid ? 1 : 0,
    },
  );
}
