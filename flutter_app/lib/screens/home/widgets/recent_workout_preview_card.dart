import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/workout.dart';

class RecentWorkoutPreviewCard extends StatelessWidget {
  const RecentWorkoutPreviewCard({
    super.key,
    required this.workout,
  });

  final Workout? workout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recentWorkout = workout;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.latestSession,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (recentWorkout == null)
            Text(
              l10n.noWeeklyProgress,
              style: theme.textTheme.bodyMedium,
            )
          else ...[
            Text(
              l10n.exerciseName(recentWorkout.exerciseType).toUpperCase(),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${recentWorkout.repCount} ${l10n.reps}',
              style: theme.textTheme.bodyLarge,
            ),
            if (recentWorkout.averageQualityScore != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.averageQuality}: ${recentWorkout.averageQualityScore}/100',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
