import '../../models/workout_analysis.dart';
import '../exercise_profile.dart';
import '../pose_frame.dart';

class JumpingJackProfile extends ExerciseProfile {
  static const double _enterOpeningArmAngle = 45;
  static const double _enterOpeningLegAngle = 22;
  static const double _enterOpeningFeetWidthRatio = 0.85;
  static const double _enterOpenArmAngle = 140;
  static const double _enterOpenLegAngle = 40;
  static const double _enterOpenFeetWidthRatio = 1.25;
  static const double _exitOpenArmAngle = 125;
  static const double _exitOpenLegAngle = 35;
  static const double _exitOpenFeetWidthRatio = 1.15;
  static const double _enterClosedArmAngle = 35;
  static const double _enterClosedLegAngle = 18;
  static const double _enterClosedFeetRatio = 1.2;
  static const double _armOpenTarget = 150;
  static const double _legOpenTarget = 45;
  static const double _feetWidthTarget = 1.3;
  static const double _syncGapThreshold = 0.35;
  static const double _peakSyncGapMsThreshold = 350;
  static const double _torsoTiltThreshold = 15;
  static const double _asymmetryThreshold = 0.35;
  static const double _lowConfidenceThreshold = 0.45;

  @override
  String get id => 'jumping_jack';

  @override
  ExerciseView get requiredView => ExerciseView.front;

  @override
  RepTrackingConfig get trackingConfig => const RepTrackingConfig(
        startPhase: MotionPhase.closed,
        targetPhases: {MotionPhase.open},
        finishPhases: {MotionPhase.closed},
        phaseDwellFrames: 2,
        minRepFrames: 8,
        completionDebounceFrames: 2,
        completionCooldownFrames: 5,
        duplicateIssueCooldownFrames: 6,
      );

  @override
  Map<String, dynamic> get thresholds => {
        ...trackingConfig.toJson(),
        'phase_arm_open': {
          'enter_opening': _enterOpeningArmAngle,
          'enter_open': _enterOpenArmAngle,
          'exit_open': _exitOpenArmAngle,
          'enter_closed': _enterClosedArmAngle,
          'target': _armOpenTarget,
        },
        'phase_leg_open': {
          'enter_opening': _enterOpeningLegAngle,
          'enter_open': _enterOpenLegAngle,
          'exit_open': _exitOpenLegAngle,
          'enter_closed': _enterClosedLegAngle,
          'target': _legOpenTarget,
        },
        'phase_feet_width_ratio': {
          'enter_opening': _enterOpeningFeetWidthRatio,
          'enter_open': _enterOpenFeetWidthRatio,
          'exit_open': _exitOpenFeetWidthRatio,
          'target': _feetWidthTarget,
        },
        'phase_feet_closed_ratio': {
          'enter_closed': _enterClosedFeetRatio,
        },
        'phase_torso_side_tilt': {
          'max_good': _torsoTiltThreshold,
        },
        'phase_left_right_asymmetry': {
          'max_good': _asymmetryThreshold,
        },
        'phase_sync_gap': {
          'poor_sync_threshold': _syncGapThreshold,
          'poor_peak_gap_ms': _peakSyncGapMsThreshold,
        },
      };

  @override
  MotionPhase detectPhase(PoseFrame frame, MotionPhase previous) {
    final armOpen = frame.derivedMetrics['phase_arm_open'] ?? 0;
    final feetOpen = _feetOpenValue(frame);

    switch (previous) {
      case MotionPhase.open:
        if (armOpen >= _exitOpenArmAngle &&
            _feetIsOpen(
              feetOpen,
              ratioThreshold: _exitOpenFeetWidthRatio,
              legacyAngleThreshold: _exitOpenLegAngle,
            )) {
          return MotionPhase.open;
        }
        if (armOpen < _enterClosedArmAngle && _feetIsClosed(frame)) {
          return MotionPhase.closed;
        }
        return MotionPhase.closing;
      case MotionPhase.closed:
        if (armOpen > _enterOpenArmAngle &&
            _feetIsOpen(
              feetOpen,
              ratioThreshold: _enterOpenFeetWidthRatio,
              legacyAngleThreshold: _enterOpenLegAngle,
            )) {
          return MotionPhase.open;
        }
        if (armOpen > _enterOpeningArmAngle ||
            _feetIsOpen(
              feetOpen,
              ratioThreshold: _enterOpeningFeetWidthRatio,
              legacyAngleThreshold: _enterOpeningLegAngle,
            )) {
          return MotionPhase.opening;
        }
        return MotionPhase.closed;
      default:
        if (armOpen > _enterOpenArmAngle &&
            _feetIsOpen(
              feetOpen,
              ratioThreshold: _enterOpenFeetWidthRatio,
              legacyAngleThreshold: _enterOpenLegAngle,
            )) {
          return MotionPhase.open;
        }
        if (armOpen < _enterClosedArmAngle && _feetIsClosed(frame)) {
          return MotionPhase.closed;
        }
        return previous == MotionPhase.closing
            ? MotionPhase.closing
            : MotionPhase.opening;
    }
  }

