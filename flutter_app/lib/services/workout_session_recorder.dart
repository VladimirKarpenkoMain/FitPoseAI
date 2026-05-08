import '../analysis/rep_analyzer.dart';
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

  bool get hasRepAnalyses => _repAnalyses.isNotEmpty;

  int get averageQualityScore {
    if (_repAnalyses.isEmpty) {
      return 0;
    }
    final total =
        _repAnalyses.fold<int>(0, (sum, rep) => sum + rep.qualityScore);
    return (total / _repAnalyses.length).round();
  }

  Map<String, dynamic> buildAnalysisPayload(
      {required int readinessTimeSeconds}) {
    final issueCounts = <TechniqueIssue, int>{};
    for (final rep in _repAnalyses) {
      for (final issue in rep.issues) {
        issueCounts.update(issue, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    final dominantIssues = issueCounts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));

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
    };
  }
}
