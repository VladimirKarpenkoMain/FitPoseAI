import '../../models/workout_analysis.dart';
import '../exercise_profile.dart';
import '../pose_frame.dart';

class ShoulderPressProfile extends ExerciseProfile {
  static const double _enterPressingShoulderAngle = 110;
  static const double _enterLockoutShoulderAngle = 150;
  static const double _exitLockoutShoulderAngle = 135;
  static const double _enterLoweredShoulderAngle = 100;
  static const double _extensionTargetElbowAngle = 160;
  static const double _lockoutElbowAngle = 150;
  static const double _shoulderTargetAngle = 150;
  static const double _wristTargetAngle = 150;
  static const double _torsoLeanThreshold = 15;
  static const double _strictKneeChangeThreshold = 20;
  static const double _kneeDriveDipThreshold = 160;
  static const double _liveKneeDriveThreshold = 155;
  static const double _handForwardOffsetThreshold = 0.18;
  static const double _armSymmetryThreshold = 15;
  static const double _wristHeightSymmetryThreshold = 0.05;
  static const double _lowConfidenceThreshold = 0.45;

  @override
  String get id => 'shoulder_press';

  @override
  ExerciseView get requiredView => ExerciseView.side;

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
        'phase_shoulder_angle': {
          'enter_pressing': _enterPressingShoulderAngle,
          'enter_lockout': _enterLockoutShoulderAngle,
          'exit_lockout': _exitLockoutShoulderAngle,
          'enter_lowered': _enterLoweredShoulderAngle,
          'target': _shoulderTargetAngle,
        },
        'phase_elbow_angle': {
          'extension_target': _extensionTargetElbowAngle,
          'lockout_target': _lockoutElbowAngle,
        },
        'phase_wrist_above_shoulder': {
          'target': 1,
        },
        'phase_wrist_angle': {
          'target': _wristTargetAngle,
        },
        'phase_torso_angle_from_vertical': {
          'max_good': _torsoLeanThreshold,
        },
        'phase_knee_angle': {
          'live_min': _liveKneeDriveThreshold,
          'drive_min': _kneeDriveDipThreshold,
          'max_change': _strictKneeChangeThreshold,
        },
        'phase_hand_forward_offset': {
          'max_good': _handForwardOffsetThreshold,
        },
        'phase_vertical_stack_offset': {
          'max_good': _handForwardOffsetThreshold,
        },
        'phase_left_right_symmetry': {
          'max_good': _armSymmetryThreshold,
        },
        'phase_wrist_height_asymmetry': {
          'max_good': _wristHeightSymmetryThreshold,
        },
      };

  @override
  MotionPhase detectPhase(PoseFrame frame, MotionPhase previous) {
    final shoulderAngle = frame.derivedMetrics['phase_shoulder_angle'] ?? 0;
    final elbowAngle = frame.derivedMetrics['phase_elbow_angle'] ?? 180;
    final wristAboveShoulder =
        frame.derivedMetrics['phase_wrist_above_shoulder'] ?? 1;
    final isLockout = shoulderAngle >= _enterLockoutShoulderAngle &&
        elbowAngle >= _lockoutElbowAngle &&
        wristAboveShoulder >= 1;

    switch (previous) {
      case MotionPhase.open:
        if (shoulderAngle >= _exitLockoutShoulderAngle) {
          return MotionPhase.open;
        }
        if (shoulderAngle <= _enterLoweredShoulderAngle) {
          return MotionPhase.closed;
        }
        return MotionPhase.closing;
      case MotionPhase.closed:
        if (isLockout) {
          return MotionPhase.open;
        }
        if (shoulderAngle > _enterPressingShoulderAngle) {
          return MotionPhase.opening;
        }
        return MotionPhase.closed;
      case MotionPhase.closing:
        if (shoulderAngle <= _enterLoweredShoulderAngle) {
          return MotionPhase.closed;
        }
        return MotionPhase.closing;
      default:
        if (isLockout) {
          return MotionPhase.open;
        }
        if (shoulderAngle <= _enterLoweredShoulderAngle) {
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
    final elbowAngle = frame.derivedMetrics['phase_elbow_angle'] ?? 180;
    final shoulderAngle = frame.derivedMetrics['phase_shoulder_angle'] ?? 0;
    final wristAboveShoulder =
        frame.derivedMetrics['phase_wrist_above_shoulder'] ?? 1;
    final torsoLean =
        frame.derivedMetrics['phase_torso_angle_from_vertical'] ?? 0;
    final kneeAngle = frame.derivedMetrics['phase_knee_angle'] ?? 180;
    final handForwardOffset =
        frame.derivedMetrics['phase_hand_forward_offset'] ?? 0;
    final verticalStackOffset =
        frame.derivedMetrics['phase_vertical_stack_offset'] ?? 0;
    final wristAngle = frame.derivedMetrics['phase_wrist_angle'] ?? 180;
    final bilateralArmMetrics =
        frame.derivedMetrics['phase_bilateral_arm_metrics'] ?? 0;
    final armSymmetry = frame.derivedMetrics['phase_left_right_symmetry'] ?? 0;
    final wristHeightSymmetry =
        frame.derivedMetrics['phase_wrist_height_asymmetry'] ?? 0;
    final confidence = frame.derivedMetrics['avg_landmark_confidence'] ?? 1;
    final isPressing = phase == MotionPhase.opening ||
        phase == MotionPhase.open ||
        phase == MotionPhase.closing;

    if (isPressing && torsoLean > _torsoLeanThreshold) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.excessiveBackLean,
          code: TechniqueIssue.excessiveBackLean.apiValue,
          message: 'Keep ribs down and avoid leaning back.',
          metricName: 'phase_torso_angle_from_vertical',
          actualValue: torsoLean,
          threshold: _torsoLeanThreshold,
          severity: IssueSeverity.moderate,
        ),
      );
    }

    if (isPressing && kneeAngle < _liveKneeDriveThreshold) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.kneeDrive,
          code: TechniqueIssue.kneeDrive.apiValue,
          message: 'Keep knees quiet for a strict press.',
          metricName: 'phase_knee_angle',
          actualValue: kneeAngle,
          threshold: _liveKneeDriveThreshold,
          severity: IssueSeverity.moderate,
        ),
      );
    }

    if (isPressing &&
        (handForwardOffset > _handForwardOffsetThreshold ||
            verticalStackOffset > _handForwardOffsetThreshold)) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.dumbbellsForward,
          code: TechniqueIssue.dumbbellsForward.apiValue,
          message: 'Keep dumbbells over your shoulders.',
          metricName: 'phase_hand_forward_offset',
          actualValue: handForwardOffset > verticalStackOffset
              ? handForwardOffset
              : verticalStackOffset,
          threshold: _handForwardOffsetThreshold,
          severity: IssueSeverity.moderate,
        ),
      );
    }

    if (isPressing &&
        bilateralArmMetrics >= 1 &&
        (armSymmetry > _armSymmetryThreshold ||
            wristHeightSymmetry > _wristHeightSymmetryThreshold)) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.asymmetry,
          code: TechniqueIssue.asymmetry.apiValue,
          message: 'Press both dumbbells evenly.',
          metricName: armSymmetry > _armSymmetryThreshold
              ? 'phase_left_right_symmetry'
              : 'phase_wrist_height_asymmetry',
          actualValue: armSymmetry > _armSymmetryThreshold
              ? armSymmetry
              : wristHeightSymmetry,
          threshold: armSymmetry > _armSymmetryThreshold
              ? _armSymmetryThreshold
              : _wristHeightSymmetryThreshold,
          severity: IssueSeverity.moderate,
        ),
      );
    }

    if (isPressing && wristAngle < _wristTargetAngle) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.wristBentBack,
          code: TechniqueIssue.wristBentBack.apiValue,
          message: 'Keep wrists stacked and nearly straight.',
          metricName: 'phase_wrist_angle',
          actualValue: wristAngle,
          threshold: _wristTargetAngle,
          severity: IssueSeverity.minor,
        ),
      );
    }

    if (phase == MotionPhase.open &&
        (elbowAngle < _lockoutElbowAngle ||
            shoulderAngle < _shoulderTargetAngle ||
            wristAboveShoulder < 1)) {
      issues.add(
        LiveIssueTrigger(
          issue: TechniqueIssue.poorLockout,
          code: TechniqueIssue.poorLockout.apiValue,
          message: 'Finish with wrists above shoulders and elbows extended.',
          metricName: 'phase_wrist_above_shoulder',
          actualValue: wristAboveShoulder,
          threshold: 1,
          severity: IssueSeverity.moderate,
        ),
      );
    }

    if (confidence < _lowConfidenceThreshold) {
      issues.add(
        LiveIssueTrigger(
          code: 'low_confidence_landmarks',
          message:
              'Low landmark confidence may reduce shoulder press analysis accuracy.',
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
      'max_elbow_angle': _maxMetric(frames, 'phase_elbow_angle'),
      'max_shoulder_angle': _maxMetric(frames, 'phase_shoulder_angle'),
      'max_wrist_above_shoulder':
          _maxMetric(frames, 'phase_wrist_above_shoulder'),
      'min_wrist_angle': _minMetric(frames, 'phase_wrist_angle'),
      'max_torso_angle_from_vertical':
          _maxMetric(frames, 'phase_torso_angle_from_vertical'),
      'min_knee_angle': _minMetric(frames, 'phase_knee_angle'),
      'max_knee_angle': _maxMetric(frames, 'phase_knee_angle'),
      'max_hand_forward_offset':
          _maxMetric(frames, 'phase_hand_forward_offset'),
      'max_vertical_stack_offset':
          _maxMetric(frames, 'phase_vertical_stack_offset'),
      'max_left_right_symmetry':
          _maxMetric(frames, 'phase_left_right_symmetry'),
      'max_wrist_height_asymmetry':
          _maxMetric(frames, 'phase_wrist_height_asymmetry'),
      'max_bilateral_arm_metrics':
          _maxMetric(frames, 'phase_bilateral_arm_metrics'),
    });
  }

  @override
  List<TechniqueIssue> detectFinalIssues(RepMetricBundle metrics) {
    final issues = <TechniqueIssue>[];
    if (metrics['max_elbow_angle'] < _extensionTargetElbowAngle) {
      issues.add(TechniqueIssue.incompleteExtension);
    }
    if (metrics['max_torso_angle_from_vertical'] > _torsoLeanThreshold) {
      issues.add(TechniqueIssue.excessiveBackLean);
    }
    final minKneeAngle = metrics['min_knee_angle'];
    final maxKneeAngle = metrics['max_knee_angle'];
    if (minKneeAngle > 0 &&
        minKneeAngle < _kneeDriveDipThreshold &&
        maxKneeAngle - minKneeAngle > _strictKneeChangeThreshold) {
      issues.add(TechniqueIssue.kneeDrive);
    }
    if (metrics['max_hand_forward_offset'] > _handForwardOffsetThreshold ||
        metrics['max_vertical_stack_offset'] > _handForwardOffsetThreshold) {
      issues.add(TechniqueIssue.dumbbellsForward);
    }
    if (metrics['max_bilateral_arm_metrics'] >= 1 &&
        (metrics['max_left_right_symmetry'] > _armSymmetryThreshold ||
            metrics['max_wrist_height_asymmetry'] >
                _wristHeightSymmetryThreshold)) {
      issues.add(TechniqueIssue.asymmetry);
    }
    if (metrics['min_wrist_angle'] > 0 &&
        metrics['min_wrist_angle'] < _wristTargetAngle) {
      issues.add(TechniqueIssue.wristBentBack);
    }
    if (metrics['max_shoulder_angle'] < _shoulderTargetAngle ||
        metrics['max_wrist_above_shoulder'] < 1) {
      issues.add(TechniqueIssue.poorLockout);
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

double _minMetric(List<PoseFrame> frames, String metricName) {
  final values = frames
      .map((frame) => frame.derivedMetrics[metricName])
      .whereType<double>()
      .toList();
  if (values.isEmpty) {
    return 0;
  }
  return values.reduce((left, right) => left < right ? left : right);
}
