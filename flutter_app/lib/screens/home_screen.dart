import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import 'home/home_metrics.dart';
import 'home/widgets/exercise_quick_start_grid.dart';

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
    final workouts = ref.watch(workoutProvider).workouts;
    final weeklyProgress = buildWeeklyProgress(workouts, now: DateTime.now());

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
                  const SizedBox(height: 16),
                  const _CoachHeroCard(),
                  const SizedBox(height: 14),
                  _WeeklyWorkoutCountCard(
                    count: weeklyProgress.weeklySessions,
                  ),
                  const SizedBox(height: 22),
                  const ExerciseQuickStartGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachHeroCard extends StatelessWidget {
  const _CoachHeroCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF101827), Color(0xFF323F4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            bottom: -36,
            child: Transform.rotate(
              angle: -0.18,
              child: Container(
                width: 148,
                height: 178,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 2,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(84),
                    topRight: Radius.circular(84),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.homeHeroBadge.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFFED7AA),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Text(
                  l10n.homeCoachHeroTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
                child: Text(
                  l10n.homeCoachHeroSubtitle,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyWorkoutCountCard extends StatelessWidget {
  const _WeeklyWorkoutCountCard({
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8F3), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A00),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDDC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFFFF7A00),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF18212F),
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.workoutsThisWeek,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
