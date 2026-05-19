// Example demonstrating the FeedbackManager and WorkoutFeedbackCoordinator.
// This file shows how to integrate the feedback system with exercise counters.
//
// This is for reference/testing purposes only - not part of the main app.

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../logic/exercise_counters.dart';
import '../services/feedback_manager.dart';
import '../services/workout_feedback_coordinator.dart';

/// Example: Squat workout with complete feedback
class SquatWorkoutExample {
  final SquatCounter counter = SquatCounter();
  final WorkoutFeedbackCoordinator coordinator;

  SquatWorkoutExample()
      : coordinator = WorkoutFeedbackCoordinator(FeedbackManager());

  /// Start a new workout session
  Future<void> startWorkout() async {
    counter.reset();
    coordinator.reset();

    // Countdown
    await coordinator.speakCustom("Get ready for squats", priority: true);
    await Future.delayed(const Duration(seconds: 2));
    await coordinator.speakCustom("Start!", priority: true);
  }

  /// Process a pose frame
  Future<void> processPose(Pose pose) async {
    // Calculate counter result
    final result = counter.calculate(pose);

    // Provide automatic voice feedback.
    await coordinator.processFeedback(result);

    // You can access the result data
    print('Reps: ${result.count}');
    print('Feedback: ${result.feedback}');

    if (result.countIncremented) {
      print('New rep completed! 🎉');
    }
  }

  /// Complete the workout
  Future<void> finishWorkout() async {
    final finalCount = counter.count;
    await coordinator.speakCustom(
      "Workout complete! You did $finalCount squats",
      priority: true,
    );
  }

  /// Get current stats
  Map<String, dynamic> getStats() {
    return {
      'reps': counter.count,
      'feedback': counter.feedback,
    };
  }
}

/// Example: Push-up workout with complete feedback
class PushUpWorkoutExample {
  final PushUpCounter counter = PushUpCounter();
  final WorkoutFeedbackCoordinator coordinator;

  PushUpWorkoutExample()
      : coordinator = WorkoutFeedbackCoordinator(FeedbackManager());

  Future<void> startWorkout() async {
    counter.reset();
    coordinator.reset();
    await coordinator.speakCustom("Get in push-up position", priority: true);
  }

  Future<void> processPose(Pose pose) async {
    final result = counter.calculate(pose);
    await coordinator.processFeedback(result);
  }

  Future<void> finishWorkout() async {
    await coordinator.speakCustom(
      "Great work! ${counter.count} push-ups completed",
      priority: true,
    );
  }
}

/// Example: Jumping jack workout with complete feedback
class JumpingJackWorkoutExample {
  final JumpingJackCounter counter = JumpingJackCounter();
  final WorkoutFeedbackCoordinator coordinator;

  JumpingJackWorkoutExample()
      : coordinator = WorkoutFeedbackCoordinator(FeedbackManager());

  Future<void> startWorkout() async {
    counter.reset();
    coordinator.reset();
    await coordinator.speakCustom("Ready for jumping jacks", priority: true);
    await Future.delayed(const Duration(seconds: 1));
    await coordinator.speakCustom("Begin!", priority: true);
  }

  Future<void> processPose(Pose pose) async {
    final result = counter.calculate(pose);
    await coordinator.processFeedback(result);
  }

  Future<void> finishWorkout() async {
    await coordinator.speakCustom(
      "Excellent! ${counter.count} jumping jacks done",
      priority: true,
    );
  }
}

/// Example: Testing TTS features
class TTSTestExample {
  final FeedbackManager manager = FeedbackManager();

  /// Test basic speech
  Future<void> testBasicSpeech() async {
    await manager.speak("Hello, this is a test");
  }

  /// Test rep counting
  Future<void> testRepCounting() async {
    for (int i = 1; i <= 10; i++) {
      await manager.speakRepCount(i);
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Test priority speech (cancels previous)
  Future<void> testPrioritySpeech() async {
    // Start a long message
    manager.speak("This is a very long message that should be interrupted");

    // Wait a bit
    await Future.delayed(const Duration(milliseconds: 500));

    // Interrupt with priority message
    await manager.speak("Important!", priority: true);
  }

  /// Test language switching
  Future<void> testLanguageSwitching() async {
    // English
    await manager.setEnglish();
    await manager.speak("Hello");
    await Future.delayed(const Duration(seconds: 2));

    // Russian
    await manager.setRussian();
    await manager.speak("Привет");
    await Future.delayed(const Duration(seconds: 2));

    // Back to English
    await manager.setEnglish();
    await manager.speak("Back to English");
  }
}

/// Example: Multi-exercise workout session
class WorkoutSessionExample {
  WorkoutFeedbackCoordinator? _currentCoordinator;
  ExerciseCounter? _currentCounter;

  /// Start a specific exercise
  Future<void> startExercise(String exerciseType) async {
    // Stop previous coordinator
    if (_currentCoordinator != null) {
      await _currentCoordinator!.stop();
    }

    // Create new counter and coordinator
    final manager = FeedbackManager();

    switch (exerciseType.toLowerCase()) {
      case 'squat':
        _currentCounter = SquatCounter();
        _currentCoordinator = WorkoutFeedbackCoordinator(manager);
        await _currentCoordinator!
            .speakCustom("Starting squats", priority: true);
        break;

      case 'pushup':
        _currentCounter = PushUpCounter();
        _currentCoordinator = WorkoutFeedbackCoordinator(manager);
        await _currentCoordinator!
            .speakCustom("Starting push-ups", priority: true);
        break;

      case 'jumpingjack':
        _currentCounter = JumpingJackCounter();
        _currentCoordinator = WorkoutFeedbackCoordinator(manager);
        await _currentCoordinator!
            .speakCustom("Starting jumping jacks", priority: true);
        break;

      default:
        throw Exception('Unknown exercise type: $exerciseType');
    }
  }

  /// Process a pose for the current exercise
  Future<void> processPose(Pose pose) async {
    if (_currentCounter == null || _currentCoordinator == null) {
      throw Exception('No active exercise. Call startExercise() first.');
    }

    final result = _currentCounter!.calculate(pose);
    await _currentCoordinator!.processFeedback(result);
  }

  /// Switch to a different exercise
  Future<void> switchExercise(String newExerciseType) async {
    if (_currentCounter != null) {
      await _currentCoordinator?.speakCustom(
        "Exercise complete! ${_currentCounter!.count} reps done",
        priority: true,
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    await startExercise(newExerciseType);
  }

  /// End the workout session
  Future<void> endSession() async {
    if (_currentCounter != null) {
      await _currentCoordinator?.speakCustom(
        "Workout session complete! Great job!",
        priority: true,
      );
    }

    await _currentCoordinator?.stop();
    _currentCounter = null;
    _currentCoordinator = null;
  }
}
