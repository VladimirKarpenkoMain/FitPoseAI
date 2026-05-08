import '../../models/workout.dart';

class WeeklyProgressSummary {
  const WeeklyProgressSummary({
    required this.weeklySessions,
    required this.weeklyReps,
    required this.averageQualityScore,
    required this.latestWorkout,
  });

  final int weeklySessions;
  final int weeklyReps;
  final int? averageQualityScore;
  final Workout? latestWorkout;

  bool get hasData => weeklySessions > 0 || latestWorkout != null;
}

WeeklyProgressSummary buildWeeklyProgress(
  List<Workout> workouts, {
  required DateTime now,
}) {
  final weekStart = DateTime.utc(
    now.toUtc().year,
    now.toUtc().month,
    now.toUtc().day,
  ).subtract(Duration(days: now.toUtc().weekday - 1));

  final weeklyWorkouts = workouts
      .where((workout) => !workout.date.toUtc().isBefore(weekStart))
      .toList();

  final qualityScores = weeklyWorkouts
      .where((workout) => workout.averageQualityScore != null)
      .map((workout) => workout.averageQualityScore!)
      .toList();

  Workout? latestWorkout;
  for (final workout in workouts) {
    if (latestWorkout == null || workout.date.isAfter(latestWorkout.date)) {
      latestWorkout = workout;
    }
  }

  return WeeklyProgressSummary(
    weeklySessions: weeklyWorkouts.length,
    weeklyReps: weeklyWorkouts.fold<int>(0, (sum, workout) => sum + workout.repCount),
    averageQualityScore: qualityScores.isEmpty
        ? null
        : (qualityScores.reduce((left, right) => left + right) / qualityScores.length).round(),
    latestWorkout: latestWorkout,
  );
}
