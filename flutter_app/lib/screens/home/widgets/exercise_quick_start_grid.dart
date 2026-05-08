import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/exercise_type.dart';

class ExerciseQuickStartGrid extends StatelessWidget {
  const ExerciseQuickStartGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.startWorkout,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _ExerciseCard(
              label: l10n.squats,
              icon: Icons.accessibility_new_rounded,
              accent: const Color(0xFFFF7A00),
              onTap: () => _openWorkoutSetup(context, ExerciseType.squat),
            ),
            _ExerciseCard(
              label: l10n.pushups,
              icon: Icons.fitness_center_rounded,
              accent: const Color(0xFF12B3FF),
              onTap: () => _openWorkoutSetup(context, ExerciseType.pushup),
            ),
            _ExerciseCard(
              label: l10n.jumpingJacks,
              icon: Icons.bolt_rounded,
              accent: const Color(0xFFFF5A5F),
              onTap: () => _openWorkoutSetup(context, ExerciseType.jumpingJack),
            ),
          ],
        ),
      ],
    );
  }

  void _openWorkoutSetup(BuildContext context, ExerciseType exerciseType) {
    context.push('/workout-setup/${exerciseType.apiValue}');
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
