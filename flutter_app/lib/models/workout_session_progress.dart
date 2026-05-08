import 'dart:math' as math;

import 'workout_plan.dart';

enum WorkoutSessionPhase {
  preparation,
  active,
  completed,
}

class WorkoutSessionProgress {
  const WorkoutSessionProgress({
    required this.plan,
    required this.phase,
    required this.repCount,
    this.activeElapsed = Duration.zero,
  });

  final WorkoutPlan plan;
  final WorkoutSessionPhase phase;
  final int repCount;
  final Duration activeElapsed;

  int get remainingReps {
    if (!plan.isRepBased) {
      return 0;
    }
    return math.max(0, plan.targetValue - repCount);
  }

  Duration get remainingDuration {
    if (!plan.isTimeBased) {
      return Duration.zero;
    }
    final remainingSeconds = math.max(0, plan.targetValue - activeElapsed.inSeconds);
    return Duration(seconds: remainingSeconds);
  }

  bool get hasReachedGoal {
    if (plan.isRepBased) {
      return repCount >= plan.targetValue;
    }
    return activeElapsed.inSeconds >= plan.targetValue;
  }

  static String formatClock(Duration duration) {
    final totalSeconds = math.max(0, duration.inSeconds);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
