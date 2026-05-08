import 'analysis_debug_info.dart';
import 'pose_frame.dart';
import 'pose_tracking_stabilizer.dart';
import 'readiness_evaluator.dart';
import 'workout_analyzer.dart';

typedef AnalyzeWorkoutFrame = WorkoutFrameResult Function(
  PoseFrame frame, {
  required ReadinessResult readiness,
});

class WorkoutFrameProcessor {
  WorkoutFrameProcessor({
    required this.readinessEvaluator,
    required this.analyzeFrame,
    Duration missingPoseTolerance = const Duration(milliseconds: 350),
  }) : _stabilizer = PoseTrackingStabilizer(
          missingPoseTolerance: missingPoseTolerance,
        );

  final ReadinessEvaluator readinessEvaluator;
  final AnalyzeWorkoutFrame analyzeFrame;
  final PoseTrackingStabilizer _stabilizer;

  WorkoutFrameResult process({
    required PoseFrame? rawFrame,
    required Duration elapsed,
  }) {
    // Feed the same stabilized frame into readiness and rep analysis so
    // start/stop gates and counted reps observe one consistent motion signal.
    final stabilizedFrame = _stabilizer.stabilize(
      frame: rawFrame,
      elapsed: elapsed,
    );
    final readiness = readinessEvaluator.evaluate(
      frame: stabilizedFrame,
      elapsedSeconds: elapsed.inSeconds,
    );
    if (stabilizedFrame == null) {
      final result = WorkoutFrameResult(
        readiness: readiness,
        systemStatus: readiness.blocker ??
            (readiness.canStartTracking ? 'Tracking active' : 'Get ready'),
      );
      return result.copyWith(
        debugInfo: AnalysisDebugInfo.fromFrameResult(
          readiness: result.readiness,
          systemStatus: result.systemStatus,
          metrics: const <String, double>{},
          frameIndex: null,
          timestampMs: elapsed.inMilliseconds,
          repUpdate: result.repUpdate,
        ),
      );
    }
    final result = analyzeFrame(
      stabilizedFrame,
      readiness: readiness,
    );
    return result.copyWith(
      debugInfo: AnalysisDebugInfo.fromFrameResult(
        readiness: result.readiness,
        systemStatus: result.systemStatus,
        metrics: Map<String, double>.from(stabilizedFrame.derivedMetrics),
        frameIndex: stabilizedFrame.frameIndex,
        timestampMs: stabilizedFrame.timestampMs,
        repUpdate: result.repUpdate,
      ),
    );
  }

  void reset() {
    _stabilizer.reset();
  }
}
