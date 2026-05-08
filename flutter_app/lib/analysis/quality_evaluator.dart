import '../models/workout_analysis.dart';
import 'exercise_profile.dart';

class QualityEvaluator {
  const QualityEvaluator();

  RepAnalysis buildRepAnalysis({
    required int repIndex,
    required RepMetricBundle metrics,
    required List<TechniqueIssue> issues,
    required List<RepIssueEvent> issueEvents,
    int? startedTimestampMs,
    int? finishedTimestampMs,
    List<String> visitedPhases = const <String>[],
    Map<String, double> minMetrics = const <String, double>{},
    Map<String, double> maxMetrics = const <String, double>{},
    Map<String, double> avgMetrics = const <String, double>{},
  }) {
    final severitiesByCode = <String, IssueSeverity>{};
    for (final issue in issues) {
      severitiesByCode[issue.apiValue] = issue.defaultSeverity;
    }
    for (final event in issueEvents) {
      final existing = severitiesByCode[event.code];
      if (existing == null || event.severity.penalty > existing.penalty) {
        severitiesByCode[event.code] = event.severity;
      }
    }

    final totalPenalty = severitiesByCode.values.fold<int>(
      0,
      (sum, severity) => sum + severity.penalty,
    );
    final qualityScore = (100 - totalPenalty).clamp(0, 100).toInt();
    final label = qualityScore >= 85
        ? QualityLabel.excellent
        : qualityScore >= 70
            ? QualityLabel.good
            : qualityScore >= 50
                ? QualityLabel.fair
                : QualityLabel.poor;

    return RepAnalysis(
      repIndex: repIndex,
      qualityScore: qualityScore,
      qualityLabel: label,
      issues: issues,
      metricsSnapshot: Map<String, dynamic>.from(metrics.values),
      issueEvents: issueEvents,
      startedTimestampMs: startedTimestampMs,
      finishedTimestampMs: finishedTimestampMs,
      durationMs: startedTimestampMs != null && finishedTimestampMs != null
          ? finishedTimestampMs - startedTimestampMs
          : null,
      visitedPhases: visitedPhases,
      minMetrics: minMetrics,
      maxMetrics: maxMetrics,
      avgMetrics: avgMetrics,
    );
  }
}
