import '../models/workout_analysis.dart';
import 'pose_frame.dart';
import 'view_detector.dart';

enum ReadinessState {
  viewAlignment,
  bodyVisibilityCheck,
  startPoseCheck,
  countdownReady,
  activeTracking,
}

class ReadinessResult {
  final ReadinessState state;
  final bool canStartTracking;
  final int remainingSeconds;
  final String? blocker;

  const ReadinessResult({
    required this.state,
    required this.canStartTracking,
    required this.remainingSeconds,
    this.blocker,
  });
}

class ReadinessEvaluator {
  ReadinessEvaluator({
    required this.requiredView,
    required this.countdownSeconds,
    required this.requiredJoints,
    this.visibilityJointGroups = const <Set<Joint>>[],
    this.enforceReadinessChecks = true,
  });

  final ExerciseView requiredView;
  final int countdownSeconds;
  final Set<Joint> requiredJoints;
  final List<Set<Joint>> visibilityJointGroups;
  final bool enforceReadinessChecks;
  final ViewDetector _viewDetector = const ViewDetector();
  int? _countdownAnchorSeconds;

  ReadinessResult evaluate({
    PoseFrame? frame,
    required int elapsedSeconds,
  }) {
    if (!enforceReadinessChecks) {
      return _evaluateCountdownOnly(elapsedSeconds: elapsedSeconds);
    }

    if (frame == null) {
      _countdownAnchorSeconds = null;
      return ReadinessResult(
        state: ReadinessState.bodyVisibilityCheck,
        canStartTracking: false,
        remainingSeconds: countdownSeconds,
        blocker: 'Step into frame',
      );
    }

    final detectedView = _viewDetector.detect(frame);
    final viewSatisfied = _isViewSatisfied(detectedView.view) ||
        (requiredView == ExerciseView.side && _hasSingleSideFallback(frame));
    if (!viewSatisfied) {
      _countdownAnchorSeconds = null;
      return ReadinessResult(
        state: ReadinessState.viewAlignment,
        canStartTracking: false,
        remainingSeconds: countdownSeconds,
        blocker: requiredView == ExerciseView.front
            ? 'Face the camera'
            : 'Turn to your side',
      );
    }

    final missingVisibilityBlocker = _missingVisibilityBlocker(frame);
    if (missingVisibilityBlocker != null) {
      _countdownAnchorSeconds = null;
      return ReadinessResult(
        state: ReadinessState.bodyVisibilityCheck,
        canStartTracking: false,
        remainingSeconds: countdownSeconds,
        blocker: missingVisibilityBlocker,
      );
    }

    if ((frame.derivedMetrics['start_pose_valid'] ?? 0) < 0.5) {
      _countdownAnchorSeconds = null;
      return ReadinessResult(
        state: ReadinessState.startPoseCheck,
        canStartTracking: false,
        remainingSeconds: countdownSeconds,
        blocker: 'Hold the start position',
      );
    }

    _countdownAnchorSeconds ??= elapsedSeconds;
    final remaining =
        countdownSeconds - (elapsedSeconds - _countdownAnchorSeconds!);
    if (remaining > 0) {
      return ReadinessResult(
        state: ReadinessState.countdownReady,
        canStartTracking: false,
        remainingSeconds: remaining,
      );
    }

    return const ReadinessResult(
      state: ReadinessState.activeTracking,
      canStartTracking: true,
      remainingSeconds: 0,
    );
  }

  ReadinessResult _evaluateCountdownOnly({required int elapsedSeconds}) {
    _countdownAnchorSeconds ??= 0;
    final remaining =
        countdownSeconds - (elapsedSeconds - _countdownAnchorSeconds!);
    if (remaining > 0) {
      return ReadinessResult(
        state: ReadinessState.countdownReady,
        canStartTracking: false,
        remainingSeconds: remaining,
      );
    }

    return const ReadinessResult(
      state: ReadinessState.activeTracking,
      canStartTracking: true,
      remainingSeconds: 0,
    );
  }

  bool _isViewSatisfied(ExerciseView detectedView) {
    if (requiredView == ExerciseView.side) {
      return detectedView == ExerciseView.side ||
          detectedView == ExerciseView.leftSide ||
          detectedView == ExerciseView.rightSide;
    }
    return detectedView == requiredView;
  }

  bool _hasSingleSideFallback(PoseFrame frame) {
    final hasLeftSide =
        frame.hasVisible(Joint.leftShoulder) && frame.hasVisible(Joint.leftHip);
    final hasRightSide = frame.hasVisible(Joint.rightShoulder) &&
        frame.hasVisible(Joint.rightHip);
    return hasLeftSide || hasRightSide;
  }

  String? _missingVisibilityBlocker(PoseFrame frame) {
    if (visibilityJointGroups.isNotEmpty) {
      for (final group in visibilityJointGroups) {
        final groupVisible = group.every(frame.hasVisible);
        if (groupVisible) {
          return null;
        }
      }
      return requiredView == ExerciseView.side
          ? 'Keep one full side visible'
          : 'Stand fully in frame';
    }

    for (final joint in requiredJoints) {
      if (!frame.hasVisible(joint)) {
        return '${joint.name} is not visible';
      }
    }
    return null;
  }
}
