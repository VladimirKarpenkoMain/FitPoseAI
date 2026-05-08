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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessionAnalysis)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${workout.averageQualityScore ?? '--'}/100',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${workout.repCount} ${l10n.reps} • ${l10n.exerciseName(workout.exerciseType)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.whatWentWell,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(l10n.analysisWinSummary(workout.repCount)),
          const SizedBox(height: 18),
          Text(
            l10n.whatToImproveNext,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            analysis == null || analysis.dominantIssues.isEmpty
                ? l10n.noMajorIssueDetected()
                : l10n.techniqueIssue(analysis.dominantIssues.first.apiValue),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.latestRepBreakdown,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final rep in analysis?.repAnalyses ?? const <RepAnalysis>[])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.repBreakdownTitle(rep.repIndex)),
              subtitle: Text(
                rep.issues.isEmpty
                    ? l10n.repBreakdownSubtitle(
                        rep.qualityScore,
                        l10n.good,
                      )
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
