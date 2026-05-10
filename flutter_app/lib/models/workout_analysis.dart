enum ExerciseView { front, side, leftSide, rightSide, unknown }

enum MotionPhase {
  ready,
  descent,
  bottom,
  ascent,
  lockout,
  closed,
  opening,
  open,
  closing,
}

enum QualityLabel { excellent, good, fair, poor }

enum IssueSeverity { minor, moderate, major, critical }

enum TechniqueIssue {
  depthTooShallow('depth_too_shallow'),
  excessiveForwardLean('excessive_forward_lean'),
  unstableBase('unstable_base'),
  incompleteLockout('incomplete_lockout'),
  asymmetricMotion('asymmetric_motion'),
  insufficientDepth('insufficient_depth'),
  hipSag('hip_sag'),
  pikePosition('pike_position'),
  incompleteTopLockout('incomplete_top_lockout'),
  headDropping('head_dropping'),
  armsIncompleteOverhead('arms_incomplete_overhead'),
  legsNotWideEnough('legs_not_wide_enough'),
  poorSynchronization('poor_synchronization'),
  failedReturnToClosed('failed_return_to_closed'),
  leftRightAsymmetry('left_right_asymmetry'),
  hipsTooHigh('hips_too_high'),
  shouldersNotOverElbows('shoulders_not_over_elbows'),
  unstablePosition('unstable_position'),
  incompleteExtension('incomplete_extension'),
  neckNotNeutral('neck_not_neutral'),
  kneesBent('knees_bent'),
  elbowAngleOutOfRange('elbow_angle_out_of_range'),
  asymmetry('asymmetry'),
  elbowsTooWide('elbows_too_wide'),
  poorLockout('poor_lockout'),
  excessiveBackLean('excessive_back_lean'),
  barPathForward('bar_path_forward'),
  dumbbellsForward('dumbbells_forward'),
  kneeDrive('knee_drive'),
  wristBentBack('wrist_bent_back');

  const TechniqueIssue(this.apiValue);

  final String apiValue;

  static TechniqueIssue fromJson(String value) {
    for (final issue in TechniqueIssue.values) {
      if (issue.apiValue == value) {
        return issue;
      }
    }
    return TechniqueIssue.unstableBase;
  }
}

enum RepEventType { started, completed, discarded }

class RepIssueEvent {
  final String code;
  final String message;
  final String exerciseType;
  final int repIndex;
  final int frameIndex;
  final int timestampMs;
  final MotionPhase phase;
  final String metricName;
  final double actualValue;
  final double threshold;
  final IssueSeverity severity;
  final Map<String, double> metricsSnapshot;

  const RepIssueEvent({
    required this.code,
    required this.message,
    required this.exerciseType,
    required this.repIndex,
    required this.frameIndex,
    required this.timestampMs,
    required this.phase,
    required this.metricName,
    required this.actualValue,
    required this.threshold,
    required this.severity,
    this.metricsSnapshot = const <String, double>{},
  });

  factory RepIssueEvent.fromJson(Map<String, dynamic> json) {
    return RepIssueEvent(
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      exerciseType: json['exercise_type'] as String? ?? '',
      repIndex: (json['rep_index'] as num?)?.toInt() ?? 0,
      frameIndex: (json['frame_index'] as num?)?.toInt() ?? 0,
      timestampMs: (json['timestamp_ms'] as num?)?.toInt() ?? 0,
      phase: MotionPhase.values.firstWhere(
        (candidate) =>
            candidate.name ==
            (json['phase'] as String? ?? MotionPhase.ready.name),
        orElse: () => MotionPhase.ready,
      ),
      metricName: json['metric_name'] as String? ?? '',
      actualValue: (json['actual_value'] as num?)?.toDouble() ?? 0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
      severity: IssueSeverity.values.firstWhere(
        (candidate) =>
            candidate.name ==
            (json['severity'] as String? ?? IssueSeverity.moderate.name),
        orElse: () => IssueSeverity.moderate,
      ),
      metricsSnapshot: Map<String, double>.from(
        (json['metrics_snapshot'] as Map? ?? const <String, dynamic>{}).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'exercise_type': exerciseType,
      'rep_index': repIndex,
      'frame_index': frameIndex,
      'timestamp_ms': timestampMs,
      'phase': phase.name,
      'metric_name': metricName,
      'actual_value': actualValue,
      'threshold': threshold,
      'severity': severity.name,
      'metrics_snapshot': metricsSnapshot,
    };
  }
}

class RepEvent {
  final RepEventType type;
  final int repIndex;
  final int frameIndex;
  final int timestampMs;
  final MotionPhase phase;
  final bool visitedTargetPhase;
  final bool valid;

