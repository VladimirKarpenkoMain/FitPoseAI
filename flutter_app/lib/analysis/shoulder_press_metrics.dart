import 'pose_frame.dart';
import 'pose_metrics.dart';

/// Which body side faces the camera for a side-view shoulder press.
enum PressSide { left, right }

/// Picks the camera-facing side using the same torso-width heuristic the other
/// side-view exercises rely on.
PressSide selectPressSide(Map<Joint, FrameLandmark> landmarks) {
  final leftShoulder = landmarks[Joint.leftShoulder];
  final leftHip = landmarks[Joint.leftHip];
  final rightShoulder = landmarks[Joint.rightShoulder];
  final rightHip = landmarks[Joint.rightHip];

  final leftScore = leftShoulder != null && leftHip != null
      ? PoseMetrics.horizontalDistance(leftShoulder, leftHip)
      : -1.0;
  final rightScore = rightShoulder != null && rightHip != null
      ? PoseMetrics.horizontalDistance(rightShoulder, rightHip)
      : -1.0;

  return rightScore > leftScore ? PressSide.right : PressSide.left;
}

/// Builds the derived metrics consumed by [ShoulderPressProfile] from a single
/// frame of pose landmarks.
Map<String, double> buildShoulderPressMetrics(
    Map<Joint, FrameLandmark> landmarks) {
  final metrics = <String, double>{};
  final side = selectPressSide(landmarks);
  final shoulder = side == PressSide.left
      ? landmarks[Joint.leftShoulder]
      : landmarks[Joint.rightShoulder];
  final elbow = side == PressSide.left
      ? landmarks[Joint.leftElbow]
      : landmarks[Joint.rightElbow];
  final wrist = side == PressSide.left
      ? landmarks[Joint.leftWrist]
      : landmarks[Joint.rightWrist];
  final hip = side == PressSide.left
      ? landmarks[Joint.leftHip]
      : landmarks[Joint.rightHip];
  final knee = side == PressSide.left
      ? landmarks[Joint.leftKnee]
      : landmarks[Joint.rightKnee];
  final ankle = side == PressSide.left
      ? landmarks[Joint.leftAnkle]
      : landmarks[Joint.rightAnkle];
  final leftHip = landmarks[Joint.leftHip];
  final leftShoulder = landmarks[Joint.leftShoulder];
  final leftElbow = landmarks[Joint.leftElbow];
  final leftWrist = landmarks[Joint.leftWrist];
  final leftAnkle = landmarks[Joint.leftAnkle];
  final rightHip = landmarks[Joint.rightHip];
  final rightShoulder = landmarks[Joint.rightShoulder];
  final rightElbow = landmarks[Joint.rightElbow];
  final rightWrist = landmarks[Joint.rightWrist];

  final shoulderAngles = <double>[];
  final elbowAngles = <double>[];
  if (leftHip != null &&
      leftShoulder != null &&
      leftElbow != null &&
      leftWrist != null) {
    final leftShoulderAngle =
        PoseMetrics.safeAngle(leftHip, leftShoulder, leftElbow);
    final leftElbowAngle =
        PoseMetrics.safeAngle(leftShoulder, leftElbow, leftWrist);
    shoulderAngles.add(leftShoulderAngle);
    elbowAngles.add(leftElbowAngle);
    metrics['phase_left_shoulder_angle'] = leftShoulderAngle;
    metrics['phase_left_elbow_angle'] = leftElbowAngle;
  }
  if (rightHip != null &&
      rightShoulder != null &&
      rightElbow != null &&
      rightWrist != null) {
    final rightShoulderAngle =
        PoseMetrics.safeAngle(rightHip, rightShoulder, rightElbow);
    final rightElbowAngle =
        PoseMetrics.safeAngle(rightShoulder, rightElbow, rightWrist);
    shoulderAngles.add(rightShoulderAngle);
    elbowAngles.add(rightElbowAngle);
    metrics['phase_right_shoulder_angle'] = rightShoulderAngle;
    metrics['phase_right_elbow_angle'] = rightElbowAngle;
  }
  // Primary phase metrics come from the camera-facing side only. The required
  // side view occludes the far arm, so averaging both arms (or gating on both)
  // dragged the lockout below threshold and reps never counted.
  if (hip != null && shoulder != null && elbow != null) {
    metrics['phase_shoulder_angle'] =
        PoseMetrics.safeAngle(hip, shoulder, elbow);
  }
  if (shoulder != null && elbow != null && wrist != null) {
    metrics['phase_elbow_angle'] =
        PoseMetrics.safeAngle(shoulder, elbow, wrist);
  }
  if (shoulderAngles.length == 2 && elbowAngles.length == 2) {
    final shoulderGap = (shoulderAngles[0] - shoulderAngles[1]).abs();
    final elbowGap = (elbowAngles[0] - elbowAngles[1]).abs();
    metrics['phase_left_right_symmetry'] =
        shoulderGap > elbowGap ? shoulderGap : elbowGap;
    metrics['phase_bilateral_arm_metrics'] = 1;
  }
  if (shoulder != null && hip != null) {
    metrics['phase_torso_angle_from_vertical'] =
        PoseMetrics.verticalTilt(shoulder, hip);
  }
  if (hip != null && knee != null && ankle != null) {
    metrics['phase_knee_angle'] = PoseMetrics.safeAngle(hip, knee, ankle);
  }
  if (shoulder != null && wrist != null) {
    final bodyReference = hip != null && ankle != null
        ? PoseMetrics.distance(shoulder, ankle)
        : PoseMetrics.distance(shoulder, wrist);
    if (bodyReference > 0) {
      metrics['phase_hand_forward_offset'] =
          PoseMetrics.horizontalDistance(wrist, shoulder) / bodyReference;
    }
  }
  if (shoulder != null && hip != null && wrist != null && ankle != null) {
    final bodyReference = PoseMetrics.distance(shoulder, ankle);
    if (bodyReference > 0) {
      final shoulderStackOffset =
          PoseMetrics.horizontalDistance(wrist, shoulder);
      final footStackOffset = PoseMetrics.horizontalDistance(wrist, ankle);
      metrics['phase_vertical_stack_offset'] =
          (shoulderStackOffset + footStackOffset) / (2 * bodyReference);
    }
  }
  if (shoulder != null && wrist != null) {
    metrics['phase_wrist_above_shoulder'] = wrist.y < shoulder.y ? 1 : 0;
  }
  if (leftShoulder != null &&
      leftWrist != null &&
      rightShoulder != null &&
      rightWrist != null) {
    final bodyReference = leftHip != null && leftAnkle != null
        ? PoseMetrics.distance(leftShoulder, leftAnkle)
        : PoseMetrics.horizontalDistance(leftShoulder, rightShoulder);
    if (bodyReference > 0) {
      metrics['phase_wrist_height_asymmetry'] =
          PoseMetrics.verticalDistance(leftWrist, rightWrist) / bodyReference;
    }
  }
  if (leftShoulder != null &&
      rightShoulder != null &&
      leftElbow != null &&
      rightElbow != null) {
    final shoulderWidth =
        PoseMetrics.horizontalDistance(leftShoulder, rightShoulder);
    if (shoulderWidth > 0) {
      metrics['phase_elbow_width_ratio'] =
          PoseMetrics.horizontalDistance(leftElbow, rightElbow) / shoulderWidth;
    }
  }
  final resolvedShoulderAngle = metrics['phase_shoulder_angle'] ?? 0;
  final resolvedElbowAngle = metrics['phase_elbow_angle'] ?? 180;
  final torsoAngle = metrics['phase_torso_angle_from_vertical'] ?? 0;
  final handForwardOffset = metrics['phase_hand_forward_offset'] ?? 0;
  metrics['start_pose_valid'] = resolvedShoulderAngle >= 20 &&
          resolvedShoulderAngle <= 105 &&
          resolvedElbowAngle >= 60 &&
          resolvedElbowAngle <= 120 &&
          torsoAngle <= 18 &&
          handForwardOffset <= 0.35
      ? 1
      : 0;
  metrics['selected_side_right'] = side == PressSide.right ? 1 : 0;
  return metrics;
}
