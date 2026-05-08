import '../../models/workout_analysis.dart';
import '../exercise_profile.dart';
import '../pose_frame.dart';

class JumpingJackProfile extends ExerciseProfile {
  static const double _enterOpeningArmAngle = 45;
  static const double _enterOpeningLegAngle = 22;
  static const double _enterOpenArmAngle = 140;
  static const double _enterOpenLegAngle = 40;
  static const double _exitOpenArmAngle = 125;
  static const double _exitOpenLegAngle = 35;
  static const double _enterClosedArmAngle = 35;
  static const double _enterClosedLegAngle = 18;
  static const double _armOpenTarget = 150;
  static const double _legOpenTarget = 45;
  static const double _syncGapThreshold = 0.35;
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
        'phase_sync_gap': {
          'poor_sync_threshold': _syncGapThreshold,
        },
      };

  @override
  MotionPhase detectPhase(PoseFrame frame, MotionPhase previous) {
    final armOpen = frame.derivedMetrics['phase_arm_open'] ?? 0;
    final legOpen = frame.derivedMetrics['phase_leg_open'] ?? 0;

    switch (previous) {
      case MotionPhase.open:
        if (armOpen >= _exitOpenArmAngle && legOpen >= _exitOpenLegAngle) {
          return MotionPhase.open;
        }
        if (armOpen < _enterClosedArmAngle && legOpen < _enterClosedLegAngle) {
          return MotionPhase.closed;
        }
        return MotionPhase.closing;
      case MotionPhase.closed:
        if (armOpen > _enterOpenArmAngle && legOpen > _enterOpenLegAngle) {
          return MotionPhase.open;
        }
        if (armOpen > _enterOpeningArmAngle ||
            legOpen > _enterOpeningLegAngle) {
          return MotionPhase.opening;
        }
        return MotionPhase.closed;
      default:
        if (armOpen > _enterOpenArmAngle && legOpen > _enterOpenLegAngle) {
          return MotionPhase.open;
        }
        if (armOpen < _enterClosedArmAngle && legOpen < _enterClosedLegAngle) {
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
    final confidence = frame.derivedMetrics['avg_landmark_confidence'] ?? 1;

    if ((phase == MotionPhase.opening ||
            phase == MotionPhase.open ||
            phase == MotionPhase.closing) &&
        syncGap > _syncGapThreshold) {
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
    return RepMetricBundle({
      'max_arm_open': _maxMetric(frames, 'phase_arm_open'),
      'max_leg_open': _maxMetric(frames, 'phase_leg_open'),
      'max_sync_gap': _maxMetric(frames, 'phase_sync_gap'),
    });
  }

  @override
  List<TechniqueIssue> detectFinalIssues(RepMetricBundle metrics) {
    final issues = <TechniqueIssue>[];
    if (metrics['max_arm_open'] < _armOpenTarget) {
      issues.add(TechniqueIssue.armsIncompleteOverhead);
    }
    if (metrics['max_leg_open'] < _legOpenTarget) {
      issues.add(TechniqueIssue.legsNotWideEnough);
    }
    if (metrics['max_sync_gap'] > _syncGapThreshold) {
      issues.add(TechniqueIssue.poorSynchronization);
    }
    return issues;
  }
}

double _maxMetric(List<PoseFrame> frames, String metricName) {
  if (frames.isEmpty) {
    return 0;
  }
  return frames
      .map((frame) => frame.derivedMetrics[metricName] ?? 0)
      .reduce((left, right) => left > right ? left : right);
}