  const RepEvent({
    required this.type,
    required this.repIndex,
    required this.frameIndex,
    required this.timestampMs,
    required this.phase,
    required this.visitedTargetPhase,
    required this.valid,
  });

  factory RepEvent.fromJson(Map<String, dynamic> json) {
    return RepEvent(
      type: RepEventType.values.firstWhere(
        (candidate) =>
            candidate.name ==
            (json['type'] as String? ?? RepEventType.started.name),
        orElse: () => RepEventType.started,
      ),
      repIndex: (json['rep_index'] as num?)?.toInt() ?? 0,
      frameIndex: (json['frame_index'] as num?)?.toInt() ?? 0,
      timestampMs: (json['timestamp_ms'] as num?)?.toInt() ?? 0,
      phase: MotionPhase.values.firstWhere(
        (candidate) =>
            candidate.name ==
            (json['phase'] as String? ?? MotionPhase.ready.name),
        orElse: () => MotionPhase.ready,
      ),
      visitedTargetPhase: json['visited_target_phase'] as bool? ?? false,
      valid: json['valid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'rep_index': repIndex,
      'frame_index': frameIndex,
      'timestamp_ms': timestampMs,
      'phase': phase.name,
      'visited_target_phase': visitedTargetPhase,
      'valid': valid,
    };
  }
}

class PhaseTimelineEvent {
  final int repIndex;
  final int frameIndex;
  final int timestampMs;
  final MotionPhase phase;

  const PhaseTimelineEvent({
    required this.repIndex,
    required this.frameIndex,
    required this.timestampMs,
    required this.phase,
  });

  factory PhaseTimelineEvent.fromJson(Map<String, dynamic> json) {
    return PhaseTimelineEvent(
      repIndex: (json['rep_index'] as num?)?.toInt() ?? 0,
      frameIndex: (json['frame_index'] as num?)?.toInt() ?? 0,
      timestampMs: (json['timestamp_ms'] as num?)?.toInt() ?? 0,
      phase: MotionPhase.values.firstWhere(
        (candidate) =>
            candidate.name ==
            (json['phase'] as String? ?? MotionPhase.ready.name),
        orElse: () => MotionPhase.ready,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rep_index': repIndex,
      'frame_index': frameIndex,
      'timestamp_ms': timestampMs,
      'phase': phase.name,
    };
  }
}

class RepAnalysis {
  final int repIndex;
  final int qualityScore;
  final QualityLabel qualityLabel;
  final List<TechniqueIssue> issues;
  final Map<String, dynamic> metricsSnapshot;
  final List<RepIssueEvent> issueEvents;
  final int? startedTimestampMs;
  final int? finishedTimestampMs;
  final int? durationMs;
  final List<String> visitedPhases;
  final Map<String, double> minMetrics;
  final Map<String, double> maxMetrics;
  final Map<String, double> avgMetrics;

  const RepAnalysis({
    required this.repIndex,
    required this.qualityScore,
    required this.qualityLabel,
    required this.issues,
    required this.metricsSnapshot,
    this.issueEvents = const <RepIssueEvent>[],
    this.startedTimestampMs,
    this.finishedTimestampMs,
    this.durationMs,
    this.visitedPhases = const <String>[],
    this.minMetrics = const <String, double>{},
    this.maxMetrics = const <String, double>{},
    this.avgMetrics = const <String, double>{},
  });

