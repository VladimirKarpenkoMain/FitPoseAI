import 'package:fitness_ai/analysis/pose_frame.dart';
import 'package:fitness_ai/analysis/profiles/jumping_jack_profile.dart';
import 'package:fitness_ai/analysis/profiles/pushup_profile.dart';
import 'package:fitness_ai/analysis/profiles/squat_profile.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SquatProfile flags shallow depth from summarized repetition metrics',
      () {
    final profile = SquatProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({'phase_knee_angle': 176, 'phase_torso_vertical_tilt': 10}),
      _frame({'phase_knee_angle': 112, 'phase_torso_vertical_tilt': 22}),
      _frame({'phase_knee_angle': 108, 'phase_torso_vertical_tilt': 18}),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.depthTooShallow));
  });

  test('PushupProfile flags hip sag from summarized repetition metrics', () {
    final profile = PushupProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({'phase_elbow_angle': 170, 'phase_body_line_angle': 176}),
      _frame({'phase_elbow_angle': 104, 'phase_body_line_angle': 160}),
      _frame({'phase_elbow_angle': 92, 'phase_body_line_angle': 158}),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.hipSag));
  });

  test('JumpingJackProfile flags incomplete arm and leg opening', () {
    final profile = JumpingJackProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({'phase_arm_open': 20, 'phase_leg_open': 14}),
      _frame({'phase_arm_open': 132, 'phase_leg_open': 32}),
      _frame({'phase_arm_open': 148, 'phase_leg_open': 38}),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.armsIncompleteOverhead));
    expect(issues, contains(TechniqueIssue.legsNotWideEnough));
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
