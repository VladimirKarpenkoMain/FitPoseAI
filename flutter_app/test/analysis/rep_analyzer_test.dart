import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/profiles/squat_profile.dart';
import 'package:fitness_ai/analysis/rep_analyzer.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepAnalyzer', () {
    test(
        'counts a rep after returning from bottom through an intermediate phase',
        () {
      final analyzer = RepAnalyzer(profile: SquatProfile());

      final frames = <PoseFrame>[
        _squatFrame(
            frameIndex: 0, timestampMs: 0, kneeAngle: 176, hipAngle: 176),
        _squatFrame(
            frameIndex: 1, timestampMs: 100, kneeAngle: 176, hipAngle: 176),
        _squatFrame(
            frameIndex: 2, timestampMs: 200, kneeAngle: 145, hipAngle: 138),
        _squatFrame(
            frameIndex: 3, timestampMs: 300, kneeAngle: 145, hipAngle: 138),
        _squatFrame(
            frameIndex: 4, timestampMs: 400, kneeAngle: 108, hipAngle: 102),
        _squatFrame(
            frameIndex: 5, timestampMs: 500, kneeAngle: 108, hipAngle: 102),
        _squatFrame(
            frameIndex: 6, timestampMs: 600, kneeAngle: 142, hipAngle: 136),
        _squatFrame(
            frameIndex: 7, timestampMs: 700, kneeAngle: 142, hipAngle: 136),
        _squatFrame(
            frameIndex: 8, timestampMs: 800, kneeAngle: 173, hipAngle: 170),
        _squatFrame(
            frameIndex: 9, timestampMs: 900, kneeAngle: 173, hipAngle: 170),
      ];

      RepUpdate? lastUpdate;
      for (final frame in frames) {
        lastUpdate = analyzer.process(frame);
      }

      expect(lastUpdate, isNotNull);
      expect(lastUpdate!.countIncremented, isTrue);
      expect(lastUpdate.repCount, 1);
      expect(lastUpdate.repAnalysis, isNotNull);
      expect(
        lastUpdate.repAnalysis!.visitedPhases,
        containsAllInOrder([
          MotionPhase.descent.name,
          MotionPhase.bottom.name,
          MotionPhase.lockout.name,
        ]),
      );
      expect(lastUpdate.repAnalysis!.startedTimestampMs, 200);
      expect(lastUpdate.repAnalysis!.finishedTimestampMs, 900);
    });

    test('does not count a rep if the target depth phase was never reached',
        () {
      final analyzer = RepAnalyzer(profile: SquatProfile());

      final frames = <PoseFrame>[
        _squatFrame(
            frameIndex: 0, timestampMs: 0, kneeAngle: 176, hipAngle: 176),
        _squatFrame(
            frameIndex: 1, timestampMs: 100, kneeAngle: 176, hipAngle: 176),
        _squatFrame(
            frameIndex: 2, timestampMs: 200, kneeAngle: 146, hipAngle: 140),
        _squatFrame(
            frameIndex: 3, timestampMs: 300, kneeAngle: 146, hipAngle: 140),
        _squatFrame(
            frameIndex: 4, timestampMs: 400, kneeAngle: 155, hipAngle: 148),
        _squatFrame(
            frameIndex: 5, timestampMs: 500, kneeAngle: 155, hipAngle: 148),
        _squatFrame(
            frameIndex: 6, timestampMs: 600, kneeAngle: 174, hipAngle: 170),
        _squatFrame(
            frameIndex: 7, timestampMs: 700, kneeAngle: 174, hipAngle: 170),
      ];

      RepUpdate? lastUpdate;
      for (final frame in frames) {
        lastUpdate = analyzer.process(frame);
      }

      expect(lastUpdate, isNotNull);
      expect(lastUpdate!.countIncremented, isFalse);
      expect(lastUpdate.repCount, 0);
      expect(lastUpdate.repAnalysis, isNull);
    });

    test('does not count a rep that returns to lockout too quickly', () {
      final analyzer = RepAnalyzer(profile: SquatProfile());

      final frames = <PoseFrame>[
        _squatFrame(
            frameIndex: 0, timestampMs: 0, kneeAngle: 176, hipAngle: 176),
        _squatFrame(
            frameIndex: 1, timestampMs: 100, kneeAngle: 176, hipAngle: 176),
        _squatFrame(
            frameIndex: 2, timestampMs: 200, kneeAngle: 112, hipAngle: 108),
        _squatFrame(
            frameIndex: 3, timestampMs: 300, kneeAngle: 112, hipAngle: 108),
        _squatFrame(
            frameIndex: 4, timestampMs: 400, kneeAngle: 174, hipAngle: 170),
        _squatFrame(
            frameIndex: 5, timestampMs: 500, kneeAngle: 174, hipAngle: 170),
      ];

      RepUpdate? lastUpdate;
      for (final frame in frames) {
        lastUpdate = analyzer.process(frame);
      }

      expect(lastUpdate, isNotNull);
      expect(lastUpdate!.countIncremented, isFalse);
      expect(lastUpdate.repCount, 0);
    });

    test(
        'records issue events with frame metadata and deduplicates repeated live issues',
        () {
      final analyzer = RepAnalyzer(profile: SquatProfile());

      final frames = <PoseFrame>[
        _squatFrame(
            frameIndex: 0, timestampMs: 0, kneeAngle: 176, hipAngle: 176),
        _squatFrame(
            frameIndex: 1, timestampMs: 100, kneeAngle: 176, hipAngle: 176),
        _squatFrame(
            frameIndex: 2,
            timestampMs: 200,
            kneeAngle: 145,
            hipAngle: 136,
            torsoTilt: 42),
        _squatFrame(
            frameIndex: 3,
            timestampMs: 300,
            kneeAngle: 145,
            hipAngle: 136,
            torsoTilt: 41),
        _squatFrame(
            frameIndex: 4,
            timestampMs: 400,
            kneeAngle: 108,
            hipAngle: 102,
            torsoTilt: 43),
        _squatFrame(
            frameIndex: 5,
            timestampMs: 500,
            kneeAngle: 108,
            hipAngle: 102,
            torsoTilt: 44),
        _squatFrame(
            frameIndex: 6,
            timestampMs: 600,
            kneeAngle: 142,
            hipAngle: 136,
            torsoTilt: 40),
        _squatFrame(
            frameIndex: 7,
            timestampMs: 700,
            kneeAngle: 142,
            hipAngle: 136,
            torsoTilt: 39),
        _squatFrame(
            frameIndex: 8, timestampMs: 800, kneeAngle: 173, hipAngle: 170),
        _squatFrame(
            frameIndex: 9, timestampMs: 900, kneeAngle: 173, hipAngle: 170),
      ];

      RepUpdate? lastUpdate;
      for (final frame in frames) {
        lastUpdate = analyzer.process(frame);
      }

      final repAnalysis = lastUpdate!.repAnalysis!;
      final leanEvents = repAnalysis.issueEvents
          .where((event) =>
              event.code == TechniqueIssue.excessiveForwardLean.apiValue)
          .toList();

      expect(leanEvents, hasLength(1));
      expect(leanEvents.single.frameIndex, 2);
      expect(leanEvents.single.timestampMs, 200);
      expect(leanEvents.single.phase, MotionPhase.descent);
      expect(leanEvents.single.metricName, 'phase_torso_vertical_tilt');
      expect(leanEvents.single.severity, IssueSeverity.moderate);
      expect(repAnalysis.issues, contains(TechniqueIssue.excessiveForwardLean));
    });
  });
}

PoseFrame _squatFrame({
  required int frameIndex,
  required int timestampMs,
  required double kneeAngle,
  required double hipAngle,
  double torsoTilt = 12,
}) {
  return PoseFrame(
    frameIndex: frameIndex,
    timestampMs: timestampMs,
    landmarks: const {},
    derivedMetrics: {
      'phase_knee_angle': kneeAngle,
      'phase_hip_angle': hipAngle,
      'phase_torso_lean': torsoTilt,
      'phase_torso_vertical_tilt': torsoTilt,
      'avg_landmark_confidence': 0.95,
      'start_pose_valid': kneeAngle > 165 && hipAngle > 160 ? 1 : 0,
    },
  );
}
