import '../../models/workout_analysis.dart';
import '../exercise_profile.dart';
import '../pose_frame.dart';

class SquatProfile extends ExerciseProfile {
  static const double _enterDescentKneeAngle = 150;
  static const double _enterBottomKneeAngle = 115;
  static const double _exitBottomKneeAngle = 125;
  static const double _enterLockoutKneeAngle = 165;
  static const double _exitLockoutKneeAngle = 150;
  static const double _depthThresholdKneeAngle = 100;
  static const double _forwardLeanThreshold = 35;
  static const double _lowConfidenceThreshold = 0.45;

  @override
  String get id => 'squat';

  @override
  ExerciseView get requiredView => ExerciseView.side;

  @override
  RepTrackingConfig get trackingConfig => const RepTrackingConfig(
        startPhase: MotionPhase.lockout,
        targetPhases: {MotionPhase.bottom},
        finishPhases: {MotionPhase.lockout},
        phaseDwellFrames: 2,
        minRepFrames: 8,
        completionDebounceFrames: 2,
        completionCooldownFrames: 5,
        duplicateIssueCooldownFrames: 6,
      );

  @override
  Map<String, dynamic> get thresholds => {
        ...trackingConfig.toJson(),
        'phase_knee_angle': {
          'enter_descent': _enterDescentKneeAngle,
          'enter_bottom': _enterBottomKneeAngle,
          'exit_bottom': _exitBottomKneeAngle,
          'enter_lockout': _enterLockoutKneeAngle,
          'exit_lockout': _exitLockoutKneeAngle,
          'depth_target': _depthThresholdKneeAngle,
        },
        'phase_torso_vertical_tilt': {
          'forward_lean_threshold': _forwardLeanThreshold,
        },
      };

  @override
  MotionPhase detectPhase(PoseFrame frame, MotionPhase previous) {
    final kneeAngle = frame.derivedMetrics['phase_knee_angle'] ?? 180;

    switch (previous) {
      case MotionPhase.bottom:
        if (kneeAngle <= _exitBottomKneeAngle) {
          return MotionPhase.bottom;
        }
        if (kneeAngle >= _enterLockoutKneeAngle) {
          return MotionPhase.lockout;
        }
        return MotionPhase.descent;
      case MotionPhase.lockout:
        if (kneeAngle >= _exitLockoutKneeAngle) {
          return MotionPhase.lockout;
        }
        if (kneeAngle <= _enterBottomKneeAngle) {
          return MotionPhase.bottom;
        }
        if (kneeAngle < _enterDescentKneeAngle) {
          return MotionPhase.descent;
        }
        return MotionPhase.lockout;
      default:
        if (kneeAngle <= _enterBottomKneeAngle) {
          return MotionPhase.bottom;
        }
        if (kneeAngle >= _enterLockoutKneeAngle) {
          return MotionPhase.lockout;
        }
        return MotionPhase.descent;
    }
  }

  @override
  List<LiveIssueTrigger> detectLiveIssues({
    required PoseFrame frame,
    required MotionPhase phase,
  }) {
    final issues = <LiveIssueTrigger>[];
    final torsoTilt = frame.derivedMetrics['phase_torso_vertical_tilt'] ??
        frame.derivedMetrics['phase_torso_lean'] ??
        0;
    final confidence = frame.derivedMetrics['avg_landmark_confidence'] ?? 1;

    if ((phase == MotionPhase.descent || phase == MotionPhase.bottom) &&
        torsoTilt > _forwardLeanThreshold) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.excessiveForwardLean,
          code: TechniqueIssue.excessiveForwardLean.apiValue,
          message: 'Torso leaned too far forward during the squat.',
          metricName: 'phase_torso_vertical_tilt',
          actualValue: torsoTilt,
          threshold: _forwardLeanThreshold,
          severity: IssueSeverity.moderate,
        ),
      );
    }

    if (confidence < _lowConfidenceThreshold) {
      issues.add(
        LiveIssueTrigger(
          code: 'low_confidence_landmarks',
          message:
              'Low landmark confidence may reduce squat analysis accuracy.',
          metricName: 'avg_landmark_confidence',
          actualValue: confidence,
          threshold: _lowConfidenceThreshold,
          severity: IssueSeverity.minor,
        ),
      );
    }

    return issues;
  }

  @override
  RepMetricBundle summarizeRep(List<PoseFrame> frames) {
    return RepMetricBundle({
      'min_knee_angle': _minMetric(frames, 'phase_knee_angle', fallback: 180),
      'min_hip_angle': _minMetric(frames, 'phase_hip_angle', fallback: 180),
      'max_torso_vertical_tilt': _maxMetric(
        frames,
        'phase_torso_vertical_tilt',
        fallbackMetric: 'phase_torso_lean',
      ),
      'avg_torso_vertical_tilt': _avgMetric(
        frames,
        'phase_torso_vertical_tilt',
        fallbackMetric: 'phase_torso_lean',
      ),
      'min_knee_symmetry':
          _minMetric(frames, 'phase_knee_symmetry', fallback: 0),
    });
  }

  @override
  List<TechniqueIssue> detectFinalIssues(RepMetricBundle metrics) {
    final issues = <TechniqueIssue>[];
    if (metrics['min_knee_angle'] > _depthThresholdKneeAngle) {
      issues.add(TechniqueIssue.depthTooShallow);
    }
    if (metrics['max_torso_vertical_tilt'] > _forwardLeanThreshold) {
      issues.add(TechniqueIssue.excessiveForwardLean);
    }
    return issues;
  }
}

double _minMetric(
  List<PoseFrame> frames,
  String metricName, {
  required double fallback,
}) {
  if (frames.isEmpty) {
    return fallback;
  }
  return frames
      .map((frame) => frame.derivedMetrics[metricName] ?? fallback)
      .reduce((left, right) => left < right ? left : right);
}

double _maxMetric(
  List<PoseFrame> frames,
  String metricName, {
  String? fallbackMetric,
}) {
  if (frames.isEmpty) {
    return 0;
  }
  return frames
      .map(
        (frame) =>
            frame.derivedMetrics[metricName] ??
            (fallbackMetric == null
                ? 0
                : frame.derivedMetrics[fallbackMetric] ?? 0),
      )
      .reduce((left, right) => left > right ? left : right);
}

double _avgMetric(
  List<PoseFrame> frames,
  String metricName, {
  String? fallbackMetric,
}) {
  if (frames.isEmpty) {
    return 0;
  }
  final values = frames
      .map(
        (frame) =>
            frame.derivedMetrics[metricName] ??
            (fallbackMetric == null
                ? 0
                : frame.derivedMetrics[fallbackMetric] ?? 0),
      )
      .toList();
  return values.reduce((left, right) => left + right) / values.length;
}
