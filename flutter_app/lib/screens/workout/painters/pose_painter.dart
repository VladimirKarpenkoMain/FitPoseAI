import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  static const Set<PoseLandmarkType> _coreLandmarks = {
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  };

  static const List<(PoseLandmarkType, PoseLandmarkType)> _coreConnections = [
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  ];

  PosePainter({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
    this.scaleFactor,
    this.displayImageSize,
    this.highlightedLandmarks = const <PoseLandmarkType>{},
  });

  final Pose pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final double? scaleFactor;
  final Size? displayImageSize;
  final Set<PoseLandmarkType> highlightedLandmarks;

  final Paint _landmarkPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.amber;

  final Paint _warningLandmarkPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.redAccent;

  final Paint _linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..color = Colors.greenAccent;

  final Paint _leftPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..color = Colors.cyanAccent;

  final Paint _rightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..color = Colors.pinkAccent;

  final Paint _warningPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..color = Colors.redAccent;

  @override
  void paint(Canvas canvas, Size size) {
    _drawConnections(canvas, size);
    _drawLandmarks(canvas, size);
  }

  void _drawLandmarks(Canvas canvas, Size size) {
    for (final entry in pose.landmarks.entries) {
      if (!_coreLandmarks.contains(entry.key)) {
        continue;
      }
      final landmark = entry.value;
      if (landmark.likelihood <= 0.5) {
        continue;
      }
      final point = _transformPoint(landmark.x, landmark.y, size);
      final isHighlighted = highlightedLandmarks.contains(entry.key);
      canvas.drawCircle(point, isHighlighted ? 10 : 8,
          isHighlighted ? _warningLandmarkPaint : _landmarkPaint);
    }
  }

  void _drawConnections(Canvas canvas, Size size) {
    for (final connection in _coreConnections) {
      final startLandmark = pose.landmarks[connection.$1];
      final endLandmark = pose.landmarks[connection.$2];

      if (startLandmark == null || endLandmark == null) {
        continue;
      }
      if (startLandmark.likelihood <= 0.5 || endLandmark.likelihood <= 0.5) {
        continue;
      }

      final startPoint =
          _transformPoint(startLandmark.x, startLandmark.y, size);
      final endPoint = _transformPoint(endLandmark.x, endLandmark.y, size);
      final shouldWarn = highlightedLandmarks.contains(connection.$1) ||
          highlightedLandmarks.contains(connection.$2);
      final paint = shouldWarn
          ? _warningPaint
          : _getPaintForConnection(connection.$1, connection.$2);
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  Paint _getPaintForConnection(PoseLandmarkType start, PoseLandmarkType end) {
    final startName = start.name.toLowerCase();
    final endName = end.name.toLowerCase();
    if (startName.contains('left') || endName.contains('left')) {
      return _leftPaint;
    }
    if (startName.contains('right') || endName.contains('right')) {
      return _rightPaint;
    }
    return _linePaint;
  }

  Offset _transformPoint(double x, double y, Size canvasSize) {
    final isRotated = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final displayImageSize = this.displayImageSize;
    final sourceWidth = displayImageSize?.width ??
        (isRotated ? imageSize.height : imageSize.width);
    final sourceHeight = displayImageSize?.height ??
        (isRotated ? imageSize.width : imageSize.height);

    final scaleX = canvasSize.width / sourceWidth;
    final scaleY = canvasSize.height / sourceHeight;
    final scale = scaleFactor ?? (scaleX > scaleY ? scaleX : scaleY);

    final offsetX = (sourceWidth * scale - canvasSize.width) / 2;
    final offsetY = (sourceHeight * scale - canvasSize.height) / 2;

    var targetX = x * scale - offsetX;
    final targetY = y * scale - offsetY;

    if (cameraLensDirection == CameraLensDirection.front) {
      targetX = canvasSize.width - targetX;
    }

    return Offset(targetX, targetY);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.rotation != rotation ||
        oldDelegate.displayImageSize != displayImageSize ||
        oldDelegate.highlightedLandmarks != highlightedLandmarks;
  }
}
