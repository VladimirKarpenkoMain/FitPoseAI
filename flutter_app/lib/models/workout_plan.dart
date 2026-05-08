import 'exercise_type.dart';

enum WorkoutGoalMode {
  reps,
  time,
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.exerciseType,
    required this.goalMode,
    required this.targetValue,
    this.preparationSeconds = 5,
  });

  final ExerciseType exerciseType;
  final WorkoutGoalMode goalMode;
  final int targetValue;
  final int preparationSeconds;

  bool get isRepBased => goalMode == WorkoutGoalMode.reps;

  bool get isTimeBased => goalMode == WorkoutGoalMode.time;
}
