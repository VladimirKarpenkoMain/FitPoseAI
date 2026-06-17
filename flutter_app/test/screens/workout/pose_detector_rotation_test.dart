import 'package:camera/camera.dart';
import 'package:fitness_ai/screens/workout/pose_detector_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  group('workoutInputImageRotation (Android, back camera, sensor 90)', () {
    InputImageRotation? rotationFor(DeviceOrientation orientation) {
      return workoutInputImageRotation(
        sensorOrientation: 90,
        deviceOrientation: orientation,
        lensDirection: CameraLensDirection.back,
        platform: TargetPlatform.android,
      );
    }

    test('portraitUp keeps sensor rotation', () {
      expect(rotationFor(DeviceOrientation.portraitUp),
          InputImageRotation.rotation90deg);
    });

    test('landscapeLeft compensates to 0deg', () {
      expect(rotationFor(DeviceOrientation.landscapeLeft),
          InputImageRotation.rotation0deg);
    });

    test('landscapeRight compensates to 180deg', () {
      expect(rotationFor(DeviceOrientation.landscapeRight),
          InputImageRotation.rotation180deg);
    });

    test('portraitDown compensates to 270deg', () {
      expect(rotationFor(DeviceOrientation.portraitDown),
          InputImageRotation.rotation270deg);
    });
  });

  group('workoutInputImageRotation (Android, front camera, sensor 270)', () {
    InputImageRotation? rotationFor(DeviceOrientation orientation) {
      return workoutInputImageRotation(
        sensorOrientation: 270,
        deviceOrientation: orientation,
        lensDirection: CameraLensDirection.front,
        platform: TargetPlatform.android,
      );
    }

    test('portraitUp keeps sensor rotation', () {
      expect(rotationFor(DeviceOrientation.portraitUp),
          InputImageRotation.rotation270deg);
    });

    test('landscapeLeft compensates to 0deg', () {
      expect(rotationFor(DeviceOrientation.landscapeLeft),
          InputImageRotation.rotation0deg);
    });
  });

  group('workoutInputImageRotation (iOS)', () {
    test('uses sensor orientation regardless of device orientation', () {
      expect(
        workoutInputImageRotation(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          lensDirection: CameraLensDirection.back,
          platform: TargetPlatform.iOS,
        ),
        InputImageRotation.rotation90deg,
      );
    });
  });
}
