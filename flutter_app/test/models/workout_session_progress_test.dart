import 'package:fitness_ai/models/exercise_type.dart';
import 'package:fitness_ai/models/workout_plan.dart';
import 'package:fitness_ai/models/workout_session_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rep-based progress reaches goal when target reps are completed', () {
    const plan = WorkoutPlan(
      exerciseType: ExerciseType.squat,
      goalMode: WorkoutGoalMode.reps,
      targetValue: 12,
    );

    const progress = WorkoutSessionProgress(
      plan: plan,
      phase: WorkoutSessionPhase.active,
      repCount: 12,
    );

    expect(progress.remainingReps, 0);
    expect(progress.hasReachedGoal, isTrue);
  });

  test('time-based progress tracks remaining duration and completion', () {
    const plan = WorkoutPlan(
      exerciseType: ExerciseType.pushup,
      goalMode: WorkoutGoalMode.time,
      targetValue: 90,
    );

    const inProgress = WorkoutSessionProgress(
      plan: plan,
      phase: WorkoutSessionPhase.active,
      repCount: 7,
      activeElapsed: Duration(seconds: 32),
    );

    const completed = WorkoutSessionProgress(
      plan: plan,
      phase: WorkoutSessionPhase.active,
      repCount: 9,
      activeElapsed: Duration(seconds: 91),
    );

    expect(inProgress.remainingDuration, const Duration(seconds: 58));
    expect(inProgress.hasReachedGoal, isFalse);

    expect(completed.remainingDuration, Duration.zero);
    expect(completed.hasReachedGoal, isTrue);
  });

  test('formatClock renders mm:ss values with leading zeroes', () {
    expect(WorkoutSessionProgress.formatClock(const Duration(seconds: 5)), '00:05');
    expect(
      WorkoutSessionProgress.formatClock(const Duration(minutes: 2, seconds: 7)),
      '02:07',
    );
  });
}
