import '../models/exercise_type.dart';
import 'analysis_debug_info.dart';
import 'exercise_profile.dart';
import 'pose_frame.dart';
import 'profiles/jumping_jack_profile.dart';
import 'profiles/pushup_profile.dart';
import 'profiles/squat_profile.dart';
import 'readiness_evaluator.dart';
import 'rep_analyzer.dart';

class WorkoutFrameResult {
  final ReadinessResult readiness;
  final String systemStatus;
  final String? liveCue;
  final RepUpdate? repUpdate;
  final AnalysisDebugInfo? debugInfo;

  const WorkoutFrameResult({
    required this.readiness,
    required this.systemStatus,
    this.liveCue,
    this.repUpdate,
    this.debugInfo,
  });

  WorkoutFrameResult copyWith({
    ReadinessResult? readiness,
    String? systemStatus,
    String? liveCue,
    RepUpdate? repUpdate,
    AnalysisDebugInfo? debugInfo,
  }) {
    return WorkoutFrameResult(
      readiness: readiness ?? this.readiness,
      systemStatus: systemStatus ?? this.systemStatus,
      liveCue: liveCue ?? this.liveCue,
      repUpdate: repUpdate ?? this.repUpdate,
      debugInfo: debugInfo ?? this.debugInfo,
    );
  }
}

class WorkoutAnalyzer {
  WorkoutAnalyzer(ExerciseType exerciseType)
      : this.fromProfile(_buildProfile(exerciseType));

  WorkoutAnalyzer.fromProfile(this.profile)
      : _repAnalyzer = RepAnalyzer(profile: profile);

  final ExerciseProfile profile;
  final RepAnalyzer _repAnalyzer;

  WorkoutFrameResult processFrame(
    PoseFrame frame, {
    required ReadinessResult readiness,
  }) {
    if (!readiness.canStartTracking) {
      return WorkoutFrameResult(
        readiness: readiness,
        systemStatus: readiness.blocker ?? 'Get ready',
      );
    }

    final repUpdate = _repAnalyzer.process(frame);
    return WorkoutFrameResult(
      readiness: readiness,
      systemStatus: 'Tracking active',
      liveCue: repUpdate.countIncremented ? 'Rep counted' : null,
      repUpdate: repUpdate,
    );
  }

  static ExerciseProfile _buildProfile(ExerciseType exerciseType) {
    switch (exerciseType) {
      case ExerciseType.squat:
        return SquatProfile();
      case ExerciseType.pushup:
        return PushupProfile();
      case ExerciseType.jumpingJack:
        return JumpingJackProfile();
    }
  }
}
