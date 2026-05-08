import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../providers/workout_provider.dart';
import 'history/widgets/workout_history_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workoutState = ref.watch(workoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
      ),
      body: workoutState.workouts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_toggle_off_rounded, size: 56),
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
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: workoutState.workouts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final workout = workoutState.workouts[index];
                return WorkoutHistoryTile(
                  workout: workout,
                  viewDetailsLabel: l10n.viewDetails,
                  onTap: () => context.push('/analysis', extra: workout),
                );
              },
            ),
    );
  }
}
