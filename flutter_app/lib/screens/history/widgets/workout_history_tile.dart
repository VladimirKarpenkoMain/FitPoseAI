import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/workout.dart';

class WorkoutHistoryTile extends StatelessWidget {
  const WorkoutHistoryTile({
    super.key,
    required this.workout,
    required this.viewDetailsLabel,
    required this.onTap,
  });

  final Workout workout;
  final String viewDetailsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quality = workout.averageQualityScore == null
        ? '--'
        : '${workout.averageQualityScore}/100';
    final topIssue = workout.analysis?.dominantIssues.isNotEmpty ?? false
        ? workout.analysis!.dominantIssues.first
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFFFF7A00),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.exerciseName(workout.exerciseType).toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.workoutTileSummary(workout.repCount, quality)),
                    if (topIssue != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.workoutFocusLabel(
                          l10n.techniqueIssue(topIssue.apiValue),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(viewDetailsLabel),
            ],
          ),
        ),
      ),
    );
  }
}
