import '../analysis/rep_analyzer.dart';
import '../analysis/plank_hold_analyzer.dart';
import '../models/workout_analysis.dart';

class WorkoutSessionRecorder {
  WorkoutSessionRecorder({
    required this.requiredView,
    this.analysisVersion = '2.0',
    this.stabilizationEnabled = true,
    this.thresholds = const <String, dynamic>{},
  });

  final ExerciseView requiredView;
  final String analysisVersion;
  final bool stabilizationEnabled;
  final Map<String, dynamic> thresholds;
  final List<RepAnalysis> _repAnalyses = [];
  final List<RepEvent> _repEvents = [];
  final List<RepIssueEvent> _issueEvents = [];
  final List<PhaseTimelineEvent> _phaseTimeline = [];
  final List<PlankHoldUpdate> _holdUpdates = [];

  void recordRep(RepAnalysis repAnalysis) {
    _repAnalyses.add(repAnalysis);
    _issueEvents.addAll(repAnalysis.issueEvents);
  }

  void recordRepUpdate(RepUpdate repUpdate) {
    _repEvents.addAll(repUpdate.repEvents);
    _issueEvents.addAll(repUpdate.issueEvents);
    _phaseTimeline.addAll(repUpdate.phaseTimeline);
    if (repUpdate.repAnalysis != null && repUpdate.countIncremented) {
      _repAnalyses.add(repUpdate.repAnalysis!);
    }
  }

  void recordHoldUpdate(PlankHoldUpdate holdUpdate) {
    _holdUpdates.add(holdUpdate);
  }

  bool get hasRepAnalyses => _repAnalyses.isNotEmpty;
  bool get hasHoldAnalyses => _holdUpdates.isNotEmpty;
  bool get hasAnalysis => hasRepAnalyses || hasHoldAnalyses;

  int get averageQualityScore {
    if (_repAnalyses.isNotEmpty) {
      final total =
          _repAnalyses.fold<int>(0, (sum, rep) => sum + rep.qualityScore);
      return (total / _repAnalyses.length).round();
    }

    if (_holdUpdates.isNotEmpty) {
      final total = _holdUpdates.fold<int>(
        0,
        (sum, update) => sum + _holdQualityScore(update),
      );
      return (total / _holdUpdates.length).round();
    }

    return 0;
  }

  Map<String, dynamic> buildAnalysisPayload(
      {required int readinessTimeSeconds}) {
    final issueCounts = <TechniqueIssue, int>{};
    for (final rep in _repAnalyses) {
      for (final issue in rep.issues) {
        issueCounts.update(issue, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    for (final update in _holdUpdates) {
      for (final issue in update.issues) {
        issueCounts.update(issue, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    final dominantIssues = issueCounts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    final latestHoldUpdate = _holdUpdates.isEmpty ? null : _holdUpdates.last;
    final totalHoldDuration = latestHoldUpdate == null
        ? Duration.zero
        : latestHoldUpdate.validHoldDuration +
            latestHoldUpdate.invalidHoldDuration;
    final reportedHoldDuration =
        totalHoldDuration > Duration.zero && latestHoldUpdate != null
            ? totalHoldDuration
            : latestHoldUpdate?.holdDuration ?? Duration.zero;
    final latestHoldStatus = latestHoldUpdate == null
        ? ''
        : latestHoldUpdate.issues.isEmpty
            ? latestHoldUpdate.status.apiValue
            : latestHoldUpdate.issues.first.apiValue;
    final holdErrorEvents = _holdErrorEvents();

    return {
      'analysis_version': analysisVersion,
      'required_view': requiredView.name,
      'readiness_time_seconds': readinessTimeSeconds,
      'stabilization_enabled': stabilizationEnabled,
      'thresholds': thresholds,
      'dominant_issues':
          dominantIssues.map((entry) => entry.key.apiValue).toList(),
      'rep_analyses': _repAnalyses.map((rep) => rep.toJson()).toList(),
      'rep_events': _repEvents.map((event) => event.toJson()).toList(),
      'issue_events': _issueEvents.map((event) => event.toJson()).toList(),
      'phase_timeline': _phaseTimeline.map((event) => event.toJson()).toList(),
      if (_holdUpdates.isNotEmpty)
        'hold_summary': {
          'samples': _holdUpdates.length,
          'duration_seconds': reportedHoldDuration.inMilliseconds ~/ 1000,
          'valid_hold_time': _seconds(latestHoldUpdate!.validHoldDuration),
          'invalid_hold_time': _seconds(latestHoldUpdate.invalidHoldDuration),
          'average_quality_score': averageQualityScore,
          'latest_status': latestHoldStatus,
          'latest_metrics': latestHoldUpdate.metrics,
          'error_events': holdErrorEvents,
          'errors': holdErrorEvents,
        },
    };
  }

  int _holdQualityScore(PlankHoldUpdate update) {
    switch (update.status) {
      case PlankHoldStatus.holdingGood:
        return 100;
      case PlankHoldStatus.hipSag:
      case PlankHoldStatus.hipsTooHigh:
        return 55;
      case PlankHoldStatus.lostPosition:
        return 35;
    }
  }

  List<Map<String, dynamic>> _holdErrorEvents() {
    final events = <Map<String, dynamic>>[];
    String? activeType;
    String? activeMessage;
    int? activeStartMs;

    void closeEvent(int endMs) {
      final type = activeType;
      final startMs = activeStartMs;
      if (type == null || startMs == null) {
        return;
      }
      events.add({
        'type': type,
        'message': activeMessage ?? '',
        'start_time': _secondsFromMilliseconds(startMs),
        'end_time': _secondsFromMilliseconds(endMs),
      });
      activeType = null;
      activeMessage = null;
      activeStartMs = null;
    }

    for (final update in _holdUpdates) {
      final type = _holdIssueType(update);
      if (type == null) {
        closeEvent(update.timestampMs);
        continue;
      }

      if (activeType != null && activeType != type) {
        closeEvent(update.timestampMs);
      }
      activeType ??= type;
      activeMessage ??= update.message;
      activeStartMs ??= update.issueStartedTimestampMs ?? update.timestampMs;
    }

    if (_holdUpdates.isNotEmpty) {
      closeEvent(_holdUpdates.last.timestampMs);
    }
    return events;
  }

  String? _holdIssueType(PlankHoldUpdate update) {
    if (update.issues.isNotEmpty) {
      return update.issues.first.apiValue;
    }
    if (update.status == PlankHoldStatus.holdingGood) {
      return null;
    }
    return update.status.apiValue;
  }

  double _seconds(Duration duration) {
    return _secondsFromMilliseconds(duration.inMilliseconds);
  }

  double _secondsFromMilliseconds(int milliseconds) {
    return milliseconds / 1000;
  }
}
