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
  static const int _viewSwitchDwellFrames = 3;

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
  ExerciseView? _stableDetectedView;
  ExerciseView? _pendingDetectedView;
  int _pendingDetectedViewFrames = 0;

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

    final rawDetectedView = _detectViewWithFallback(frame);
    final detectedView = _smoothedView(rawDetectedView);
    final viewSatisfied = _isViewSatisfied(detectedView);
    if (!viewSatisfied) {
      _countdownAnchorSeconds = null;
      return ReadinessResult(
        state: ReadinessState.viewAlignment,
        canStartTracking: false,
        remainingSeconds: countdownSeconds,
        blocker: _viewBlockerFor(detectedView),
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

  ExerciseView _detectViewWithFallback(PoseFrame frame) {
    final detectedView = _viewDetector.detect(frame).view;
    if (requiredView == ExerciseView.side &&
        detectedView == ExerciseView.unknown &&
        _hasSingleSideFallback(frame)) {
      return ExerciseView.side;
    }
    return detectedView;
  }

  ExerciseView _smoothedView(ExerciseView detectedView) {
    if (detectedView == ExerciseView.unknown) {
      _pendingDetectedView = null;
      _pendingDetectedViewFrames = 0;
      return _stableDetectedView ?? ExerciseView.unknown;
    }

    final stableView = _stableDetectedView;
    if (stableView == null) {
      _stableDetectedView = detectedView;
      return detectedView;
    }

    if (detectedView == stableView) {
      _pendingDetectedView = null;
      _pendingDetectedViewFrames = 0;
      return stableView;
    }

    if (_pendingDetectedView != detectedView) {
      _pendingDetectedView = detectedView;
      _pendingDetectedViewFrames = 1;
      return stableView;
    }

    _pendingDetectedViewFrames++;
    if (_pendingDetectedViewFrames < _viewSwitchDwellFrames) {
      return stableView;
    }

    _stableDetectedView = detectedView;
    _pendingDetectedView = null;
    _pendingDetectedViewFrames = 0;
    return detectedView;
  }

  bool _hasSingleSideFallback(PoseFrame frame) {
    final hasLeftSide =
        frame.hasVisible(Joint.leftShoulder) && frame.hasVisible(Joint.leftHip);
    final hasRightSide = frame.hasVisible(Joint.rightShoulder) &&
        frame.hasVisible(Joint.rightHip);
    return hasLeftSide != hasRightSide;
  }

  String _viewBlockerFor(ExerciseView detectedView) {
    if (requiredView == ExerciseView.front) {
      return 'Face the camera';
    }
    if (detectedView == ExerciseView.unknown) {
      return 'Keep one full side visible';
    }
    return 'Turn to your side';
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
