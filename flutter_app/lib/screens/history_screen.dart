import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import 'history/widgets/workout_history_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workoutState = ref.watch(workoutProvider);
    final workouts = [...workoutState.workouts]
      ..sort((a, b) => b.date.compareTo(a.date));
    final groupedWorkouts = _groupByDate(workouts);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.historyTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.historySubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: workouts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_toggle_off_rounded,
                              size: 56,
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.historyEmptyTitle),
                            const SizedBox(height: 8),
                            Text(
                              l10n.historyEmptySubtitle,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                        _HistorySummaryCard(
                          averageQuality: _averageQuality(workouts),
                          workoutCount: workouts.length,
                        ),
                        const SizedBox(height: 18),
                        for (final entry in groupedWorkouts.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 0, 2, 9),
                            child: Text(
                              l10n.historyDateLabel(entry.key).toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFF667085),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < entry.value.length;
                                      i++) ...[
                                    WorkoutHistoryTile(
                                      workout: entry.value[i],
                                      onTap: () => context.push(
                                        '/analysis',
                                        extra: entry.value[i],
                                      ),
                                    ),
                                    if (i != entry.value.length - 1)
                                      const Divider(
                                        height: 1,
                                        indent: 68,
                                        color: Color(0xFFEFF4F8),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, List<Workout>> _groupByDate(List<Workout> workouts) {
    final groups = <DateTime, List<Workout>>{};
    for (final workout in workouts) {
      final date = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );
      groups.putIfAbsent(date, () => []).add(workout);
    }
    return groups;
  }

  int? _averageQuality(List<Workout> workouts) {
    final scores = workouts
        .map((workout) => workout.averageQualityScore)
        .whereType<int>()
        .toList();
    if (scores.isEmpty) {
      return null;
    }
    final total = scores.fold<int>(0, (sum, score) => sum + score);
    return (total / scores.length).round();
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({
    required this.averageQuality,
    required this.workoutCount,
  });

  final int? averageQuality;
  final int workoutCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = (averageQuality ?? 0) / 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.averageQuality,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  averageQuality == null ? '--/100' : '$averageQuality/100',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress.clamp(0, 1),
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF34D399),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 74,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFFEFF4F8),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.historyWorkoutCount,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$workoutCount',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.allTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
