import 'dart:math';

/// Smooths angle values over time using exponential moving average.
/// Prevents single-frame spikes from causing false state transitions.
class AngleSmoother {
  final double _alpha; // Smoothing factor (0..1), lower = more smoothing
  double? _smoothed;

  AngleSmoother({double alpha = 0.4}) : _alpha = alpha;

  /// Returns smoothed angle value.
  double update(double rawAngle) {
    if (_smoothed == null) {
      _smoothed = rawAngle;
    } else {
      _smoothed = _alpha * rawAngle + (1 - _alpha) * _smoothed!;
    }
    return _smoothed!;
  }

  double? get value => _smoothed;

  void reset() => _smoothed = null;
}

/// Requires N consecutive frames meeting a condition before confirming.
/// Prevents accidental state transitions from single noisy frames.
class FrameStabilizer {
  final int requiredFrames;
  int _consecutiveCount = 0;
  bool _lastCondition = false;

  FrameStabilizer({this.requiredFrames = 3});

  /// Returns true only when the condition has been true for [requiredFrames] consecutive calls.
  bool update(bool condition) {
    if (condition) {
      _consecutiveCount++;
    } else {
      _consecutiveCount = 0;
    }
    _lastCondition = condition;
    return _consecutiveCount >= requiredFrames;
  }

  void reset() {
    _consecutiveCount = 0;
    _lastCondition = false;
  }
}

/// Utility class for pose geometry calculations
class PoseGeometry {
  /// Calculates the angle between three points in degrees.
  /// 
  /// The angle is calculated at point B (the middle point):
  ///   A
  ///    \
  ///     B <- vertex of the angle
  ///    /
  ///   C
  /// 
  /// Formula: angle = arccos((BA · BC) / (|BA| * |BC|))
  /// 
  /// Returns the angle in degrees (0-180).
  static double getAngle(Point<double> a, Point<double> b, Point<double> c) {
    // Vectors BA and BC
    final ba = Point(a.x - b.x, a.y - b.y);
    final bc = Point(c.x - b.x, c.y - b.y);

    // Dot product BA · BC
    final dotProduct = ba.x * bc.x + ba.y * bc.y;

    // Vector magnitudes
    final magnitudeBA = sqrt(ba.x * ba.x + ba.y * ba.y);
    final magnitudeBC = sqrt(bc.x * bc.x + bc.y * bc.y);

    // Avoid division by zero
    if (magnitudeBA == 0 || magnitudeBC == 0) {
      return 180.0;
    }

    // Cosine of the angle
    double cosAngle = dotProduct / (magnitudeBA * magnitudeBC);
    
    // Clamp value to [-1, 1] to avoid acos errors
    cosAngle = cosAngle.clamp(-1.0, 1.0);

    // Convert radians to degrees
    final angleRadians = acos(cosAngle);
    final angleDegrees = angleRadians * 180 / pi;

    return angleDegrees;
  }
}
