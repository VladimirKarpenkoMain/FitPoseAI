import 'package:fitness_ai/models/workout.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history card data exposes average quality score when present', () {
    final workout = Workout(
      id: 1,
      userId: 2,
      exerciseType: 'squat',
      repCount: 8,
      date: DateTime.parse('2026-05-05T10:30:00Z'),
      averageQualityScore: 74,
      analysis: const WorkoutAnalysis(
        requiredView: ExerciseView.side,
        readinessTimeSeconds: 10,
        dominantIssues: [TechniqueIssue.depthTooShallow],
        repAnalyses: [],
      ),
    );

    expect('${workout.averageQualityScore}/100', '74/100');
  });
}
