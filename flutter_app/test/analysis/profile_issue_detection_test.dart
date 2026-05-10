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
      _frame({
        'phase_elbow_angle': 170,
        'phase_body_line_angle': 176,
        'phase_hip_offset': 0.02,
      }),
      _frame({
        'phase_elbow_angle': 104,
        'phase_body_line_angle': 160,
        'phase_hip_offset': 0.16,
      }),
      _frame({
        'phase_elbow_angle': 92,
        'phase_body_line_angle': 158,
        'phase_hip_offset': 0.18,
      }),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.hipSag));
  });

  test('PushupProfile flags pike position separately from hip sag', () {
    final profile = PushupProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_elbow_angle': 170,
        'phase_body_line_angle': 176,
        'phase_hip_offset': 0.02,
      }),
      _frame({
        'phase_elbow_angle': 96,
        'phase_body_line_angle': 160,
        'phase_hip_offset': -0.17,
      }),
      _frame({
        'phase_elbow_angle': 164,
        'phase_body_line_angle': 170,
        'phase_hip_offset': -0.04,
      }),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.pikePosition));
    expect(issues, isNot(contains(TechniqueIssue.hipSag)));
  });

  test('PushupProfile flags shallow depth and incomplete top lockout', () {
    final profile = PushupProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_elbow_angle': 154,
        'phase_body_line_angle': 176,
        'phase_hip_offset': 0.02,
      }),
      _frame({
        'phase_elbow_angle': 112,
        'phase_body_line_angle': 174,
        'phase_hip_offset': 0.04,
      }),
      _frame({
        'phase_elbow_angle': 156,
        'phase_body_line_angle': 176,
        'phase_hip_offset': 0.02,
      }),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.insufficientDepth));
    expect(issues, contains(TechniqueIssue.incompleteTopLockout));
  });

  test('PushupProfile emits live pike cue from hip offset direction', () {
    final profile = PushupProfile();

    final issues = profile.detectLiveIssues(
      frame: _frame({
        'phase_elbow_angle': 112,
        'phase_body_line_angle': 160,
        'phase_hip_offset': -0.18,
        'avg_landmark_confidence': 0.95,
      }),
      phase: MotionPhase.descent,
    );

    expect(issues.single.issue, TechniqueIssue.pikePosition);
    expect(issues.single.metricName, 'phase_hip_offset');
  });

  test('PushupProfile flags shoulders and hips moving out of sync', () {
    final profile = PushupProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_elbow_angle': 170,
        'phase_body_line_angle': 176,
        'phase_hip_offset': 0.02,
        'phase_shoulder_y': 100,
        'phase_hip_y': 140,
      }),
      _frame({
        'phase_elbow_angle': 94,
        'phase_body_line_angle': 174,
        'phase_hip_offset': 0.03,
        'phase_shoulder_y': 160,
        'phase_hip_y': 200,
      }),
      _frame({
        'phase_elbow_angle': 132,
        'phase_body_line_angle': 172,
        'phase_hip_offset': 0.04,
        'phase_shoulder_y': 110,
        'phase_hip_y': 190,
      }),
      _frame({
        'phase_elbow_angle': 164,
        'phase_body_line_angle': 176,
        'phase_hip_offset': 0.02,
        'phase_shoulder_y': 100,
        'phase_hip_y': 140,
      }),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.poorSynchronization));
  });

  test('PushupProfile flags head dropping when head falls below shoulders', () {
    final profile = PushupProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_elbow_angle': 170,
        'phase_body_line_angle': 176,
        'phase_hip_offset': 0.02,
        'phase_head_shoulder_drop': 0.02,
      }),
      _frame({
        'phase_elbow_angle': 92,
        'phase_body_line_angle': 174,
        'phase_hip_offset': 0.03,
        'phase_head_shoulder_drop': 0.18,
      }),
      _frame({
        'phase_elbow_angle': 164,
        'phase_body_line_angle': 176,
        'phase_hip_offset': 0.02,
        'phase_head_shoulder_drop': 0.04,
      }),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.headDropping));
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

  test('JumpingJackProfile uses ankle width ratio to detect open phase', () {
    final profile = JumpingJackProfile();

    final phase = profile.detectPhase(
      _frame({
        'phase_arm_open': 152,
        'phase_feet_width_ratio': 1.34,
        'phase_feet_closed_ratio': 1.8,
      }),
      MotionPhase.closed,
    );

    expect(phase, MotionPhase.open);
  });

  test('JumpingJackProfile tolerates small arm and foot peak delay', () {
    final profile = JumpingJackProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_arm_open': 28,
        'phase_feet_width_ratio': 0.32,
        'phase_feet_closed_ratio': 0.75,
        'phase_torso_side_tilt': 4,
        'phase_left_right_asymmetry': 0.04,
      }, timestampMs: 0),
      _frame({
        'phase_arm_open': 156,
        'phase_feet_width_ratio': 1.18,
        'phase_feet_closed_ratio': 2.4,
        'phase_torso_side_tilt': 6,
        'phase_left_right_asymmetry': 0.05,
      }, timestampMs: 1000),
      _frame({
        'phase_arm_open': 152,
        'phase_feet_width_ratio': 1.36,
        'phase_feet_closed_ratio': 2.8,
        'phase_torso_side_tilt': 5,
        'phase_left_right_asymmetry': 0.04,
      }, timestampMs: 1280),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(metrics['peak_sync_gap_ms'], 280);
    expect(issues, isNot(contains(TechniqueIssue.poorSynchronization)));
    expect(issues, isNot(contains(TechniqueIssue.armsIncompleteOverhead)));
    expect(issues, isNot(contains(TechniqueIssue.legsNotWideEnough)));
  });

  test('JumpingJackProfile flags large arm and foot peak delay', () {
    final profile = JumpingJackProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_arm_open': 156,
        'phase_feet_width_ratio': 1.02,
        'phase_feet_closed_ratio': 2.0,
      }, timestampMs: 1000),
      _frame({
        'phase_arm_open': 150,
        'phase_feet_width_ratio': 1.36,
        'phase_feet_closed_ratio': 2.8,
      }, timestampMs: 1460),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(metrics['peak_sync_gap_ms'], 460);
    expect(issues, contains(TechniqueIssue.poorSynchronization));
  });

  test('JumpingJackProfile flags torso sway and left-right asymmetry', () {
    final profile = JumpingJackProfile();
    final metrics = profile.summarizeRep(<PoseFrame>[
      _frame({
        'phase_arm_open': 154,
        'phase_feet_width_ratio': 1.34,
        'phase_torso_side_tilt': 18,
        'phase_left_right_asymmetry': 0.42,
      }, timestampMs: 1000),
    ]);

    final issues = profile.detectFinalIssues(metrics);

    expect(issues, contains(TechniqueIssue.unstablePosition));
    expect(issues, contains(TechniqueIssue.leftRightAsymmetry));
  });
}

PoseFrame _frame(Map<String, double> metrics, {int timestampMs = 0}) {
  return PoseFrame(
    frameIndex: 0,
    timestampMs: timestampMs,
    landmarks: const {},
    derivedMetrics: metrics,
  );
}
