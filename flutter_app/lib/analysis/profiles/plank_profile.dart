import '../../models/workout_analysis.dart';
import '../exercise_profile.dart';
import '../plank_hold_analyzer.dart';
import '../pose_frame.dart';

class PlankProfile extends ExerciseProfile {
  static const double _minGoodBodyLineAngle = 165;
  static const double _minGoodElbowAngle = 70;
  static const double _maxGoodElbowAngle = 110;
  static const double _minGoodKneeAngle = 165;
  static const double _maxGoodNeckDeviation = 15;
  static const double _hipSagOffsetThreshold = 0.14;
  static const double _hipsHighOffsetThreshold = -0.14;
  static const double _shoulderElbowOffsetThreshold = 0.18;
  static const double _lowConfidenceThreshold = 0.45;

  @override
  String get id => 'plank';

  @override
  bool get isHoldBased => true;

  @override
  ExerciseView get requiredView => ExerciseView.side;

  @override
  RepTrackingConfig get trackingConfig => const RepTrackingConfig(
        startPhase: MotionPhase.ready,
        targetPhases: {MotionPhase.ready},
        finishPhases: {MotionPhase.ready},
        phaseDwellFrames: 1,
        minRepFrames: 1,
        completionDebounceFrames: 1,
        completionCooldownFrames: 0,
        duplicateIssueCooldownFrames: 6,
      );

  @override
  Map<String, dynamic> get thresholds => {
        'hold_body_line_angle': {
          'min_good': _minGoodBodyLineAngle,
        },
        'hold_elbow_angle': {
          'min_good': _minGoodElbowAngle,
          'max_good': _maxGoodElbowAngle,
        },
        'hold_knee_angle': {
          'min_good': _minGoodKneeAngle,
        },
        'hold_neck_deviation': {
          'max_good': _maxGoodNeckDeviation,
        },
        'hold_hip_offset': {
          'hip_sag_threshold': _hipSagOffsetThreshold,
          'hips_too_high_threshold': _hipsHighOffsetThreshold,
        },
        'hold_shoulder_elbow_offset': {
          'max_good': _shoulderElbowOffsetThreshold,
        },
      };

  PlankHoldEvaluation evaluateHold(PoseFrame frame) {
    final metrics = captureFrameMetrics(frame);
    final bodyLineAngle = metrics['hold_body_line_angle'] ?? 180;
    final elbowAngle = metrics['hold_elbow_angle'] ?? 90;
    final kneeAngle = metrics['hold_knee_angle'] ?? 180;
    final neckDeviation = metrics['hold_neck_deviation'] ?? 0;
    final hipOffset = metrics['hold_hip_offset'] ?? 0;
    final shoulderElbowOffset = metrics['hold_shoulder_elbow_offset'] ?? 0;
    final confidence = metrics['avg_landmark_confidence'] ?? 1;
    final issues = <TechniqueIssue>[];

    if (confidence < _lowConfidenceThreshold) {
      issues.add(TechniqueIssue.unstablePosition);
      return PlankHoldEvaluation(
        status: PlankHoldStatus.lostPosition,
        issues: issues,
        message: 'Lost stable plank position.',
        metrics: metrics,
      );
    }

    if (shoulderElbowOffset > _shoulderElbowOffsetThreshold) {
      issues.add(TechniqueIssue.shouldersNotOverElbows);
      return PlankHoldEvaluation(
        status: PlankHoldStatus.lostPosition,
        issues: issues,
        message: 'Keep shoulders stacked over elbows.',
        metrics: metrics,
      );
    }

    if (elbowAngle < _minGoodElbowAngle || elbowAngle > _maxGoodElbowAngle) {
      issues.add(TechniqueIssue.elbowAngleOutOfRange);
      return PlankHoldEvaluation(
        status: PlankHoldStatus.lostPosition,
        issues: issues,
        message: 'Keep elbows bent around 90 degrees.',
        metrics: metrics,
      );
    }

    if (hipOffset >= _hipSagOffsetThreshold ||
        bodyLineAngle < _minGoodBodyLineAngle && hipOffset > 0) {
      issues.add(TechniqueIssue.hipSag);
      return PlankHoldEvaluation(
        status: PlankHoldStatus.hipSag,
        issues: issues,
        message: 'Lift hips back into a straight line.',
        metrics: metrics,
      );
    }

    if (hipOffset <= _hipsHighOffsetThreshold ||
        bodyLineAngle < _minGoodBodyLineAngle && hipOffset < 0) {
      issues.add(TechniqueIssue.hipsTooHigh);
      return PlankHoldEvaluation(
        status: PlankHoldStatus.hipsTooHigh,
        issues: issues,
        message: 'Lower hips into a straight plank line.',
        metrics: metrics,
      );
    }

    if (kneeAngle < _minGoodKneeAngle) {
      issues.add(TechniqueIssue.kneesBent);
      return PlankHoldEvaluation(
        status: PlankHoldStatus.lostPosition,
        issues: issues,
        message: 'Straighten legs and hold one body line.',
        metrics: metrics,
      );
    }

    if (neckDeviation > _maxGoodNeckDeviation) {
      issues.add(TechniqueIssue.neckNotNeutral);
      return PlankHoldEvaluation(
        status: PlankHoldStatus.lostPosition,
        issues: issues,
        message: 'Keep neck neutral, looking down.',
        metrics: metrics,
      );
    }

    return PlankHoldEvaluation(
      status: PlankHoldStatus.holdingGood,
      issues: const <TechniqueIssue>[],
      message: 'Hold this position.',
      metrics: metrics,
    );
  }

  @override
  MotionPhase detectPhase(PoseFrame frame, MotionPhase previous) {
    return MotionPhase.ready;
  }

  @override
  List<LiveIssueTrigger> detectLiveIssues({
    required PoseFrame frame,
    required MotionPhase phase,
  }) {
    return const <LiveIssueTrigger>[];
  }

  @override
  RepMetricBundle summarizeRep(List<PoseFrame> frames) {
    return const RepMetricBundle(<String, double>{});
  }

  @override
  List<TechniqueIssue> detectFinalIssues(RepMetricBundle metrics) {
    return const <TechniqueIssue>[];
  }
}
