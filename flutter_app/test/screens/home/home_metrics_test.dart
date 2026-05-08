import 'package:fitness_ai/models/workout.dart';
import 'package:fitness_ai/screens/home/home_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildWeeklyProgress returns weekly totals and latest workout summary', () {
    final workouts = [
      Workout(
        id: 3,
        userId: 1,
        exerciseType: 'pushup',
        repCount: 22,
        date: DateTime.parse('2026-05-06T07:40:00Z'),
        averageQualityScore: 82,
      ),
      Workout(
        id: 2,
        userId: 1,
        exerciseType: 'squat',
        repCount: 18,
        date: DateTime.parse('2026-05-04T09:00:00Z'),
        averageQualityScore: 74,
      ),
      Workout(
        id: 1,
        userId: 1,
        exerciseType: 'squat',
        repCount: 12,
        date: DateTime.parse('2026-04-27T09:00:00Z'),
        averageQualityScore: 70,
      ),
    ];

    final summary = buildWeeklyProgress(
      workouts,
      now: DateTime.parse('2026-05-06T12:00:00Z'),
    );

    expect(summary.weeklySessions, 2);
    expect(summary.weeklyReps, 40);
    expect(summary.averageQualityScore, 78);
    expect(summary.latestWorkout?.id, 3);
    expect(summary.hasData, isTrue);
  });
}
