import '../../models/workout_analysis.dart';
import '../exercise_profile.dart';
import '../pose_frame.dart';

class PushupProfile extends ExerciseProfile {
  static const double _enterDescentElbowAngle = 150;
  static const double _enterBottomElbowAngle = 100;
  static const double _exitBottomElbowAngle = 110;
  static const double _enterLockoutElbowAngle = 160;
  static const double _exitLockoutElbowAngle = 145;
  static const double _depthThresholdElbowAngle = 100;
  static const double _lockoutThresholdElbowAngle = 160;
  static const double _minBodyLineAngle = 165;
  static const double _hipSagOffsetThreshold = 0.14;
  static const double _pikeOffsetThreshold = -0.14;
  static const double _syncErrorThreshold = 0.35;
  static const double _headDropThreshold = 0.16;
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
          'min_body_line_angle': _minBodyLineAngle,
        },
        'phase_hip_offset': {
          'hip_sag_threshold': _hipSagOffsetThreshold,
          'pike_threshold': _pikeOffsetThreshold,
        },
        'phase_shoulder_hip_sync': {
          'max_sync_error': _syncErrorThreshold,
        },
        'phase_head_shoulder_drop': {
          'max_drop': _headDropThreshold,
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
    final hipOffset = frame.derivedMetrics['phase_hip_offset'];
    final headDrop = frame.derivedMetrics['phase_head_shoulder_drop'];
    final confidence = frame.derivedMetrics['avg_landmark_confidence'] ?? 1;

    if ((phase == MotionPhase.descent || phase == MotionPhase.bottom) &&
        (hipOffset != null
            ? hipOffset >= _hipSagOffsetThreshold
            : bodyLineAngle < _minBodyLineAngle)) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.hipSag,
          code: TechniqueIssue.hipSag.apiValue,
          message: 'Hips are sagging below the shoulder to ankle line.',
          metricName:
              hipOffset != null ? 'phase_hip_offset' : 'phase_body_line_angle',
          actualValue: hipOffset ?? bodyLineAngle,
          threshold:
              hipOffset != null ? _hipSagOffsetThreshold : _minBodyLineAngle,
          severity: IssueSeverity.major,
        ),
      );
    }

    if ((phase == MotionPhase.descent || phase == MotionPhase.bottom) &&
        hipOffset != null &&
        hipOffset <= _pikeOffsetThreshold) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.pikePosition,
          code: TechniqueIssue.pikePosition.apiValue,
          message: 'Lower hips into one straight shoulder to ankle line.',
          metricName: 'phase_hip_offset',
          actualValue: hipOffset,
          threshold: _pikeOffsetThreshold,
          severity: IssueSeverity.major,
        ),
      );
    }

    if ((phase == MotionPhase.descent || phase == MotionPhase.bottom) &&
        headDrop != null &&
        headDrop >= _headDropThreshold) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.headDropping,
          code: TechniqueIssue.headDropping.apiValue,
          message:
              'Keep your head aligned with the body instead of reaching down.',
          metricName: 'phase_head_shoulder_drop',
          actualValue: headDrop,
          threshold: _headDropThreshold,
          severity: IssueSeverity.moderate,
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
      'max_elbow_angle': _maxMetric(frames, 'phase_elbow_angle', fallback: 180),
      'min_body_line_angle':
          _minMetric(frames, 'phase_body_line_angle', fallback: 180),
      'max_hip_offset': _maxMetric(frames, 'phase_hip_offset', fallback: 0),
      'min_hip_offset': _minMetric(frames, 'phase_hip_offset', fallback: 0),
      'max_shoulder_hip_sync_error': _maxNormalizedSyncError(
        frames,
        firstMetricName: 'phase_shoulder_y',
        secondMetricName: 'phase_hip_y',
      ),
      'max_head_shoulder_drop':
          _maxMetric(frames, 'phase_head_shoulder_drop', fallback: 0),
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
    if (metrics['max_elbow_angle'] < _lockoutThresholdElbowAngle) {
      issues.add(TechniqueIssue.incompleteTopLockout);
    }
    if (metrics['max_hip_offset'] >= _hipSagOffsetThreshold ||
        metrics['min_body_line_angle'] < _minBodyLineAngle &&
            metrics['min_hip_offset'] >= 0) {
      issues.add(TechniqueIssue.hipSag);
    }
    if (metrics['min_hip_offset'] <= _pikeOffsetThreshold) {
      issues.add(TechniqueIssue.pikePosition);
    }
    if (metrics['max_shoulder_hip_sync_error'] > _syncErrorThreshold) {
      issues.add(TechniqueIssue.poorSynchronization);
    }
    if (metrics['max_head_shoulder_drop'] >= _headDropThreshold) {
      issues.add(TechniqueIssue.headDropping);
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
  required double fallback,
}) {
  if (frames.isEmpty) {
    return fallback;
  }
  return frames
      .map((frame) => frame.derivedMetrics[metricName] ?? fallback)
      .reduce((left, right) => left > right ? left : right);
}

double _maxNormalizedSyncError(
  List<PoseFrame> frames, {
  required String firstMetricName,
  required String secondMetricName,
}) {
  final pairedValues = frames
      .where((frame) =>
          frame.derivedMetrics.containsKey(firstMetricName) &&
          frame.derivedMetrics.containsKey(secondMetricName))
      .map(
        (frame) => (
          frame.derivedMetrics[firstMetricName]!,
          frame.derivedMetrics[secondMetricName]!,
        ),
      )
      .toList();

  if (pairedValues.length < 3) {
    return 0;
  }

  final firstValues = pairedValues.map((pair) => pair.$1);
  final secondValues = pairedValues.map((pair) => pair.$2);
  final firstMin =
      firstValues.reduce((left, right) => left < right ? left : right);
  final firstMax =
      firstValues.reduce((left, right) => left > right ? left : right);
  final secondMin =
      secondValues.reduce((left, right) => left < right ? left : right);
  final secondMax =
      secondValues.reduce((left, right) => left > right ? left : right);
  final firstRange = firstMax - firstMin;
  final secondRange = secondMax - secondMin;

  if (firstRange.abs() < 0.0001 || secondRange.abs() < 0.0001) {
    return 0;
  }

  return pairedValues.map((pair) {
    final firstProgress = (pair.$1 - firstMin) / firstRange;
    final secondProgress = (pair.$2 - secondMin) / secondRange;
    return (firstProgress - secondProgress).abs();
  }).reduce((left, right) => left > right ? left : right);
}
