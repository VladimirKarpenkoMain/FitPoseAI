import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../analysis/pose_frame.dart';
import '../../analysis/pose_metrics.dart';
import '../../analysis/readiness_evaluator.dart';
import '../../analysis/readiness_requirements.dart';
import '../../analysis/workout_analyzer.dart';
import '../../analysis/workout_frame_processor.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exercise_type.dart';
import 'painters/pose_painter.dart';

class PoseDetectorView extends StatefulWidget {
  const PoseDetectorView({
    super.key,
    required this.exerciseType,
    required this.preparationSeconds,
    this.enforceReadinessChecks = false,
    this.onAnalysisFrame,
  });

  final ExerciseType exerciseType;
  final int preparationSeconds;
  final bool enforceReadinessChecks;
  final ValueChanged<WorkoutFrameResult>? onAnalysisFrame;

  @override
  State<PoseDetectorView> createState() => _PoseDetectorViewState();
}

@visibleForTesting
Size workoutCameraPreviewDisplaySize(
  Size previewSize,
  Orientation orientation,
) {
  if (orientation == Orientation.landscape) {
    return Size(previewSize.width, previewSize.height);
  }
  return Size(previewSize.height, previewSize.width);
}

class _PoseDetectorViewState extends State<PoseDetectorView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _cameraIndex = 0;

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    ),
  );

  late final WorkoutAnalyzer _workoutAnalyzer;
  late final ReadinessEvaluator _readinessEvaluator;
  late final WorkoutFrameProcessor _workoutFrameProcessor;
  final Stopwatch _stopwatch = Stopwatch();
  static const Duration _analysisInterval = Duration(milliseconds: 90);
  static const Duration _poseLossGracePeriod = Duration(milliseconds: 350);

  Pose? _currentPose;
  Set<PoseLandmarkType> _highlightedLandmarks = const <PoseLandmarkType>{};
  bool _isDetecting = false;
  bool _isInitialized = false;
  String? _errorMessage;
  int _lastAnalysisStartedMs = -100000;
  int? _lastPoseSeenAtMs;
  int _frameIndex = 0;
  int _lastDebugLogAtMs = -100000;
  String? _lastDebugLine;
  Orientation? _lastViewOrientation;
  bool _isRestartingForOrientation = false;
  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _workoutAnalyzer = WorkoutAnalyzer(widget.exerciseType);
    final readinessRequirements = readinessRequirementsFor(widget.exerciseType);
    _readinessEvaluator = ReadinessEvaluator(
      requiredView: _workoutAnalyzer.profile.requiredView,
      countdownSeconds: widget.preparationSeconds,
      requiredJoints: readinessRequirements.requiredJoints,
      visibilityJointGroups: readinessRequirements.visibilityJointGroups,
      enforceReadinessChecks: widget.enforceReadinessChecks,
    );
    _workoutFrameProcessor = WorkoutFrameProcessor(
      readinessEvaluator: _readinessEvaluator,
      analyzeFrame: _workoutAnalyzer.processFrame,
      missingPoseTolerance: _poseLossGracePeriod,
    );
    _allowWorkoutOrientations();
    _stopwatch.start();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopwatch.stop();
    _stopCamera();
    _poseDetector.close();
    _restorePortraitOrientation();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted || _cameraController == null) {
      return;
    }

    final view = View.maybeOf(context);
    if (view == null) {
      return;
    }

    final physicalSize = view.physicalSize;
    final nextOrientation = physicalSize.width > physicalSize.height
        ? Orientation.landscape
        : Orientation.portrait;
    if (nextOrientation == _lastViewOrientation) {
      return;
    }
    _lastViewOrientation = nextOrientation;
    unawaited(_restartCameraForOrientation());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = _l10n.noCamerasAvailable;
        });
        return;
      }

      _cameraIndex = _cameras!.length > 1 ? 1 : 0;
      await _startCamera();
    } catch (e) {
      setState(() {
        _errorMessage = _l10n.cameraInitializationError(e.toString());
      });
    }
  }

  Future<void> _startCamera() async {
    if (_cameras == null || _cameras!.isEmpty) {
      return;
    }

    final camera = _cameras![_cameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processImage);

      if (mounted) {
        _lastViewOrientation = MediaQuery.orientationOf(context);
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _l10n.cameraStartError(e.toString());
      });
    }
  }

  Future<void> _stopCamera() async {
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      await _cameraController!.dispose();
      _cameraController = null;
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return;
    }

    await _stopCamera();

    setState(() {
      _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
      _isInitialized = false;
      _currentPose = null;
      _highlightedLandmarks = const <PoseLandmarkType>{};
    });
    _workoutFrameProcessor.reset();
    _lastPoseSeenAtMs = null;
    _frameIndex = 0;

    await _startCamera();
  }

  Future<void> _restartCameraForOrientation() async {
    if (_isRestartingForOrientation || _cameras == null || _cameras!.isEmpty) {
      return;
    }
    _isRestartingForOrientation = true;

    try {
      await _stopCamera();
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitialized = false;
        _currentPose = null;
        _highlightedLandmarks = const <PoseLandmarkType>{};
      });
      _workoutFrameProcessor.reset();
      _lastPoseSeenAtMs = null;
      _frameIndex = 0;
      await _startCamera();
    } finally {
      _isRestartingForOrientation = false;
    }
  }

  void _processImage(CameraImage image) async {
    final elapsed = _stopwatch.elapsed;
    final elapsedMs = elapsed.inMilliseconds;

    if (_isDetecting ||
        elapsedMs - _lastAnalysisStartedMs < _analysisInterval.inMilliseconds) {
      return;
    }

    _lastAnalysisStartedMs = elapsedMs;
    _isDetecting = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);
      final pose = poses.isNotEmpty ? poses.first : null;

      if (!mounted) {
        return;
      }

      if (pose != null) {
        _lastPoseSeenAtMs = elapsedMs;
      }

      if (pose == null) {
        final lastPoseSeenAtMs = _lastPoseSeenAtMs;
        final withinGracePeriod = lastPoseSeenAtMs != null &&
            elapsedMs - lastPoseSeenAtMs <= _poseLossGracePeriod.inMilliseconds;
        if (withinGracePeriod) {
          return;
        }

        final result = _workoutFrameProcessor.process(
          rawFrame: null,
          elapsed: elapsed,
        );

        if (_currentPose != null || _highlightedLandmarks.isNotEmpty) {
          setState(() {
            _currentPose = null;
            _highlightedLandmarks = const <PoseLandmarkType>{};
          });
        }
        widget.onAnalysisFrame?.call(result);
        _logDebugInfo(result);
        return;
      }

      final frame = _buildPoseFrame(
        pose,
        frameIndex: _frameIndex++,
        timestampMs: elapsedMs,
      );
      final result = _workoutFrameProcessor.process(
        rawFrame: frame,
        elapsed: elapsed,
      );

      setState(() {
        _currentPose = pose;
        _highlightedLandmarks =
            _highlightedLandmarksFor(result.readiness.state);
      });

      widget.onAnalysisFrame?.call(result);
      _logDebugInfo(result);
    } catch (e) {
      debugPrint('Pose detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    if (_cameraController == null) {
      return null;
    }

    final camera = _cameras![_cameraIndex];
    final rotation = _getInputImageRotation(camera);
    if (rotation == null) {
      return null;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      return null;
    }

    final plane = image.planes.first;

    final inputImageMetadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: inputImageMetadata,
    );
  }

  InputImageRotation? _getInputImageRotation(CameraDescription camera) {
    switch (camera.sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  PoseFrame _buildPoseFrame(
    Pose pose, {
    required int frameIndex,
    required int timestampMs,
  }) {
    final landmarks = <Joint, FrameLandmark>{};
    for (final entry in _jointMap.entries) {
      final landmark = pose.landmarks[entry.value];
      if (landmark == null) {
        continue;
      }
      landmarks[entry.key] = FrameLandmark(
        x: landmark.x,
        y: landmark.y,
        confidence: landmark.likelihood,
      );
    }

    final metrics = _buildDerivedMetrics(landmarks);
    return PoseFrame(
      frameIndex: frameIndex,
      timestampMs: timestampMs,
      landmarks: landmarks,
      derivedMetrics: metrics,
    );
  }

  Map<String, double> _buildDerivedMetrics(
      Map<Joint, FrameLandmark> landmarks) {
    final metrics = <String, double>{
      'avg_landmark_confidence':
          PoseMetrics.averageVisibleConfidence(landmarks.values),
    };

    switch (widget.exerciseType) {
      case ExerciseType.squat:
        final side = _selectSide(landmarks);
        final shoulder = side == _Side.left
            ? landmarks[Joint.leftShoulder]
            : landmarks[Joint.rightShoulder];
        final hip = side == _Side.left
            ? landmarks[Joint.leftHip]
            : landmarks[Joint.rightHip];
        final knee = side == _Side.left
            ? landmarks[Joint.leftKnee]
            : landmarks[Joint.rightKnee];
        final ankle = side == _Side.left
            ? landmarks[Joint.leftAnkle]
            : landmarks[Joint.rightAnkle];
        if (shoulder != null && hip != null && knee != null && ankle != null) {
          final kneeAngle = PoseMetrics.safeAngle(hip, knee, ankle);
          final hipAngle = PoseMetrics.safeAngle(shoulder, hip, knee);
          final torsoReference = PoseMetrics.safeAngle(shoulder, hip, ankle);
          final torsoVerticalTilt = PoseMetrics.verticalTilt(shoulder, hip);
          metrics['phase_knee_angle'] = kneeAngle;
          metrics['phase_hip_angle'] = hipAngle;
          metrics['phase_torso_lean'] = (180 - torsoReference).abs();
          metrics['phase_torso_vertical_tilt'] = torsoVerticalTilt;
          metrics['start_pose_valid'] =
              kneeAngle > 155 && hipAngle > 150 ? 1 : 0;
          metrics['selected_side_right'] = side == _Side.right ? 1 : 0;
        }
        final leftHip = landmarks[Joint.leftHip];
        final leftKnee = landmarks[Joint.leftKnee];
        final leftAnkle = landmarks[Joint.leftAnkle];
        final rightHip = landmarks[Joint.rightHip];
        final rightKnee = landmarks[Joint.rightKnee];
        final rightAnkle = landmarks[Joint.rightAnkle];
        if (leftHip != null &&
            leftKnee != null &&
            leftAnkle != null &&
            rightHip != null &&
            rightKnee != null &&
            rightAnkle != null) {
          final leftKneeAngle =
              PoseMetrics.safeAngle(leftHip, leftKnee, leftAnkle);
          final rightKneeAngle =
              PoseMetrics.safeAngle(rightHip, rightKnee, rightAnkle);
          metrics['phase_knee_symmetry'] =
              (leftKneeAngle - rightKneeAngle).abs();
        }
        break;
      case ExerciseType.pushup:
        final side = _selectSide(landmarks);
        final shoulder = side == _Side.left
            ? landmarks[Joint.leftShoulder]
            : landmarks[Joint.rightShoulder];
        final elbow = side == _Side.left
            ? landmarks[Joint.leftElbow]
            : landmarks[Joint.rightElbow];
        final wrist = side == _Side.left
            ? landmarks[Joint.leftWrist]
            : landmarks[Joint.rightWrist];
        final hip = side == _Side.left
            ? landmarks[Joint.leftHip]
            : landmarks[Joint.rightHip];
        final ankle = side == _Side.left
            ? landmarks[Joint.leftAnkle]
            : landmarks[Joint.rightAnkle];
        final head = side == _Side.left
            ? landmarks[Joint.leftEar] ?? landmarks[Joint.nose]
            : landmarks[Joint.rightEar] ?? landmarks[Joint.nose];
        if (shoulder != null && elbow != null && wrist != null) {
          final elbowAngle = PoseMetrics.safeAngle(shoulder, elbow, wrist);
          metrics['phase_elbow_angle'] = elbowAngle;
          metrics['selected_side_right'] = side == _Side.right ? 1 : 0;
          if (hip != null && ankle != null) {
            final bodyLine = PoseMetrics.safeAngle(shoulder, hip, ankle);
            final hipOffset = PoseMetrics.normalizedOffsetFromLine(
              lineStart: shoulder,
              point: hip,
              lineEnd: ankle,
            );
            metrics['phase_body_line_angle'] = bodyLine;
            metrics['phase_hip_offset'] = hipOffset;
            metrics['phase_body_line_deviation'] = (180 - bodyLine).abs();
            metrics['phase_shoulder_y'] = shoulder.y;
            metrics['phase_hip_y'] = hip.y;
            if (head != null) {
              final bodyLength = PoseMetrics.distance(shoulder, ankle);
              if (bodyLength > 0) {
                metrics['phase_head_shoulder_drop'] =
                    (head.y - shoulder.y) / bodyLength;
              }
            }
            metrics['start_pose_valid'] =
                elbowAngle >= 160 && bodyLine >= 165 && hipOffset.abs() < 0.14
                    ? 1
                    : 0;
          }
        }
        final leftShoulder = landmarks[Joint.leftShoulder];
        final leftElbow = landmarks[Joint.leftElbow];
        final leftWrist = landmarks[Joint.leftWrist];
        final rightShoulder = landmarks[Joint.rightShoulder];
        final rightElbow = landmarks[Joint.rightElbow];
        final rightWrist = landmarks[Joint.rightWrist];
        if (leftShoulder != null &&
            leftElbow != null &&
            leftWrist != null &&
            rightShoulder != null &&
            rightElbow != null &&
            rightWrist != null) {
          final leftAngle =
              PoseMetrics.safeAngle(leftShoulder, leftElbow, leftWrist);
          final rightAngle =
              PoseMetrics.safeAngle(rightShoulder, rightElbow, rightWrist);
          metrics['phase_elbow_symmetry'] = (leftAngle - rightAngle).abs();
        }
        break;
      case ExerciseType.plank:
        final side = _selectSide(landmarks);
        final shoulder = side == _Side.left
            ? landmarks[Joint.leftShoulder]
            : landmarks[Joint.rightShoulder];
        final elbow = side == _Side.left
            ? landmarks[Joint.leftElbow]
            : landmarks[Joint.rightElbow];
        final wrist = side == _Side.left
            ? landmarks[Joint.leftWrist]
            : landmarks[Joint.rightWrist];
        final hip = side == _Side.left
            ? landmarks[Joint.leftHip]
            : landmarks[Joint.rightHip];
        final knee = side == _Side.left
            ? landmarks[Joint.leftKnee]
            : landmarks[Joint.rightKnee];
        final ankle = side == _Side.left
            ? landmarks[Joint.leftAnkle]
            : landmarks[Joint.rightAnkle];
        final head = side == _Side.left
            ? landmarks[Joint.leftEar] ?? landmarks[Joint.nose]
            : landmarks[Joint.rightEar] ?? landmarks[Joint.nose];
        if (shoulder != null &&
            elbow != null &&
            wrist != null &&
            hip != null &&
            knee != null &&
            ankle != null) {
          final bodyLine = PoseMetrics.safeAngle(shoulder, hip, ankle);
          final elbowAngle = PoseMetrics.safeAngle(shoulder, elbow, wrist);
          final kneeAngle = PoseMetrics.safeAngle(hip, knee, ankle);
          final hipOffset = PoseMetrics.normalizedOffsetFromLine(
            lineStart: shoulder,
            point: hip,
            lineEnd: ankle,
          );
          final bodyLength = PoseMetrics.distance(shoulder, ankle);
          if (bodyLength == 0) {
            break;
          }
          final shoulderElbowOffset =
              PoseMetrics.horizontalDistance(shoulder, elbow) / bodyLength;
          final neckDeviation = head == null
              ? 0.0
              : (180 - PoseMetrics.safeAngle(head, shoulder, hip)).abs();
          metrics['hold_body_line_angle'] = bodyLine;
          metrics['hold_elbow_angle'] = elbowAngle;
          metrics['hold_knee_angle'] = kneeAngle;
          metrics['hold_neck_deviation'] = neckDeviation;
          metrics['hold_hip_offset'] = hipOffset;
          metrics['hold_shoulder_elbow_offset'] = shoulderElbowOffset;
          metrics['start_pose_valid'] = bodyLine >= 165 &&
                  elbowAngle >= 70 &&
                  elbowAngle <= 110 &&
                  kneeAngle >= 165 &&
                  neckDeviation <= 15 &&
                  hipOffset.abs() < 0.14 &&
                  shoulderElbowOffset < 0.18
              ? 1
              : 0;
          metrics['selected_side_right'] = side == _Side.right ? 1 : 0;
        }
        break;
      case ExerciseType.shoulderPress:
        final side = _selectSide(landmarks);
        final shoulder = side == _Side.left
            ? landmarks[Joint.leftShoulder]
            : landmarks[Joint.rightShoulder];
        final wrist = side == _Side.left
            ? landmarks[Joint.leftWrist]
            : landmarks[Joint.rightWrist];
        final hip = side == _Side.left
            ? landmarks[Joint.leftHip]
            : landmarks[Joint.rightHip];
        final knee = side == _Side.left
            ? landmarks[Joint.leftKnee]
            : landmarks[Joint.rightKnee];
        final ankle = side == _Side.left
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
        if (shoulderAngles.isNotEmpty) {
          metrics['phase_shoulder_angle'] =
              shoulderAngles.reduce((left, right) => left + right) /
                  shoulderAngles.length;
        }
        if (elbowAngles.isNotEmpty) {
          metrics['phase_elbow_angle'] =
              elbowAngles.reduce((left, right) => left + right) /
                  elbowAngles.length;
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
            final footStackOffset =
                PoseMetrics.horizontalDistance(wrist, ankle);
            metrics['phase_vertical_stack_offset'] =
                (shoulderStackOffset + footStackOffset) / (2 * bodyReference);
          }
        }
        if (leftShoulder != null &&
            leftWrist != null &&
            rightShoulder != null &&
            rightWrist != null) {
          metrics['phase_wrist_above_shoulder'] =
              leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y
                  ? 1
                  : 0;
          final bodyReference = leftHip != null && leftAnkle != null
              ? PoseMetrics.distance(leftShoulder, leftAnkle)
              : PoseMetrics.horizontalDistance(leftShoulder, rightShoulder);
          if (bodyReference > 0) {
            metrics['phase_wrist_height_asymmetry'] =
                PoseMetrics.verticalDistance(leftWrist, rightWrist) /
                    bodyReference;
          }
        } else if (shoulder != null && wrist != null) {
          metrics['phase_wrist_above_shoulder'] = wrist.y < shoulder.y ? 1 : 0;
        }
        if (leftShoulder != null &&
            rightShoulder != null &&
            leftElbow != null &&
            rightElbow != null) {
          final shoulderWidth =
              PoseMetrics.horizontalDistance(leftShoulder, rightShoulder);
          if (shoulderWidth > 0) {
            metrics['phase_elbow_width_ratio'] =
                PoseMetrics.horizontalDistance(leftElbow, rightElbow) /
                    shoulderWidth;
          }
        }
        final shoulderAngle = metrics['phase_shoulder_angle'] ?? 0;
        final elbowAngle = metrics['phase_elbow_angle'] ?? 180;
        final torsoAngle = metrics['phase_torso_angle_from_vertical'] ?? 0;
        final handForwardOffset = metrics['phase_hand_forward_offset'] ?? 0;
        metrics['start_pose_valid'] = shoulderAngle >= 20 &&
                shoulderAngle <= 105 &&
                elbowAngle >= 60 &&
                elbowAngle <= 120 &&
                torsoAngle <= 18 &&
                handForwardOffset <= 0.35
            ? 1
            : 0;
        metrics['selected_side_right'] = side == _Side.right ? 1 : 0;
        break;
      case ExerciseType.jumpingJack:
        final leftHip = landmarks[Joint.leftHip];
        final leftShoulder = landmarks[Joint.leftShoulder];
        final leftWrist = landmarks[Joint.leftWrist];
        final leftAnkle = landmarks[Joint.leftAnkle];
        final rightHip = landmarks[Joint.rightHip];
        final rightShoulder = landmarks[Joint.rightShoulder];
        final rightWrist = landmarks[Joint.rightWrist];
        final rightAnkle = landmarks[Joint.rightAnkle];
        final leftKnee = landmarks[Joint.leftKnee];
        final rightKnee = landmarks[Joint.rightKnee];

        final armAngles = <double>[];
        if (leftHip != null && leftShoulder != null && leftWrist != null) {
          armAngles
              .add(PoseMetrics.safeAngle(leftHip, leftShoulder, leftWrist));
        }
        if (rightHip != null && rightShoulder != null && rightWrist != null) {
          armAngles
              .add(PoseMetrics.safeAngle(rightHip, rightShoulder, rightWrist));
        }
        if (armAngles.isNotEmpty) {
          metrics['phase_arm_open'] =
              armAngles.reduce((left, right) => left + right) /
                  armAngles.length;
        }

        if (leftHip != null &&
            rightHip != null &&
            leftKnee != null &&
            rightKnee != null) {
          final midHip = PoseMetrics.midpoint(leftHip, rightHip);
          metrics['phase_leg_open'] =
              PoseMetrics.safeAngle(leftKnee, midHip, rightKnee);
        }

        if (leftShoulder != null &&
            rightShoulder != null &&
            leftHip != null &&
            rightHip != null) {
          final shoulderWidth =
              PoseMetrics.horizontalDistance(leftShoulder, rightShoulder);
          final hipWidth = PoseMetrics.horizontalDistance(leftHip, rightHip);
          final midShoulder = PoseMetrics.midpoint(leftShoulder, rightShoulder);
          final midHip = PoseMetrics.midpoint(leftHip, rightHip);
          final torsoHeight = PoseMetrics.verticalDistance(midShoulder, midHip);

          metrics['phase_torso_side_tilt'] =
              PoseMetrics.verticalTilt(midShoulder, midHip);

          if (leftAnkle != null && rightAnkle != null) {
            final ankleDistance =
                PoseMetrics.horizontalDistance(leftAnkle, rightAnkle);
            if (shoulderWidth > 0) {
              metrics['phase_feet_width_ratio'] = ankleDistance / shoulderWidth;

              final bodyCenterX = midHip.x;
              final leftSpread = (leftAnkle.x - bodyCenterX).abs();
              final rightSpread = (rightAnkle.x - bodyCenterX).abs();
              metrics['phase_ankle_spread_asymmetry'] =
                  (leftSpread - rightSpread).abs() / shoulderWidth;
            }
            if (hipWidth > 0) {
              metrics['phase_feet_closed_ratio'] = ankleDistance / hipWidth;
            }
          }

          if (leftWrist != null && rightWrist != null && torsoHeight > 0) {
            metrics['phase_wrist_height_asymmetry'] =
                PoseMetrics.verticalDistance(leftWrist, rightWrist) /
                    torsoHeight;
          }

          final wristAsymmetry = metrics['phase_wrist_height_asymmetry'] ?? 0;
          final ankleAsymmetry = metrics['phase_ankle_spread_asymmetry'] ?? 0;
          metrics['phase_left_right_asymmetry'] =
              math.max(wristAsymmetry, ankleAsymmetry);
        }

        final armOpen = metrics['phase_arm_open'] ?? 0;
        final legOpen = metrics['phase_leg_open'] ?? 0;
        final feetWidthRatio = metrics['phase_feet_width_ratio'];
        final feetClosedRatio = metrics['phase_feet_closed_ratio'];
        final torsoTilt = metrics['phase_torso_side_tilt'] ?? 0;
        final feetProgress = feetWidthRatio != null
            ? ((feetWidthRatio - 0.3) / (1.3 - 0.3)).clamp(0.0, 1.0)
            : (legOpen / 60).clamp(0.0, 1.0);
        final armProgress = (armOpen / 180).clamp(0.0, 1.0);
        metrics['phase_sync_gap'] = (armProgress - feetProgress).abs();
        metrics['start_pose_valid'] = armOpen <= 30 &&
                (feetClosedRatio != null
                    ? feetClosedRatio <= 1.2
                    : legOpen < 18) &&
                torsoTilt <= 15
            ? 1
            : 0;
        break;
    }

    return metrics;
  }

  _Side _selectSide(Map<Joint, FrameLandmark> landmarks) {
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

    return rightScore > leftScore ? _Side.right : _Side.left;
  }

  Set<PoseLandmarkType> _highlightedLandmarksFor(ReadinessState state) {
    switch (state) {
      case ReadinessState.viewAlignment:
        return const {
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
        };
      case ReadinessState.bodyVisibilityCheck:
        return _requiredPoseLandmarksFor(widget.exerciseType);
      case ReadinessState.startPoseCheck:
        return _requiredPoseLandmarksFor(widget.exerciseType);
      case ReadinessState.countdownReady:
      case ReadinessState.activeTracking:
        return const <PoseLandmarkType>{};
    }
  }

  Set<PoseLandmarkType> _requiredPoseLandmarksFor(ExerciseType exerciseType) {
    return readinessRequirementsFor(exerciseType)
        .requiredJoints
        .map((joint) => _jointMap[joint])
        .whereType<PoseLandmarkType>()
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _cameraController == null) {
      return _buildLoadingWidget();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCameraPreview(),
        if (_currentPose != null) _buildPoseOverlay(),
        _buildCameraSwitchButton(),
      ],
    );
  }

  Future<void> _allowWorkoutOrientations() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restorePortraitOrientation() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Widget _buildLoadingWidget() {
    final l10n = AppLocalizations.of(context);

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              l10n.initializingCamera,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final l10n = AppLocalizations.of(context);

    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController!;
    final previewSize = controller.value.previewSize!;
    final displaySize = workoutCameraPreviewDisplaySize(
      previewSize,
      MediaQuery.orientationOf(context),
    );

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: displaySize.width,
          height: displaySize.height,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildPoseOverlay() {
    final controller = _cameraController!;
    final camera = _cameras![_cameraIndex];
    final previewSize = controller.value.previewSize!;
    final rotation =
        _getInputImageRotation(camera) ?? InputImageRotation.rotation0deg;

    final size = MediaQuery.of(context).size;
    final displaySize = workoutCameraPreviewDisplaySize(
      previewSize,
      MediaQuery.orientationOf(context),
    );
    final scaleFactor = math.max(
      size.width / displaySize.width,
      size.height / displaySize.height,
    );

    return CustomPaint(
      painter: PosePainter(
        pose: _currentPose!,
        imageSize: Size(previewSize.width, previewSize.height),
        rotation: rotation,
        cameraLensDirection: camera.lensDirection,
        scaleFactor: scaleFactor,
        displayImageSize: displaySize,
        highlightedLandmarks: _highlightedLandmarks,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildCameraSwitchButton() {
    if (_cameras == null || _cameras!.length < 2) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(30),
          ),
          child: IconButton(
            onPressed: _switchCamera,
            icon: const Icon(
              Icons.cameraswitch,
              color: Colors.white,
              size: 28,
            ),
            tooltip: AppLocalizations.of(context).switchCamera,
          ),
        ),
      ),
    );
  }

  void _logDebugInfo(WorkoutFrameResult result) {
    if (!kDebugMode) {
      return;
    }

    final debugInfo = result.debugInfo;
    if (debugInfo == null) {
      return;
    }

    final line = debugInfo.toLogLine();
    final timestampMs =
        debugInfo.timestampMs ?? _stopwatch.elapsed.inMilliseconds;
    final shouldLog = result.repUpdate?.countIncremented == true ||
        _lastDebugLine != line ||
        timestampMs - _lastDebugLogAtMs >= 500;

    if (!shouldLog) {
      return;
    }

    _lastDebugLine = line;
    _lastDebugLogAtMs = timestampMs;
    debugPrint('[workout-debug] $line');
  }
}

const Map<Joint, PoseLandmarkType> _jointMap = {
  Joint.nose: PoseLandmarkType.nose,
  Joint.leftEar: PoseLandmarkType.leftEar,
  Joint.rightEar: PoseLandmarkType.rightEar,
  Joint.leftShoulder: PoseLandmarkType.leftShoulder,
  Joint.rightShoulder: PoseLandmarkType.rightShoulder,
  Joint.leftElbow: PoseLandmarkType.leftElbow,
  Joint.rightElbow: PoseLandmarkType.rightElbow,
  Joint.leftWrist: PoseLandmarkType.leftWrist,
  Joint.rightWrist: PoseLandmarkType.rightWrist,
  Joint.leftHip: PoseLandmarkType.leftHip,
  Joint.rightHip: PoseLandmarkType.rightHip,
  Joint.leftKnee: PoseLandmarkType.leftKnee,
  Joint.rightKnee: PoseLandmarkType.rightKnee,
  Joint.leftAnkle: PoseLandmarkType.leftAnkle,
  Joint.rightAnkle: PoseLandmarkType.rightAnkle,
};

enum _Side { left, right }
