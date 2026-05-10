import 'package:fitness_ai/analysis/plank_hold_analyzer.dart';
import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/profiles/plank_profile.dart';
import 'package:fitness_ai/analysis/readiness_evaluator.dart';
import 'package:fitness_ai/analysis/workout_analyzer.dart';
import 'package:fitness_ai/models/exercise_type.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlankProfile', () {
    test(
        'reports holding_good when body line and shoulder-elbow alignment hold',
        () {
      final profile = PlankProfile();

      final result = profile.evaluateHold(_frame(
        bodyLineAngle: 176,
        hipOffset: 0.02,
        shoulderElbowOffset: 0.06,
      ));

      expect(result.status, PlankHoldStatus.holdingGood);
      expect(result.issues, isEmpty);
    });

    test('reports hip_sag when hips drop below the shoulder-ankle line', () {
      final profile = PlankProfile();

      final result = profile.evaluateHold(_frame(
        bodyLineAngle: 157,
        hipOffset: 0.18,
        shoulderElbowOffset: 0.06,
      ));

      expect(result.status, PlankHoldStatus.hipSag);
      expect(result.issues, contains(TechniqueIssue.hipSag));
    });

    test('reports hips_too_high when hips rise above the shoulder-ankle line',
        () {
      final profile = PlankProfile();

      final result = profile.evaluateHold(_frame(
        bodyLineAngle: 158,
        hipOffset: -0.18,
        shoulderElbowOffset: 0.06,
      ));

      expect(result.status, PlankHoldStatus.hipsTooHigh);
      expect(result.issues, contains(TechniqueIssue.hipsTooHigh));
    });

    test('reports lost_position when shoulders drift away from elbows', () {
      final profile = PlankProfile();

      final result = profile.evaluateHold(_frame(
        bodyLineAngle: 174,
        hipOffset: 0.02,
        shoulderElbowOffset: 0.24,
      ));

      expect(result.status, PlankHoldStatus.lostPosition);
      expect(result.issues, contains(TechniqueIssue.shouldersNotOverElbows));
    });

    test('reports neck_not_neutral when the head breaks the spine line', () {
      final profile = PlankProfile();

      final result = profile.evaluateHold(_frame(
        bodyLineAngle: 174,
        hipOffset: 0.02,
        shoulderElbowOffset: 0.06,
        neckDeviation: 22,
      ));

      expect(result.status, PlankHoldStatus.lostPosition);
      expect(result.issues, contains(TechniqueIssue.neckNotNeutral));
    });

    test('reports knees_bent when legs are not extended', () {
      final profile = PlankProfile();

      final result = profile.evaluateHold(_frame(
        bodyLineAngle: 174,
        hipOffset: 0.02,
        shoulderElbowOffset: 0.06,
        kneeAngle: 154,
      ));

      expect(result.status, PlankHoldStatus.lostPosition);
      expect(result.issues, contains(TechniqueIssue.kneesBent));
    });

    test('reports elbow_angle_out_of_range when elbow is not near 90 degrees',
        () {
      final profile = PlankProfile();

      final result = profile.evaluateHold(_frame(
        bodyLineAngle: 174,
        hipOffset: 0.02,
        shoulderElbowOffset: 0.06,
        elbowAngle: 128,
      ));

      expect(result.status, PlankHoldStatus.lostPosition);
      expect(result.issues, contains(TechniqueIssue.elbowAngleOutOfRange));
    });
  });

  test('PlankHoldAnalyzer never increments repetition count', () {
    final analyzer = PlankHoldAnalyzer(profile: PlankProfile());

    analyzer.process(_frame(
      timestampMs: 0,
      bodyLineAngle: 176,
      hipOffset: 0.02,
      shoulderElbowOffset: 0.06,
    ));
    final update = analyzer.process(_frame(
      timestampMs: 100,
      bodyLineAngle: 176,
      hipOffset: 0.02,
      shoulderElbowOffset: 0.06,
    ));

    expect(update.repUpdate, isNull);
    expect(update.holdUpdate.status, PlankHoldStatus.holdingGood);
    expect(update.holdUpdate.holdDuration, const Duration(milliseconds: 100));
  });

  test('PlankHoldAnalyzer keeps good hold through transient noisy frames', () {
    final analyzer = PlankHoldAnalyzer(
      profile: PlankProfile(),
      invalidGrace: const Duration(milliseconds: 300),
    );

    analyzer.process(_frame(
      timestampMs: 0,
      bodyLineAngle: 176,
      hipOffset: 0.02,
      shoulderElbowOffset: 0.06,
    ));
    final noisyUpdate = analyzer.process(_frame(
      timestampMs: 100,
      bodyLineAngle: 154,
      hipOffset: 0.18,
      shoulderElbowOffset: 0.06,
    ));
    final recoveredUpdate = analyzer.process(_frame(
      timestampMs: 200,
      bodyLineAngle: 176,
      hipOffset: 0.02,
      shoulderElbowOffset: 0.06,
    ));

    expect(noisyUpdate.holdUpdate.status, PlankHoldStatus.holdingGood);
    expect(noisyUpdate.holdUpdate.issues, isEmpty);
    expect(
      recoveredUpdate.holdUpdate.validHoldDuration,
      const Duration(milliseconds: 200),
    );
    expect(recoveredUpdate.holdUpdate.invalidHoldDuration, Duration.zero);
  });

  test('PlankHoldAnalyzer moves sustained issues into invalid hold time', () {
    final analyzer = PlankHoldAnalyzer(
      profile: PlankProfile(),
      invalidGrace: const Duration(milliseconds: 300),
    );

    analyzer.process(_frame(
      timestampMs: 0,
      bodyLineAngle: 176,
      hipOffset: 0.02,
      shoulderElbowOffset: 0.06,
    ));
    analyzer.process(_frame(
      timestampMs: 100,
      bodyLineAngle: 176,
      hipOffset: 0.02,
      shoulderElbowOffset: 0.06,
    ));
    analyzer.process(_frame(
      timestampMs: 200,
      bodyLineAngle: 154,
      hipOffset: 0.18,
      shoulderElbowOffset: 0.06,
    ));
    analyzer.process(_frame(
      timestampMs: 300,
      bodyLineAngle: 154,
      hipOffset: 0.18,
      shoulderElbowOffset: 0.06,
    ));
    analyzer.process(_frame(
      timestampMs: 400,
      bodyLineAngle: 154,
      hipOffset: 0.18,
      shoulderElbowOffset: 0.06,
    ));
    final update = analyzer.process(_frame(
      timestampMs: 500,
      bodyLineAngle: 154,
      hipOffset: 0.18,
      shoulderElbowOffset: 0.06,
    ));

    expect(update.holdUpdate.status, PlankHoldStatus.hipSag);
    expect(
      update.holdUpdate.validHoldDuration,
      const Duration(milliseconds: 400),
    );
    expect(
      update.holdUpdate.invalidHoldDuration,
      const Duration(milliseconds: 100),
    );
    expect(update.holdUpdate.holdDuration, update.holdUpdate.validHoldDuration);
  });

  test('WorkoutAnalyzer routes plank frames through hold analysis', () {
    final analyzer = WorkoutAnalyzer(ExerciseType.plank);

    final result = analyzer.processFrame(
      _frame(
        bodyLineAngle: 176,
        hipOffset: 0.02,
        shoulderElbowOffset: 0.06,
      ),
      readiness: const ReadinessResult(
        state: ReadinessState.activeTracking,
        canStartTracking: true,
        remainingSeconds: 0,
      ),
    );

    expect(result.repUpdate, isNull);
    expect(result.holdUpdate?.status, PlankHoldStatus.holdingGood);
    expect(result.systemStatus, 'holding_good');
  });
}

PoseFrame _frame({
  int timestampMs = 100,
  required double bodyLineAngle,
  required double hipOffset,
  required double shoulderElbowOffset,
  double elbowAngle = 90,
  double kneeAngle = 176,
  double neckDeviation = 4,
}) {
  return PoseFrame(
    frameIndex: 1,
    timestampMs: timestampMs,
    landmarks: const {},
    derivedMetrics: {
      'hold_body_line_angle': bodyLineAngle,
      'hold_hip_offset': hipOffset,
      'hold_shoulder_elbow_offset': shoulderElbowOffset,
      'hold_elbow_angle': elbowAngle,
      'hold_knee_angle': kneeAngle,
      'hold_neck_deviation': neckDeviation,
      'avg_landmark_confidence': 0.95,
    },
  );
}