  @override
  List<LiveIssueTrigger> detectLiveIssues({
    required PoseFrame frame,
    required MotionPhase phase,
  }) {
    final issues = <LiveIssueTrigger>[];
    final syncGap = frame.derivedMetrics['phase_sync_gap'] ?? 0;
    final torsoTilt = frame.derivedMetrics['phase_torso_side_tilt'] ?? 0;
    final asymmetry = _frameAsymmetry(frame);
    final confidence = frame.derivedMetrics['avg_landmark_confidence'] ?? 1;
    final isMoving = phase == MotionPhase.opening ||
        phase == MotionPhase.open ||
        phase == MotionPhase.closing;

    if (isMoving && syncGap > _syncGapThreshold) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.poorSynchronization,
          code: TechniqueIssue.poorSynchronization.apiValue,
          message: 'Arms and legs are opening at noticeably different speeds.',
          metricName: 'phase_sync_gap',
          actualValue: syncGap,
          threshold: _syncGapThreshold,
          severity: IssueSeverity.minor,
        ),
      );
    }

    if (isMoving && torsoTilt > _torsoTiltThreshold) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.unstablePosition,
          code: TechniqueIssue.unstablePosition.apiValue,
          message: 'Keep your torso upright without swaying side to side.',
          metricName: 'phase_torso_side_tilt',
          actualValue: torsoTilt,
          threshold: _torsoTiltThreshold,
          severity: IssueSeverity.minor,
        ),
      );
    }

    if (isMoving && asymmetry > _asymmetryThreshold) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.leftRightAsymmetry,
          code: TechniqueIssue.leftRightAsymmetry.apiValue,
          message: 'Move both sides evenly through the jumping jack.',
          metricName: 'phase_left_right_asymmetry',
          actualValue: asymmetry,
          threshold: _asymmetryThreshold,
          severity: IssueSeverity.minor,
        ),
      );
    }

    if (confidence < _lowConfidenceThreshold) {
      issues.add(
        LiveIssueTrigger(
          code: 'low_confidence_landmarks',
          message:
              'Low landmark confidence may reduce jumping jack analysis accuracy.',
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
    final hasFeetWidthRatio = _hasMetric(frames, 'phase_feet_width_ratio');
    final feetMetricName =
        hasFeetWidthRatio ? 'phase_feet_width_ratio' : 'phase_leg_open';
    final armPeakTime = _timestampAtMaxMetric(frames, 'phase_arm_open');
    final feetPeakTime = _timestampAtMaxMetric(frames, feetMetricName);

    return RepMetricBundle({
      'max_arm_open': _maxMetric(frames, 'phase_arm_open'),
      'max_feet_width_ratio': _maxMetric(frames, 'phase_feet_width_ratio'),
      'max_leg_open': _maxMetric(frames, 'phase_leg_open'),
      'max_sync_gap': _maxMetric(frames, 'phase_sync_gap'),
      'has_feet_width_ratio': hasFeetWidthRatio ? 1 : 0,
      'arm_peak_timestamp_ms': armPeakTime,
      'feet_peak_timestamp_ms': feetPeakTime,
      'peak_sync_gap_ms': (armPeakTime - feetPeakTime).abs(),
      'max_torso_side_tilt': _maxMetric(frames, 'phase_torso_side_tilt'),
      'max_left_right_asymmetry': _maxFrameValue(frames, _frameAsymmetry),
    });
  }

  @override
  List<TechniqueIssue> detectFinalIssues(RepMetricBundle metrics) {
    final issues = <TechniqueIssue>[];
    if (metrics['max_arm_open'] < _armOpenTarget) {
      issues.add(TechniqueIssue.armsIncompleteOverhead);
    }
    final hasFeetWidthRatio = metrics['has_feet_width_ratio'] >= 0.5;
    final legsNotWideEnough = hasFeetWidthRatio
        ? metrics['max_feet_width_ratio'] < _feetWidthTarget
        : metrics['max_leg_open'] < _legOpenTarget;
    if (legsNotWideEnough) {
      issues.add(TechniqueIssue.legsNotWideEnough);
    }
    if (metrics['peak_sync_gap_ms'] > _peakSyncGapMsThreshold ||
        metrics['max_sync_gap'] > _syncGapThreshold) {
      issues.add(TechniqueIssue.poorSynchronization);
    }
    if (metrics['max_torso_side_tilt'] > _torsoTiltThreshold) {
      issues.add(TechniqueIssue.unstablePosition);
    }
    if (metrics['max_left_right_asymmetry'] > _asymmetryThreshold) {
      issues.add(TechniqueIssue.leftRightAsymmetry);
    }
    return issues;
  }
}

({double value, bool usesRatio}) _feetOpenValue(PoseFrame frame) {
  final feetWidthRatio = frame.derivedMetrics['phase_feet_width_ratio'];
  if (feetWidthRatio != null) {
    return (value: feetWidthRatio, usesRatio: true);
  }
  return (
    value: frame.derivedMetrics['phase_leg_open'] ?? 0,
    usesRatio: false,
  );
}

bool _feetIsOpen(
  ({double value, bool usesRatio}) feetOpen, {
  required double ratioThreshold,
  required double legacyAngleThreshold,
}) {
  return feetOpen.usesRatio
      ? feetOpen.value >= ratioThreshold
      : feetOpen.value >= legacyAngleThreshold;
}

bool _feetIsClosed(PoseFrame frame) {
  final feetClosedRatio = frame.derivedMetrics['phase_feet_closed_ratio'];
  if (feetClosedRatio != null) {
    return feetClosedRatio <= JumpingJackProfile._enterClosedFeetRatio;
  }
  return (frame.derivedMetrics['phase_leg_open'] ?? 0) <
      JumpingJackProfile._enterClosedLegAngle;
}

double _maxMetric(List<PoseFrame> frames, String metricName) {
  if (frames.isEmpty) {
    return 0;
  }
  return frames
      .map((frame) => frame.derivedMetrics[metricName] ?? 0)
      .reduce((left, right) => left > right ? left : right);
}

bool _hasMetric(List<PoseFrame> frames, String metricName) {
  return frames.any((frame) => frame.derivedMetrics.containsKey(metricName));
}

double _timestampAtMaxMetric(List<PoseFrame> frames, String metricName) {
  if (frames.isEmpty) {
    return 0;
  }

  PoseFrame? peakFrame;
  double? peakValue;
  for (final frame in frames) {
    final value = frame.derivedMetrics[metricName];
    if (value == null) {
      continue;
    }
    if (peakValue == null || value > peakValue) {
      peakValue = value;
      peakFrame = frame;
    }
  }
  return peakFrame?.timestampMs.toDouble() ?? 0;
}

double _maxFrameValue(
  List<PoseFrame> frames,
  double Function(PoseFrame frame) valueForFrame,
) {
  if (frames.isEmpty) {
    return 0;
  }
  return frames
      .map(valueForFrame)
      .reduce((left, right) => left > right ? left : right);
}

double _frameAsymmetry(PoseFrame frame) {
  final combined = frame.derivedMetrics['phase_left_right_asymmetry'];
  if (combined != null) {
    return combined;
  }

  final wrist = frame.derivedMetrics['phase_wrist_height_asymmetry'] ?? 0;
  final ankle = frame.derivedMetrics['phase_ankle_spread_asymmetry'] ?? 0;
  return wrist > ankle ? wrist : ankle;
}
