import 'dart:math' as math;

import 'pose_frame.dart';

class PoseMetrics {
  static double horizontalDistance(FrameLandmark a, FrameLandmark b) {
    return (a.x - b.x).abs();
  }

  static double verticalDistance(FrameLandmark a, FrameLandmark b) {
    return (a.y - b.y).abs();
  }

  static double distance(FrameLandmark a, FrameLandmark b) {
    final deltaX = a.x - b.x;
    final deltaY = a.y - b.y;
    return math.sqrt(deltaX * deltaX + deltaY * deltaY);
  }

  static FrameLandmark midpoint(FrameLandmark a, FrameLandmark b) {
    return FrameLandmark(
      x: (a.x + b.x) / 2,
      y: (a.y + b.y) / 2,
      confidence: (a.confidence + b.confidence) / 2,
    );
  }

  static double angle(FrameLandmark a, FrameLandmark b, FrameLandmark c) {
    return safeAngle(a, b, c);
  }

  static double safeAngle(
    FrameLandmark? a,
    FrameLandmark? b,
    FrameLandmark? c, {
    double fallback = 180,
  }) {
    if (a == null || b == null || c == null) {
      return fallback;
    }

    final abX = a.x - b.x;
    final abY = a.y - b.y;
    final cbX = c.x - b.x;
    final cbY = c.y - b.y;
    final magnitude =
        math.sqrt(abX * abX + abY * abY) * math.sqrt(cbX * cbX + cbY * cbY);
    if (magnitude == 0) {
      return fallback;
    }

    final dot = abX * cbX + abY * cbY;
    final normalized = (dot / magnitude).clamp(-1.0, 1.0);
    return math.acos(normalized) * 180 / math.pi;
  }

  static double verticalTilt(
    FrameLandmark? top,
    FrameLandmark? bottom, {
    double fallback = 90,
  }) {
    if (top == null || bottom == null) {
      return fallback;
    }

    final deltaX = (top.x - bottom.x).abs();
    final deltaY = (top.y - bottom.y).abs();
    if (deltaX == 0 && deltaY == 0) {
      return fallback;
    }

    return math.atan2(deltaX, deltaY == 0 ? 0.0001 : deltaY) * 180 / math.pi;
  }

  static double averageVisibleConfidence(Iterable<FrameLandmark?> landmarks) {
    var total = 0.0;
    var count = 0;
    for (final landmark in landmarks) {
      if (landmark == null) {
        continue;
      }
      total += landmark.confidence;
      count++;
    }
    if (count == 0) {
      return 0;
    }
    return total / count;
  }

  static double normalizedOffsetFromLine({
    required FrameLandmark lineStart,
    required FrameLandmark point,
    required FrameLandmark lineEnd,
  }) {
    final lineLength = distance(lineStart, lineEnd);
    if (lineLength == 0) {
      return 0;
    }

    final lineDeltaX = lineEnd.x - lineStart.x;
    if (lineDeltaX.abs() < 0.0001) {
      return (point.y - ((lineStart.y + lineEnd.y) / 2)) / lineLength;
    }

    final progress = (point.x - lineStart.x) / lineDeltaX;
    final lineY = lineStart.y + (lineEnd.y - lineStart.y) * progress;
    return (point.y - lineY) / lineLength;
  }
}
