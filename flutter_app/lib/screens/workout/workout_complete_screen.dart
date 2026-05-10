import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import 'workout_route_args.dart';

class WorkoutCompleteScreen extends StatelessWidget {
  const WorkoutCompleteScreen({
    super.key,
    required this.args,
  });

  final WorkoutCompleteArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quality = args.workout.averageQualityScore == null
        ? '--'
        : '${args.workout.averageQualityScore}/100';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: Color(0xFF1FBF75),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.workoutComplete,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.completedWorkoutSummary(
                  args.workout.repCount,
                  quality,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.reachedYourGoal,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.push('/analysis', extra: args.workout),
                child: Text(l10n.viewAnalysis),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/home'),
                child: Text(l10n.backToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
