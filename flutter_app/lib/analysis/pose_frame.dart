enum Joint {
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

class FrameLandmark {
  final double x;
  final double y;
  final double confidence;

  const FrameLandmark({
    required this.x,
    required this.y,
    required this.confidence,
  });
}

class PoseFrame {
  final int frameIndex;
  final int timestampMs;
  final Map<Joint, FrameLandmark> landmarks;
  final Map<String, double> derivedMetrics;

  const PoseFrame({
    this.frameIndex = 0,
    this.timestampMs = 0,
    required this.landmarks,
    this.derivedMetrics = const {},
  });

  FrameLandmark? operator [](Joint joint) => landmarks[joint];

  bool hasVisible(Joint joint, {double minConfidence = 0.5}) {
    final landmark = landmarks[joint];
    return landmark != null && landmark.confidence >= minConfidence;
  }

  PoseFrame copyWith({
    int? frameIndex,
    int? timestampMs,
    Map<Joint, FrameLandmark>? landmarks,
    Map<String, double>? derivedMetrics,
  }) {
    return PoseFrame(
      frameIndex: frameIndex ?? this.frameIndex,
      timestampMs: timestampMs ?? this.timestampMs,
      landmarks: landmarks ?? this.landmarks,
      derivedMetrics: derivedMetrics ?? this.derivedMetrics,
    );
  }
}
