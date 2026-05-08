import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/exercise_type.dart';
import '../../models/workout_plan.dart';

class WorkoutSetupScreen extends StatefulWidget {
  const WorkoutSetupScreen({
    super.key,
    required this.exerciseType,
  });

  final ExerciseType exerciseType;

  @override
  State<WorkoutSetupScreen> createState() => _WorkoutSetupScreenState();
}

class _WorkoutSetupScreenState extends State<WorkoutSetupScreen> {
  late final TextEditingController _targetController;
  WorkoutGoalMode _goalMode = WorkoutGoalMode.reps;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(text: '10');
    _targetController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  int? get _targetValue {
    final value = int.tryParse(_targetController.text);
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  void _setGoalMode(WorkoutGoalMode mode) {
    if (_goalMode == mode) {
      return;
    }
    setState(() {
      _goalMode = mode;
      _targetController.text = mode == WorkoutGoalMode.reps ? '10' : '60';
    });
  }

  void _startWorkout() {
    final targetValue = _targetValue;
    if (targetValue == null) {
      return;
    }

    context.push(
      '/workout/${widget.exerciseType.apiValue}',
      extra: WorkoutPlan(
        exerciseType: widget.exerciseType,
        goalMode: _goalMode,
        targetValue: targetValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workoutSetup),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.exerciseType.icon,
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.exerciseName(widget.exerciseType.apiValue),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.setupCoachSubtitle),
                const SizedBox(height: 16),
                Text(
                  l10n.howToStart,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.exerciseStartPositionHint(widget.exerciseType.apiValue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.chooseTarget,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GoalModeButton(
                  label: l10n.repsShort,
                  isSelected: _goalMode == WorkoutGoalMode.reps,
                  onTap: () => _setGoalMode(WorkoutGoalMode.reps),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GoalModeButton(
                  label: l10n.timeShort,
                  isSelected: _goalMode == WorkoutGoalMode.time,
                  onTap: () => _setGoalMode(WorkoutGoalMode.time),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _goalMode == WorkoutGoalMode.reps
                  ? l10n.targetReps
                  : l10n.durationSeconds,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _targetValue == null ? null : _startWorkout,
              child: Text(l10n.startWorkoutNow),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalModeButton extends StatelessWidget {
  const _GoalModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1E4) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF7A00)
                : const Color(0xFFD9E2EE),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFFF7A00)
                  : const Color(0xFF18212F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
