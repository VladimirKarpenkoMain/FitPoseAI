import '../models/workout_analysis.dart';
import 'pose_frame.dart';

class RepAttempt {
  RepAttempt({
    required this.repIndex,
    required this.startedFrame,
    required this.startedTimestampMs,
    required this.startPhase,
  }) : currentPhase = startPhase;

  final int repIndex;
  final int startedFrame;
  final int startedTimestampMs;
  final MotionPhase startPhase;

  int? finishedFrame;
  int? finishedTimestampMs;
  bool visitedTargetPhase = false;
  bool isCompleted = false;
  bool isValid = false;
  MotionPhase currentPhase;
  final Set<MotionPhase> visitedPhases = <MotionPhase>{};
  final List<PoseFrame> frames = <PoseFrame>[];
  final List<RepIssueEvent> issueEvents = <RepIssueEvent>[];
  final Map<String, double> minMetrics = <String, double>{};
  final Map<String, double> maxMetrics = <String, double>{};
  final Map<String, double> avgMetrics = <String, double>{};
  final Map<String, double> _metricSums = <String, double>{};
  final Map<String, int> _metricCounts = <String, int>{};
  final Map<String, int> _lastIssueFrameByCode = <String, int>{};

  int get frameCount => frames.length;

  void addFrame(
    PoseFrame frame, {
    required MotionPhase phase,
    required Map<String, double> metrics,
  }) {
    frames.add(frame);
    currentPhase = phase;
    visitedPhases.add(phase);

    for (final entry in metrics.entries) {
      final key = entry.key;
      final value = entry.value;
      minMetrics.update(key, (current) => value < current ? value : current,
          ifAbsent: () => value);
      maxMetrics.update(key, (current) => value > current ? value : current,
          ifAbsent: () => value);
      _metricSums.update(key, (current) => current + value,
          ifAbsent: () => value);
      _metricCounts.update(key, (current) => current + 1, ifAbsent: () => 1);
      avgMetrics[key] = _metricSums[key]! / _metricCounts[key]!;
    }
  }

  bool shouldRecordIssue({
    required String code,
    required int frameIndex,
    required int cooldownFrames,
  }) {
    final lastFrame = _lastIssueFrameByCode[code];
    if (lastFrame == null) {
      _lastIssueFrameByCode[code] = frameIndex;
      return true;
    }
    if (frameIndex - lastFrame >= cooldownFrames) {
      _lastIssueFrameByCode[code] = frameIndex;
      return true;
    }
    return false;
  }
}
