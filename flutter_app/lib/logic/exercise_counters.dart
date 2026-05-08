/// Export file for all exercise counters and related classes
/// 
/// This file provides easy access to the exercise counting logic:
/// - Abstract ExerciseCounter base class
/// - Concrete implementations: SquatCounter, PushUpCounter, JumpingJackCounter
/// - CounterResult class for returning state and feedback
/// 
/// Usage:
/// ```dart
/// import 'package:fitness_ai/logic/exercise_counters.dart';
/// 
/// final counter = SquatCounter();
/// final result = counter.calculate(pose);
/// print('Reps: ${result.count}, Feedback: ${result.feedback}');
/// ```

export 'exercise_counter.dart';
export 'squat_counter.dart';
export 'pushup_counter.dart';
export 'jumping_jack_counter.dart';
