import 'package:fitness_ai/models/exercise_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('api values are stable route and backend slugs', () {
    expect(ExerciseType.squat.apiValue, 'squat');
    expect(ExerciseType.pushup.apiValue, 'pushup');
    expect(ExerciseType.jumpingJack.apiValue, 'jumping_jack');
    expect(ExerciseType.plank.apiValue, 'plank');
    expect(ExerciseType.shoulderPress.apiValue, 'shoulder_press');
  });

  test('fromString parses every api value without falling back to squat', () {
    for (final exerciseType in ExerciseType.values) {
      expect(
        ExerciseTypeExtension.fromString(exerciseType.apiValue),
        exerciseType,
      );
    }
  });

  test('shoulder press is presented as standing dumbbell press', () {
    expect(ExerciseType.shoulderPress.displayNameRu, 'Dumbbell Shoulder Press');
    expect(
      ExerciseType.shoulderPress.startPositionHint,
      contains('dumbbells'),
    );
  });
}
