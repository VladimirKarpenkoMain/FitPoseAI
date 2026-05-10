/// Enum representing the types of exercises supported by the app.
enum ExerciseType {
  squat,
  pushup,
  jumpingJack,
  plank,
  shoulderPress,
}

/// Extension methods for ExerciseType.
extension ExerciseTypeExtension on ExerciseType {
  /// Returns the display name in English.
  String get displayName {
    switch (this) {
      case ExerciseType.squat:
        return 'ПРИСЕДАНИЯ';
      case ExerciseType.pushup:
        return 'ОТЖИМАНИЯ';
      case ExerciseType.jumpingJack:
        return 'ПРЫЖКИ';
      case ExerciseType.plank:
        return 'ПЛАНКА';
      case ExerciseType.shoulderPress:
        return 'ЖИМ ВВЕРХ';
    }
  }

  /// Returns the display name in Russian.
  String get displayNameRu {
    switch (this) {
      case ExerciseType.squat:
        return 'Squats';
      case ExerciseType.pushup:
        return 'Push-ups';
      case ExerciseType.jumpingJack:
        return 'Jumping Jacks';
      case ExerciseType.plank:
        return 'Plank';
      case ExerciseType.shoulderPress:
        return 'Dumbbell Shoulder Press';
    }
  }

  /// Returns the backend API value.
  String get apiValue {
    switch (this) {
      case ExerciseType.squat:
        return 'squat';
      case ExerciseType.pushup:
        return 'pushup';
      case ExerciseType.jumpingJack:
        return 'jumping_jack';
      case ExerciseType.plank:
        return 'plank';
      case ExerciseType.shoulderPress:
        return 'shoulder_press';
    }
  }

  /// Returns the icon label for this exercise type.
  String get icon {
    switch (this) {
      case ExerciseType.squat:
        return 'squat';
      case ExerciseType.pushup:
        return 'pushup';
      case ExerciseType.jumpingJack:
        return 'jumping_jack';
      case ExerciseType.plank:
        return 'plank';
      case ExerciseType.shoulderPress:
        return 'shoulder_press';
    }
  }

  String get startPositionHint {
    switch (this) {
      case ExerciseType.squat:
        return 'Stand sideways to the camera with feet shoulder-width apart.';
      case ExerciseType.pushup:
        return 'Turn sideways and hold a straight-arm plank before the first rep.';
      case ExerciseType.jumpingJack:
        return 'Face the camera with feet together and arms relaxed at your sides.';
      case ExerciseType.plank:
        return 'Turn sideways and hold a forearm plank with shoulders over elbows.';
      case ExerciseType.shoulderPress:
        return 'Turn sideways with dumbbells near shoulder height and elbows slightly forward.';
    }
  }

  /// Parse from string (from route parameter).
  static ExerciseType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'squat':
      case 'squats':
        return ExerciseType.squat;
      case 'pushup':
      case 'pushups':
      case 'push-up':
      case 'push-ups':
        return ExerciseType.pushup;
      case 'jumpingjack':
      case 'jumping_jack':
      case 'jumping-jack':
      case 'jumping_jacks':
        return ExerciseType.jumpingJack;
      case 'plank':
      case 'planks':
        return ExerciseType.plank;
      case 'shoulderpress':
      case 'shoulder_press':
      case 'shoulder-press':
      case 'shoulderpresses':
      case 'shoulder_presses':
      case 'shoulder-presses':
        return ExerciseType.shoulderPress;
      default:
        return ExerciseType.squat;
    }
  }
}
