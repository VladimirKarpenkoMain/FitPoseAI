import '../../models/workout_analysis.dart';
import '../exercise_profile.dart';
import '../pose_frame.dart';

class PushupProfile extends ExerciseProfile {
  static const double _enterDescentElbowAngle = 150;
  static const double _enterBottomElbowAngle = 100;
  static const double _exitBottomElbowAngle = 110;
  static const double _enterLockoutElbowAngle = 160;
  static const double _exitLockoutElbowAngle = 145;
  static const double _depthThresholdElbowAngle = 95;
  static const double _hipSagBodyLineThreshold = 165;
  static const double _lowConfidenceThreshold = 0.45;

  @override
  String get id => 'pushup';

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
        'phase_elbow_angle': {
          'enter_descent': _enterDescentElbowAngle,
          'enter_bottom': _enterBottomElbowAngle,
          'exit_bottom': _exitBottomElbowAngle,
          'enter_lockout': _enterLockoutElbowAngle,
          'exit_lockout': _exitLockoutElbowAngle,
          'depth_target': _depthThresholdElbowAngle,
        },
        'phase_body_line_angle': {
          'hip_sag_threshold': _hipSagBodyLineThreshold,
        },
      };

  @override
  MotionPhase detectPhase(PoseFrame frame, MotionPhase previous) {
    final elbowAngle = frame.derivedMetrics['phase_elbow_angle'] ?? 180;

    switch (previous) {
      case MotionPhase.bottom:
        if (elbowAngle <= _exitBottomElbowAngle) {
          return MotionPhase.bottom;
        }
        if (elbowAngle >= _enterLockoutElbowAngle) {
          return MotionPhase.lockout;
        }
        return MotionPhase.descent;
      case MotionPhase.lockout:
        if (elbowAngle >= _exitLockoutElbowAngle) {
          return MotionPhase.lockout;
        }
        if (elbowAngle <= _enterBottomElbowAngle) {
          return MotionPhase.bottom;
        }
        if (elbowAngle < _enterDescentElbowAngle) {
          return MotionPhase.descent;
        }
        return MotionPhase.lockout;
      default:
        if (elbowAngle <= _enterBottomElbowAngle) {
          return MotionPhase.bottom;
        }
        if (elbowAngle >= _enterLockoutElbowAngle) {
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
    final bodyLineAngle = frame.derivedMetrics['phase_body_line_angle'] ?? 180;
    final confidence = frame.derivedMetrics['avg_landmark_confidence'] ?? 1;

    if ((phase == MotionPhase.descent || phase == MotionPhase.bottom) &&
        bodyLineAngle < _hipSagBodyLineThreshold) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.hipSag,
          code: TechniqueIssue.hipSag.apiValue,
          message: 'Hips are sagging below the shoulder to ankle line.',
          metricName: 'phase_body_line_angle',
          actualValue: bodyLineAngle,
          threshold: _hipSagBodyLineThreshold,
          severity: IssueSeverity.major,
        ),
      );
    }

    if (confidence < _lowConfidenceThreshold) {
      issues.add(
        LiveIssueTrigger(
          code: 'low_confidence_landmarks',
          message:
              'Low landmark confidence may reduce push-up analysis accuracy.',
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
      'min_elbow_angle': _minMetric(frames, 'phase_elbow_angle', fallback: 180),
      'min_body_line_angle':
          _minMetric(frames, 'phase_body_line_angle', fallback: 180),
      'min_elbow_symmetry':
          _minMetric(frames, 'phase_elbow_symmetry', fallback: 0),
    });
  }

  @override
  List<TechniqueIssue> detectFinalIssues(RepMetricBundle metrics) {
    final issues = <TechniqueIssue>[];
    if (metrics['min_elbow_angle'] > _depthThresholdElbowAngle) {
      issues.add(TechniqueIssue.insufficientDepth);
    }
    if (metrics['min_body_line_angle'] < _hipSagBodyLineThreshold) {
      issues.add(TechniqueIssue.hipSag);
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
