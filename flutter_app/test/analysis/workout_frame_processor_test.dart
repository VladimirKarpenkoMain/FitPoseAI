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
}
