import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/profiles/shoulder_press_profile.dart';
import 'package:fitness_ai/analysis/rep_analyzer.dart';
import 'package:fitness_ai/analysis/workout_analyzer.dart';
import 'package:fitness_ai/models/exercise_type.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ShoulderPressProfile tracks from lowered arms through overhead lockout',
      () {
    final profile = ShoulderPressProfile();

    expect(
      profile.detectPhase(
        _frame({'phase_shoulder_angle': 92, 'phase_elbow_angle': 88}),
        MotionPhase.closed,
      ),
      MotionPhase.closed,
    );
    expect(
      profile.detectPhase(
        _frame({'phase_shoulder_angle': 118, 'phase_elbow_angle': 138}),
        MotionPhase.closed,
      ),
      MotionPhase.opening,
    );
    expect(
      profile.detectPhase(
        _frame({'phase_shoulder_angle': 164, 'phase_elbow_angle': 169}),
        MotionPhase.opening,
      ),
      MotionPhase.open,
    );
  });

  test('ShoulderPressProfile flags incomplete extension and lockout issues',
      () {
    final profile = ShoulderPressProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_shoulder_angle': 62,
        'phase_elbow_angle': 122,
        'phase_wrist_above_shoulder': 0,
      }),
      _frame({
        'phase_shoulder_angle': 138,
        'phase_elbow_angle': 151,
        'phase_wrist_above_shoulder': 0,
      }),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.incompleteExtension));
    expect(issues, contains(TechniqueIssue.poorLockout));
  });

  test('ShoulderPressProfile ignores front-only symmetry metrics in side view',
      () {
    final profile = ShoulderPressProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_shoulder_angle': 164,
        'phase_elbow_angle': 170,
        'phase_wrist_above_shoulder': 1,
        'phase_left_right_symmetry': 42,
        'phase_elbow_width_ratio': 4.0,
      }),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, isNot(contains(TechniqueIssue.asymmetry)));
    expect(issues, isNot(contains(TechniqueIssue.elbowsTooWide)));
  });

  test(
      'ShoulderPressProfile flags dumbbell arm asymmetry when both arms visible',
      () {
    final profile = ShoulderPressProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_shoulder_angle': 164,
        'phase_elbow_angle': 170,
        'phase_wrist_above_shoulder': 1,
        'phase_left_right_symmetry': 22,
        'phase_wrist_height_asymmetry': 0.06,
        'phase_bilateral_arm_metrics': 1,
      }),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.asymmetry));
  });

  test(
      'ShoulderPressProfile counts overhead reach when elbow angle is slightly under strict lockout',
      () {
    final analyzer = RepAnalyzer(profile: ShoulderPressProfile());
    RepUpdate? update;

    for (final metrics in <Map<String, double>>[
      {
        'phase_shoulder_angle': 45,
        'phase_elbow_angle': 175,
        'phase_wrist_above_shoulder': 0,
      },
      {
        'phase_shoulder_angle': 92,
        'phase_elbow_angle': 120,
        'phase_wrist_above_shoulder': 1,
      },
      {
        'phase_shoulder_angle': 130,
        'phase_elbow_angle': 145,
        'phase_wrist_above_shoulder': 1,
      },
      {
        'phase_shoulder_angle': 152,
        'phase_elbow_angle': 152,
        'phase_wrist_above_shoulder': 1,
      },
      {
        'phase_shoulder_angle': 155,
        'phase_elbow_angle': 154,
        'phase_wrist_above_shoulder': 1,
      },
      {
        'phase_shoulder_angle': 140,
        'phase_elbow_angle': 150,
        'phase_wrist_above_shoulder': 1,
      },
      {
        'phase_shoulder_angle': 98,
        'phase_elbow_angle': 132,
        'phase_wrist_above_shoulder': 1,
      },
      {
        'phase_shoulder_angle': 94,
        'phase_elbow_angle': 168,
        'phase_wrist_above_shoulder': 0,
      },
      {
        'phase_shoulder_angle': 92,
        'phase_elbow_angle': 174,
        'phase_wrist_above_shoulder': 0,
      },
      {
        'phase_shoulder_angle': 90,
        'phase_elbow_angle': 174,
        'phase_wrist_above_shoulder': 0,
      },
    ]) {
      update = analyzer.process(_frame(metrics));
    }

    expect(update!.repCount, 1);
    expect(update.countIncremented, isTrue);
  });

  test('ShoulderPressProfile does not reopen a rep after lowering starts', () {
    final profile = ShoulderPressProfile();

    expect(
      profile.detectPhase(
        _frame({
          'phase_shoulder_angle': 157,
          'phase_elbow_angle': 153,
          'phase_wrist_above_shoulder': 1,
        }),
        MotionPhase.closing,
      ),
      MotionPhase.closing,
    );
  });

  test('WorkoutAnalyzer builds shoulder press profile from exercise type', () {
    final analyzer = WorkoutAnalyzer(ExerciseType.shoulderPress);

    expect(analyzer.profile, isA<ShoulderPressProfile>());
    expect(analyzer.profile.requiredView, ExerciseView.side);
  });

  test('ShoulderPressProfile flags side-view strict press faults', () {
    final profile = ShoulderPressProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_shoulder_angle': 72,
        'phase_elbow_angle': 92,
        'phase_wrist_angle': 172,
        'phase_knee_angle': 176,
        'phase_torso_angle_from_vertical': 4,
        'phase_hand_forward_offset': 0.04,
      }),
      _frame({
        'phase_shoulder_angle': 132,
        'phase_elbow_angle': 150,
        'phase_wrist_angle': 146,
        'phase_knee_angle': 148,
        'phase_torso_angle_from_vertical': 18,
        'phase_hand_forward_offset': 0.24,
        'phase_wrist_above_shoulder': 1,
      }),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.kneeDrive));
    expect(issues, contains(TechniqueIssue.excessiveBackLean));
    expect(issues, contains(TechniqueIssue.dumbbellsForward));
    expect(issues, contains(TechniqueIssue.wristBentBack));
  });

  test('ShoulderPressProfile ignores brief soft-knee tracking noise', () {
    final profile = ShoulderPressProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_shoulder_angle': 152,
        'phase_elbow_angle': 170,
        'phase_knee_angle': 171,
        'phase_wrist_above_shoulder': 1,
      }),
      _frame({
        'phase_shoulder_angle': 176,
        'phase_elbow_angle': 174,
        'phase_knee_angle': 160,
        'phase_wrist_above_shoulder': 1,
      }),
      _frame({
        'phase_shoulder_angle': 170,
        'phase_elbow_angle': 172,
        'phase_knee_angle': 166,
        'phase_wrist_above_shoulder': 1,
      }),
    ]);

    expect(
      profile.detectFinalIssues(metrics),
      isNot(contains(TechniqueIssue.kneeDrive)),
    );
  });

  test('ShoulderPressProfile accepts strict side-view press metrics', () {
    final profile = ShoulderPressProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_shoulder_angle': 78,
        'phase_elbow_angle': 95,
        'phase_wrist_angle': 170,
        'phase_knee_angle': 176,
        'phase_torso_angle_from_vertical': 5,
        'phase_hand_forward_offset': 0.03,
        'phase_wrist_above_shoulder': 0,
      }),
      _frame({
        'phase_shoulder_angle': 164,
        'phase_elbow_angle': 170,
        'phase_wrist_angle': 168,
        'phase_knee_angle': 172,
        'phase_torso_angle_from_vertical': 7,
        'phase_hand_forward_offset': 0.06,
        'phase_wrist_above_shoulder': 1,
      }),
    ]);

    expect(profile.detectFinalIssues(metrics), isEmpty);
  });
}

PoseFrame _frame(Map<String, double> metrics) {
  return PoseFrame(
    frameIndex: 0,
    timestampMs: 0,
    landmarks: const {},
    derivedMetrics: metrics,
  );
}
