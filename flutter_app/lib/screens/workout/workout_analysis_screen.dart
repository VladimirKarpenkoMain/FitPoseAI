import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/workout.dart';
import '../../models/workout_analysis.dart';

class WorkoutAnalysisScreen extends StatelessWidget {
  const WorkoutAnalysisScreen({
    super.key,
    required this.workout,
  });

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final analysis = workout.analysis;
    final holdSummary = analysis?.holdSummary;
    final repAnalyses = analysis?.repAnalyses ?? const <RepAnalysis>[];
    final hasTechniqueData = analysis != null &&
        (repAnalyses.isNotEmpty ||
            holdSummary != null ||
            analysis.issueEvents.isNotEmpty);
    final scoreText = workout.averageQualityScore == null
        ? l10n.analysisUnavailable
        : '${workout.averageQualityScore}/100';
    final sampleText = holdSummary != null
        ? l10n.techniqueSamples(holdSummary.samples)
        : repAnalyses.isNotEmpty
            ? l10n.techniqueSamples(repAnalyses.length)
            : l10n.noTechniqueSamples;
    final focusText = analysis == null || analysis.dominantIssues.isEmpty
        ? l10n.noMajorIssueDetected()
        : l10n.techniqueIssue(analysis.dominantIssues.first.apiValue);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionAnalysis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _SummaryPanel(
            scoreText: scoreText,
            exerciseText: l10n.exerciseName(workout.exerciseType),
            repsText: l10n.repsTracked(workout.repCount),
            sampleText: sampleText,
            hasTechniqueData: hasTechniqueData,
          ),
          const SizedBox(height: 14),
          if (!hasTechniqueData)
            _Section(
              title: l10n.noTechniqueSamples,
              child: Text(
                l10n.techniqueDataNotRecorded,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else ...[
            _Section(
              title: l10n.whatWentWell,
              child: Text(
                l10n.analysisWinSummary(workout.repCount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: l10n.whatToImproveNext,
              child: Text(
                focusText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            if (holdSummary != null)
              _HoldBreakdown(summary: holdSummary)
            else if (repAnalyses.isNotEmpty)
              _RepBreakdown(reps: repAnalyses),
          ],
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.scoreText,
    required this.exerciseText,
    required this.repsText,
    required this.sampleText,
    required this.hasTechniqueData,
  });

  final String scoreText;
  final String exerciseText;
  final String repsText;
  final String sampleText;
  final bool hasTechniqueData;

  @override
  Widget build(BuildContext context) {
    final color =
        hasTechniqueData ? const Color(0xFFFF7A00) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E1EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasTechniqueData
                      ? Icons.analytics_outlined
                      : Icons.info_outline_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scoreText,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exerciseText,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FactChip(label: repsText),
              _FactChip(label: sampleText),
            ],
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _HoldBreakdown extends StatelessWidget {
  const _HoldBreakdown({required this.summary});

  final HoldAnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _Section(
      title: l10n.holdBreakdown,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          l10n.holdBreakdownSummary(summary.durationSeconds, summary.samples),
        ),
        subtitle: Text(
          l10n.repBreakdownSubtitle(
            summary.averageQualityScore,
            summary.latestStatus.isEmpty
                ? l10n.good
                : l10n.techniqueIssue(summary.latestStatus),
          ),
        ),
      ),
    );
  }
}

class _RepBreakdown extends StatelessWidget {
  const _RepBreakdown({required this.reps});

  final List<RepAnalysis> reps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _Section(
      title: l10n.latestRepBreakdown,
      child: Column(
        children: [
          for (final rep in reps)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.repBreakdownTitle(rep.repIndex)),
              subtitle: Text(
                rep.issues.isEmpty
                    ? l10n.repBreakdownSubtitle(rep.qualityScore, l10n.good)
                    : l10n.repBreakdownSubtitle(
                        rep.qualityScore,
                        l10n.techniqueIssue(rep.issues.first.apiValue),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
