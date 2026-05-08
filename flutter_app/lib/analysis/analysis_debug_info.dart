import 'readiness_evaluator.dart';
import 'rep_analyzer.dart';

class AnalysisDebugInfo {
  final int? frameIndex;
  final int? timestampMs;
  final ReadinessState readinessState;
  final bool canStartTracking;
  final String? blocker;
  final String systemStatus;
  final Map<String, double> metrics;
  final String? stablePhase;
  final String? detectedPhase;
  final int repCount;
  final bool countIncremented;
  final bool hasActiveAttempt;
  final int? activeRepIndex;
  final int? activeRepFrameCount;
  final bool visitedTargetPhase;
  final int cooldownFramesRemaining;
  final int completionFrames;
  final String? pendingReason;

  const AnalysisDebugInfo({
    required this.frameIndex,
    required this.timestampMs,
    required this.readinessState,
    required this.canStartTracking,
    required this.blocker,
    required this.systemStatus,
    required this.metrics,
    required this.stablePhase,
    required this.detectedPhase,
    required this.repCount,
    required this.countIncremented,
    required this.hasActiveAttempt,
    required this.activeRepIndex,
    required this.activeRepFrameCount,
    required this.visitedTargetPhase,
    required this.cooldownFramesRemaining,
    required this.completionFrames,
    required this.pendingReason,
  });

  factory AnalysisDebugInfo.fromFrameResult({
    required ReadinessResult readiness,
    required String systemStatus,
    required Map<String, double> metrics,
    required int? frameIndex,
    required int? timestampMs,
    RepUpdate? repUpdate,
  }) {
    return AnalysisDebugInfo(
      frameIndex: frameIndex,
      timestampMs: timestampMs,
      readinessState: readiness.state,
      canStartTracking: readiness.canStartTracking,
      blocker: readiness.blocker,
      systemStatus: systemStatus,
      metrics: metrics,
      stablePhase: repUpdate?.phase.name,
      detectedPhase: repUpdate?.detectedPhase.name,
      repCount: repUpdate?.repCount ?? 0,
      countIncremented: repUpdate?.countIncremented ?? false,
      hasActiveAttempt: repUpdate?.hasActiveAttempt ?? false,
      activeRepIndex: repUpdate?.activeRepIndex,
      activeRepFrameCount: repUpdate?.activeRepFrameCount,
      visitedTargetPhase: repUpdate?.visitedTargetPhase ?? false,
      cooldownFramesRemaining: repUpdate?.cooldownFramesRemaining ?? 0,
      completionFrames: repUpdate?.completionFrames ?? 0,
      pendingReason: repUpdate?.pendingReason,
    );
  }

  String toLogLine() {
    final buffer = StringBuffer()
      ..write('frame=${frameIndex ?? -1}')
      ..write(' ts=${timestampMs ?? -1}')
      ..write(' readiness=${readinessState.name}')
      ..write(' tracking=$canStartTracking')
      ..write(' status="$systemStatus"');

    if (blocker != null && blocker!.isNotEmpty) {
      buffer.write(' blocker="$blocker"');
    }
    if (detectedPhase != null) {
      buffer.write(' phaseDetected=$detectedPhase');
    }
    if (stablePhase != null) {
      buffer.write(' phaseStable=$stablePhase');
    }

    buffer
      ..write(' reps=$repCount')
      ..write(' activeRep=$hasActiveAttempt');

    if (activeRepIndex != null) {
      buffer.write(' repIndex=$activeRepIndex');
    }
    if (activeRepFrameCount != null) {
      buffer.write(' repFrames=$activeRepFrameCount');
    }
    if (hasActiveAttempt) {
      buffer.write(' visitedTarget=$visitedTargetPhase');
    }
    if (completionFrames > 0) {
      buffer.write(' completionFrames=$completionFrames');
    }
    if (cooldownFramesRemaining > 0) {
      buffer.write(' cooldown=$cooldownFramesRemaining');
    }
    if (pendingReason != null && pendingReason!.isNotEmpty) {
      buffer.write(' pending=$pendingReason');
    }
    if (countIncremented) {
      buffer.write(' counted=true');
    }

    final interestingMetrics = metrics.entries
        .where(
          (entry) =>
              entry.key.startsWith('phase_') ||
              entry.key == 'avg_landmark_confidence' ||
              entry.key == 'start_pose_valid' ||
              entry.key == 'selected_side_right',
        )
        .toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    for (final entry in interestingMetrics) {
      buffer.write(' ${entry.key}=${entry.value.toStringAsFixed(1)}');
    }

    return buffer.toString();
  }
}
