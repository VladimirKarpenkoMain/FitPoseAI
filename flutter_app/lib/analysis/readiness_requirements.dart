import '../models/exercise_type.dart';
import 'pose_frame.dart';

class ReadinessRequirements {
  const ReadinessRequirements({
    required this.requiredJoints,
    this.visibilityJointGroups = const <Set<Joint>>[],
  });

  final Set<Joint> requiredJoints;
  final List<Set<Joint>> visibilityJointGroups;
}

ReadinessRequirements readinessRequirementsFor(ExerciseType exerciseType) {
  switch (exerciseType) {
    case ExerciseType.squat:
      return const ReadinessRequirements(
        requiredJoints: {
          Joint.leftShoulder,
          Joint.leftHip,
          Joint.leftKnee,
          Joint.leftAnkle,
        },
        visibilityJointGroups: [
          {
            Joint.leftShoulder,
            Joint.leftHip,
            Joint.leftKnee,
            Joint.leftAnkle,
          },
          {
            Joint.rightShoulder,
            Joint.rightHip,
            Joint.rightKnee,
            Joint.rightAnkle,
          },
        ],
      );
    case ExerciseType.pushup:
      return const ReadinessRequirements(
        requiredJoints: {
          Joint.leftShoulder,
          Joint.leftElbow,
          Joint.leftWrist,
          Joint.leftHip,
          Joint.leftAnkle,
        },
        visibilityJointGroups: [
          {
            Joint.leftShoulder,
            Joint.leftElbow,
            Joint.leftWrist,
            Joint.leftHip,
            Joint.leftAnkle,
          },
          {
            Joint.rightShoulder,
            Joint.rightElbow,
            Joint.rightWrist,
            Joint.rightHip,
            Joint.rightAnkle,
          },
        ],
      );
    case ExerciseType.plank:
      return const ReadinessRequirements(
        requiredJoints: {
          Joint.nose,
          Joint.leftShoulder,
          Joint.leftElbow,
          Joint.leftWrist,
          Joint.leftHip,
          Joint.leftKnee,
          Joint.leftAnkle,
        },
        visibilityJointGroups: [
          {
            Joint.nose,
            Joint.leftShoulder,
            Joint.leftElbow,
            Joint.leftWrist,
            Joint.leftHip,
            Joint.leftKnee,
            Joint.leftAnkle,
          },
          {
            Joint.nose,
            Joint.rightShoulder,
            Joint.rightElbow,
            Joint.rightWrist,
            Joint.rightHip,
            Joint.rightKnee,
            Joint.rightAnkle,
          },
        ],
      );
    case ExerciseType.shoulderPress:
      return const ReadinessRequirements(
        requiredJoints: {
          Joint.leftShoulder,
          Joint.leftElbow,
          Joint.leftWrist,
          Joint.leftHip,
        },
        visibilityJointGroups: [
          {
            Joint.leftShoulder,
            Joint.leftElbow,
            Joint.leftWrist,
            Joint.leftHip,
          },
          {
            Joint.rightShoulder,
            Joint.rightElbow,
            Joint.rightWrist,
            Joint.rightHip,
          },
        ],
      );
    case ExerciseType.jumpingJack:
      return const ReadinessRequirements(
        requiredJoints: {
          Joint.leftShoulder,
          Joint.rightShoulder,
          Joint.leftWrist,
          Joint.rightWrist,
          Joint.leftHip,
          Joint.rightHip,
          Joint.leftKnee,
          Joint.rightKnee,
          Joint.leftAnkle,
          Joint.rightAnkle,
        },
      );
  }
}
