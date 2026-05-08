import '../../models/workout.dart';

class WorkoutCompleteArgs {
  const WorkoutCompleteArgs({
    required this.workout,
    required this.goalLabel,
  });

  final Workout workout;
  final String goalLabel;
}
