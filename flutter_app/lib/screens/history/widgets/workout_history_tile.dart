import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/workout.dart';

class WorkoutHistoryTile extends StatelessWidget {
  const WorkoutHistoryTile({
    super.key,
    required this.workout,
    required this.onTap,
  });

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final exerciseName = l10n.exerciseName(workout.exerciseType);
    final quality = workout.averageQualityScore;
    final scoreStyle = _scoreStyle(quality);
    final topIssue = workout.analysis?.dominantIssues.isNotEmpty ?? false
        ? workout.analysis!.dominantIssues.first
        : null;
    final focusText = topIssue == null
        ? l10n.noMajorIssueDetected()
        : l10n.workoutFocusLabel(l10n.techniqueIssue(topIssue.apiValue));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _exerciseInitials(exerciseName),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFE85D04),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${workout.repCount} ${l10n.reps} • ${l10n.historySessionTime(workout.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      focusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scoreStyle.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  quality == null ? '--' : '$quality',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scoreStyle.foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _exerciseInitials(String name) {
    final words = name
        .split(RegExp(r'[\s-]+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return '?';
    }
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  _ScoreStyle _scoreStyle(int? score) {
    if (score == null) {
      return const _ScoreStyle(
        background: Color(0xFFF1F5F9),
        foreground: Color(0xFF64748B),
      );
    }
    if (score >= 80) {
      return const _ScoreStyle(
        background: Color(0xFFECFDF3),
        foreground: Color(0xFF047857),
      );
    }
    if (score >= 60) {
      return const _ScoreStyle(
        background: Color(0xFFFFF7ED),
        foreground: Color(0xFFB45309),
      );
    }
    return const _ScoreStyle(
      background: Color(0xFFFEF2F2),
      foreground: Color(0xFFB91C1C),
    );
  }
}

class _ScoreStyle {
  const _ScoreStyle({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
