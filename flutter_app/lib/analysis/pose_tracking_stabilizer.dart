import 'pose_frame.dart';

class PoseTrackingStabilizer {
  PoseTrackingStabilizer({
    this.missingPoseTolerance = const Duration(milliseconds: 350),
  });

  final Duration missingPoseTolerance;

  PoseFrame? _lastFrame;
  int? _lastSeenAtMs;

  PoseFrame? stabilize({
    required PoseFrame? frame,
    required Duration elapsed,
  }) {
    if (frame != null) {
      _lastFrame = frame;
      _lastSeenAtMs = elapsed.inMilliseconds;
      return frame;
    }

    final lastFrame = _lastFrame;
    final lastSeenAtMs = _lastSeenAtMs;
    if (lastFrame == null || lastSeenAtMs == null) {
      return null;
    }

    if (elapsed.inMilliseconds - lastSeenAtMs <=
        missingPoseTolerance.inMilliseconds) {
      return lastFrame;
    }

    _lastFrame = null;
    _lastSeenAtMs = null;
    return null;
  }

  void reset() {
    _lastFrame = null;
    _lastSeenAtMs = null;
  }
}
