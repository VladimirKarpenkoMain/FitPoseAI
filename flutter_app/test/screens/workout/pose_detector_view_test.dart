import 'package:fitness_ai/screens/workout/pose_detector_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workoutCameraPreviewDisplaySize matches device orientation', () {
    const previewSize = Size(640, 480);

    expect(
      workoutCameraPreviewDisplaySize(previewSize, Orientation.portrait),
      const Size(480, 640),
    );
    expect(
      workoutCameraPreviewDisplaySize(previewSize, Orientation.landscape),
      const Size(640, 480),
    );
  });
}
