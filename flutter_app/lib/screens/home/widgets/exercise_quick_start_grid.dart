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
        const SizedBox(height: 2),
        Text(
          l10n.exerciseCount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ExerciseCard(
                label: l10n.squats,
                icon: Icons.accessibility_new_rounded,
                accent: const Color(0xFFFF7A00),
                onTap: () => _openWorkoutSetup(context, ExerciseType.squat),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ExerciseCard(
                label: l10n.pushups,
                icon: Icons.fitness_center_rounded,
                accent: const Color(0xFF12B3FF),
                onTap: () => _openWorkoutSetup(context, ExerciseType.pushup),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ExerciseCard(
                label: l10n.jumpingJacks,
                icon: Icons.bolt_rounded,
                accent: const Color(0xFFFF5A5F),
                onTap: () =>
                    _openWorkoutSetup(context, ExerciseType.jumpingJack),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ExerciseCard(
                label: l10n.plank,
                icon: Icons.timer_rounded,
                accent: const Color(0xFF16A34A),
                onTap: () => _openWorkoutSetup(context, ExerciseType.plank),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ExerciseCard(
          label: l10n.shoulderPress,
          icon: Icons.upload_rounded,
          accent: const Color(0xFFFF7A00),
          compact: true,
          onTap: () => _openWorkoutSetup(context, ExerciseType.shoulderPress),
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
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: compact ? 46 : 88,
              child: compact
                  ? Row(
                      children: [
                        _ExerciseIcon(icon: icon, accent: accent),
                        const SizedBox(width: 12),
                        Expanded(child: _ExerciseLabel(label: label)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ExerciseIcon(icon: icon, accent: accent),
                        const Spacer(),
                        _ExerciseLabel(label: label),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseIcon extends StatelessWidget {
  const _ExerciseIcon({
    required this.icon,
    required this.accent,
  });

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: accent, size: 23),
    );
  }
}

class _ExerciseLabel extends StatelessWidget {
  const _ExerciseLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF18212F),
            fontWeight: FontWeight.w900,
            height: 1.12,
            fontSize: 13,
          ),
    );
  }
}
