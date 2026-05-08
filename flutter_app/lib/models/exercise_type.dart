/// Enum representing the types of exercises supported by the app
enum ExerciseType {
  squat,
  pushup,
  jumpingJack,
}

/// Extension methods for ExerciseType
extension ExerciseTypeExtension on ExerciseType {
  /// Returns the display name in English
  String get displayName {
    switch (this) {
      case ExerciseType.squat:
        return 'Squats';
      case ExerciseType.pushup:
        return 'Push-ups';
      case ExerciseType.jumpingJack:
        return 'Jumping Jacks';
    }
  }

  /// Returns the display name in Russian
  String get displayNameRu {
    switch (this) {
      case ExerciseType.squat:
        return 'ПРИСЕДАНИЯ';
      case ExerciseType.pushup:
        return 'ОТЖИМАНИЯ';
      case ExerciseType.jumpingJack:
        return 'ПРЫЖКИ';
    }
  }

  /// Returns the backend API value
  String get apiValue {
    switch (this) {
      case ExerciseType.squat:
        return 'squat';
      case ExerciseType.pushup:
        return 'pushup';
      case ExerciseType.jumpingJack:
        return 'jumping_jack';
    }
  }

  /// Returns the icon for this exercise type
  String get icon {
    switch (this) {
      case ExerciseType.squat:
        return '🏋️';
      case ExerciseType.pushup:
        return '💪';
      case ExerciseType.jumpingJack:
        return '⭐';
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
    }
  }

  /// Parse from string (from route parameter)
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
      default:
        return ExerciseType.squat; // Default to squat
    }
  }
}
