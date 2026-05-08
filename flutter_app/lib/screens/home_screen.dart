import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import 'home/home_metrics.dart';
import 'home/widgets/exercise_quick_start_grid.dart';
import 'home/widgets/recent_workout_preview_card.dart';
import 'home/widgets/weekly_progress_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(workoutProvider.notifier).fetchWorkouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workoutState = ref.watch(workoutProvider);
    final summary = buildWeeklyProgress(
      workoutState.workouts,
      now: DateTime.now(),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Color(0xFFF4F7FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref.read(workoutProvider.notifier).fetchWorkouts(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.fitnessAI,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/settings'),
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: l10n.settings,
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                        },
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: l10n.logout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DashboardHero(
                    title: l10n.dashboardHeroTitle,
                    subtitle: l10n.dashboardHeroSubtitle,
                    actionLabel: l10n.startNow,
                  ),
                  const SizedBox(height: 20),
                  WeeklyProgressCard(
                    title: l10n.thisWeek,
                    emptyState: l10n.noWeeklyProgress,
                    sessionsLabel: l10n.weeklySessions,
                    repsLabel: l10n.weeklyReps,
                    qualityLabel: l10n.averageQuality,
                    summary: summary,
                  ),
                  const SizedBox(height: 20),
                  const ExerciseQuickStartGrid(),
                  const SizedBox(height: 20),
                  RecentWorkoutPreviewCard(workout: summary.latestWorkout),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.push('/history'),
                      child: Text(l10n.seeFullHistory),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final String title;
  final String subtitle;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE5EBF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x1412B3FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.homeHeroBadge,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF0E7490),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
          Text(subtitle, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/workout-setup/squat'),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