  factory RepAnalysis.fromJson(Map<String, dynamic> json) {
    return RepAnalysis(
      repIndex: (json['rep_index'] as num?)?.toInt() ?? 0,
      qualityScore: (json['quality_score'] as num?)?.toInt() ?? 0,
      qualityLabel: QualityLabel.values.firstWhere(
        (candidate) =>
            candidate.name ==
            (json['quality_label'] as String? ?? QualityLabel.fair.name),
        orElse: () => QualityLabel.fair,
      ),
      issues: (json['issues'] as List<dynamic>? ?? const <dynamic>[])
          .map((issue) => TechniqueIssue.fromJson(issue as String))
          .toList(),
      metricsSnapshot: Map<String, dynamic>.from(
        json['metrics_snapshot'] as Map? ?? const <String, dynamic>{},
      ),
      issueEvents: (json['issue_events'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) =>
              RepIssueEvent.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      startedTimestampMs: (json['started_timestamp_ms'] as num?)?.toInt(),
      finishedTimestampMs: (json['finished_timestamp_ms'] as num?)?.toInt(),
      durationMs: (json['duration_ms'] as num?)?.toInt(),
      visitedPhases:
          (json['visited_phases'] as List<dynamic>? ?? const <dynamic>[])
              .map((phase) => phase.toString())
              .toList(),
      minMetrics: _doubleMapFromJson(json['min_metrics']),
      maxMetrics: _doubleMapFromJson(json['max_metrics']),
      avgMetrics: _doubleMapFromJson(json['avg_metrics']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rep_index': repIndex,
      'quality_score': qualityScore,
      'quality_label': qualityLabel.name,
      'issues': issues.map((issue) => issue.apiValue).toList(),
      'metrics_snapshot': metricsSnapshot,
      'issue_events': issueEvents.map((event) => event.toJson()).toList(),
      if (startedTimestampMs != null)
        'started_timestamp_ms': startedTimestampMs,
      if (finishedTimestampMs != null)
        'finished_timestamp_ms': finishedTimestampMs,
      if (durationMs != null) 'duration_ms': durationMs,
      'visited_phases': visitedPhases,
      'min_metrics': minMetrics,
      'max_metrics': maxMetrics,
      'avg_metrics': avgMetrics,
    };
  }
}

class HoldAnalysisSummary {
  final int samples;
  final int durationSeconds;
  final double validHoldTime;
  final double invalidHoldTime;
  final int averageQualityScore;
  final String latestStatus;
  final Map<String, double> latestMetrics;
  final List<HoldErrorEvent> errorEvents;

  const HoldAnalysisSummary({
    required this.samples,
    required this.durationSeconds,
    this.validHoldTime = 0,
    this.invalidHoldTime = 0,
    required this.averageQualityScore,
    required this.latestStatus,
    this.latestMetrics = const <String, double>{},
    this.errorEvents = const <HoldErrorEvent>[],
  });

  factory HoldAnalysisSummary.fromJson(Map<String, dynamic> json) {
    return HoldAnalysisSummary(
      samples: (json['samples'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      validHoldTime: (json['valid_hold_time'] as num?)?.toDouble() ?? 0,
      invalidHoldTime: (json['invalid_hold_time'] as num?)?.toDouble() ?? 0,
      averageQualityScore:
          (json['average_quality_score'] as num?)?.toInt() ?? 0,
      latestStatus: json['latest_status'] as String? ?? '',
      latestMetrics: _doubleMapFromJson(json['latest_metrics']),
      errorEvents: (json['error_events'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) =>
              HoldErrorEvent.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'samples': samples,
      'duration_seconds': durationSeconds,
      'valid_hold_time': validHoldTime,
      'invalid_hold_time': invalidHoldTime,
      'average_quality_score': averageQualityScore,
      'latest_status': latestStatus,
      'latest_metrics': latestMetrics,
      'error_events': errorEvents.map((event) => event.toJson()).toList(),
    };
  }
}

class HoldErrorEvent {
  final String type;
  final String message;
  final double startTime;
  final double endTime;

  const HoldErrorEvent({
    required this.type,
    required this.message,
    required this.startTime,
    required this.endTime,
  });

  factory HoldErrorEvent.fromJson(Map<String, dynamic> json) {
    return HoldErrorEvent(
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      startTime: (json['start_time'] as num?)?.toDouble() ?? 0,
      endTime: (json['end_time'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}

class WorkoutAnalysis {
  final String analysisVersion;
  final ExerciseView requiredView;
  final int readinessTimeSeconds;
  final bool stabilizationEnabled;
  final Map<String, dynamic> thresholds;
  final List<TechniqueIssue> dominantIssues;
  final List<RepIssueEvent> issueEvents;
  final List<RepEvent> repEvents;
  final List<PhaseTimelineEvent> phaseTimeline;
  final List<RepAnalysis> repAnalyses;
  final HoldAnalysisSummary? holdSummary;

  const WorkoutAnalysis({
    this.analysisVersion = '1.0',
    required this.requiredView,
    required this.readinessTimeSeconds,
    this.stabilizationEnabled = false,
    this.thresholds = const <String, dynamic>{},
    required this.dominantIssues,
    this.issueEvents = const <RepIssueEvent>[],
    this.repEvents = const <RepEvent>[],
    this.phaseTimeline = const <PhaseTimelineEvent>[],
    required this.repAnalyses,
    this.holdSummary,
  });

  factory WorkoutAnalysis.fromJson(Map<String, dynamic> json) {
    return WorkoutAnalysis(
      analysisVersion: json['analysis_version'] as String? ?? '1.0',
      requiredView: ExerciseView.values.firstWhere(
        (view) => view.name == (json['required_view'] ?? 'unknown'),
        orElse: () => ExerciseView.unknown,
      ),
      readinessTimeSeconds: (json['readiness_time_seconds'] as int?) ?? 0,
      stabilizationEnabled: json['stabilization_enabled'] as bool? ?? false,
      thresholds: Map<String, dynamic>.from(
        json['thresholds'] as Map? ?? const <String, dynamic>{},
      ),
      dominantIssues:
          (json['dominant_issues'] as List<dynamic>? ?? const <dynamic>[])
              .map((issue) => TechniqueIssue.fromJson(issue as String))
              .toList(),
      issueEvents: (json['issue_events'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) =>
              RepIssueEvent.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      repEvents: (json['rep_events'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) =>
              RepEvent.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      phaseTimeline:
          (json['phase_timeline'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => PhaseTimelineEvent.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList(),
      repAnalyses: (json['rep_analyses'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) =>
              RepAnalysis.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      holdSummary: json['hold_summary'] == null
          ? null
          : HoldAnalysisSummary.fromJson(
              Map<String, dynamic>.from(json['hold_summary'] as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis_version': analysisVersion,
      'required_view': requiredView.name,
      'readiness_time_seconds': readinessTimeSeconds,
      'stabilization_enabled': stabilizationEnabled,
      'thresholds': thresholds,
      'dominant_issues': dominantIssues.map((issue) => issue.apiValue).toList(),
      'issue_events': issueEvents.map((event) => event.toJson()).toList(),
      'rep_events': repEvents.map((event) => event.toJson()).toList(),
      'phase_timeline': phaseTimeline.map((event) => event.toJson()).toList(),
      'rep_analyses': repAnalyses.map((rep) => rep.toJson()).toList(),
      if (holdSummary != null) 'hold_summary': holdSummary!.toJson(),
    };
  }
}

extension TechniqueIssuePresentation on TechniqueIssue {
  String get displayText => apiValue.replaceAll('_', ' ');
}

extension TechniqueIssueSeverity on TechniqueIssue {
  IssueSeverity get defaultSeverity {
    switch (this) {
      case TechniqueIssue.hipSag:
      case TechniqueIssue.pikePosition:
      case TechniqueIssue.failedReturnToClosed:
        return IssueSeverity.major;
      case TechniqueIssue.poorSynchronization:
      case TechniqueIssue.unstablePosition:
        return IssueSeverity.minor;
      case TechniqueIssue.shouldersNotOverElbows:
      case TechniqueIssue.hipsTooHigh:
      case TechniqueIssue.incompleteExtension:
      case TechniqueIssue.neckNotNeutral:
      case TechniqueIssue.kneesBent:
      case TechniqueIssue.elbowAngleOutOfRange:
      case TechniqueIssue.asymmetry:
      case TechniqueIssue.elbowsTooWide:
      case TechniqueIssue.poorLockout:
      case TechniqueIssue.excessiveBackLean:
      case TechniqueIssue.barPathForward:
      case TechniqueIssue.dumbbellsForward:
      case TechniqueIssue.kneeDrive:
      case TechniqueIssue.wristBentBack:
        return IssueSeverity.moderate;
      default:
        return IssueSeverity.moderate;
    }
  }
}

extension IssueSeverityPenalty on IssueSeverity {
  int get penalty {
    switch (this) {
      case IssueSeverity.minor:
        return 10;
      case IssueSeverity.moderate:
        return 20;
      case IssueSeverity.major:
        return 35;
      case IssueSeverity.critical:
        return 50;
    }
  }
}

Map<String, double> _doubleMapFromJson(dynamic value) {
  return Map<String, double>.from(
    (value as Map? ?? const <String, dynamic>{}).map(
      (key, item) => MapEntry(key.toString(), (item as num).toDouble()),
    ),
  );
}
