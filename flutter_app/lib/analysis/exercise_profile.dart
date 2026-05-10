import '../models/workout_analysis.dart';
import 'pose_frame.dart';

class RepMetricBundle {
  final Map<String, double> values;

  const RepMetricBundle(this.values);

  double operator [](String key) => values[key] ?? 0;
}

class RepTrackingConfig {
  final MotionPhase startPhase;
  final Set<MotionPhase> targetPhases;
  final Set<MotionPhase> finishPhases;
  final int phaseDwellFrames;
  final int minRepFrames;
  final int completionDebounceFrames;
  final int completionCooldownFrames;
  final int duplicateIssueCooldownFrames;

  const RepTrackingConfig({
    required this.startPhase,
    required this.targetPhases,
    required this.finishPhases,
    required this.phaseDwellFrames,
    required this.minRepFrames,
    required this.completionDebounceFrames,
    required this.completionCooldownFrames,
    required this.duplicateIssueCooldownFrames,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_phase': startPhase.name,
      'target_phases': targetPhases.map((phase) => phase.name).toList(),
      'finish_phases': finishPhases.map((phase) => phase.name).toList(),
      'phase_dwell_frames': phaseDwellFrames,
      'min_rep_frames': minRepFrames,
      'completion_debounce_frames': completionDebounceFrames,
      'completion_cooldown_frames': completionCooldownFrames,
      'duplicate_issue_cooldown_frames': duplicateIssueCooldownFrames,
    };
  }
}

class LiveIssueTrigger {
  final TechniqueIssue? issue;
  final String code;
  final String message;
  final String metricName;
  final double actualValue;
  final double threshold;
  final IssueSeverity severity;

  const LiveIssueTrigger({
    this.issue,
    required this.code,
    required this.message,
    required this.metricName,
    required this.actualValue,
    required this.threshold,
    required this.severity,
  });
}

abstract class ExerciseProfile {
  String get id;
  bool get isHoldBased => false;
  ExerciseView get requiredView;
  RepTrackingConfig get trackingConfig;
  Map<String, dynamic> get thresholds;

  MotionPhase detectPhase(PoseFrame frame, MotionPhase previous);

  Map<String, double> captureFrameMetrics(PoseFrame frame) {
    return Map<String, double>.from(frame.derivedMetrics);
  }

  List<LiveIssueTrigger> detectLiveIssues({
    required PoseFrame frame,
    required MotionPhase phase,
  });

  RepMetricBundle summarizeRep(List<PoseFrame> frames);

  List<TechniqueIssue> detectFinalIssues(RepMetricBundle metrics);
}
