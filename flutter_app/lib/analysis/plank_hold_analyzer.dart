import '../models/workout_analysis.dart';
import 'pose_frame.dart';
import 'profiles/plank_profile.dart';
import 'rep_analyzer.dart';

enum PlankHoldStatus {
  holdingGood('holding_good'),
  hipSag('hip_sag'),
  hipsTooHigh('hips_too_high'),
  lostPosition('lost_position');

  const PlankHoldStatus(this.apiValue);

  final String apiValue;
}

class PlankHoldEvaluation {
  const PlankHoldEvaluation({
    required this.status,
    required this.issues,
    required this.message,
    required this.metrics,
  });

  final PlankHoldStatus status;
  final List<TechniqueIssue> issues;
  final String message;
  final Map<String, double> metrics;
}

class PlankHoldUpdate {
  const PlankHoldUpdate({
    required this.status,
    required this.holdDuration,
    this.timestampMs = 0,
    this.validHoldDuration = Duration.zero,
    this.invalidHoldDuration = Duration.zero,
    this.issueStartedTimestampMs,
    required this.issues,
    required this.message,
    required this.metrics,
  });

  final PlankHoldStatus status;
  final Duration holdDuration;
  final int timestampMs;
  final Duration validHoldDuration;
  final Duration invalidHoldDuration;
  final int? issueStartedTimestampMs;
  final List<TechniqueIssue> issues;
  final String message;
  final Map<String, double> metrics;
}

class PlankAnalyzerUpdate {
  const PlankAnalyzerUpdate({
    required this.holdUpdate,
    this.repUpdate,
  });

  final PlankHoldUpdate holdUpdate;
  final RepUpdate? repUpdate;
}

class PlankHoldAnalyzer {
  PlankHoldAnalyzer({
    required this.profile,
    this.invalidGrace = const Duration(milliseconds: 300),
  });

  final PlankProfile profile;
  final Duration invalidGrace;
  int? _lastTimestampMs;
  int? _pendingInvalidStartedTimestampMs;
  String? _pendingInvalidIssueCode;
  int _validHoldMs = 0;
  int _invalidHoldMs = 0;
  PlankHoldEvaluation? _lastGoodEvaluation;

  PlankAnalyzerUpdate process(PoseFrame frame) {
    final evaluation = profile.evaluateHold(frame);
    final deltaMs = _deltaSinceLastFrame(frame.timestampMs);
    final effectiveEvaluation = _effectiveEvaluation(
      evaluation: evaluation,
      timestampMs: frame.timestampMs,
      deltaMs: deltaMs,
    );

    final validHoldDuration = Duration(milliseconds: _validHoldMs);
    final invalidHoldDuration = Duration(milliseconds: _invalidHoldMs);
    final issueStartedTimestampMs =
        effectiveEvaluation.status == PlankHoldStatus.holdingGood
            ? null
            : _confirmedIssueStartedTimestampMs(frame.timestampMs);

    return PlankAnalyzerUpdate(
      holdUpdate: PlankHoldUpdate(
        status: effectiveEvaluation.status,
        timestampMs: frame.timestampMs,
        holdDuration: validHoldDuration,
        validHoldDuration: validHoldDuration,
        invalidHoldDuration: invalidHoldDuration,
        issueStartedTimestampMs: issueStartedTimestampMs,
        issues: effectiveEvaluation.issues,
        message: effectiveEvaluation.message,
        metrics: effectiveEvaluation.metrics,
      ),
    );
  }

  int _deltaSinceLastFrame(int timestampMs) {
    final lastTimestampMs = _lastTimestampMs;
    _lastTimestampMs = timestampMs;
    if (lastTimestampMs == null) {
      return 0;
    }
    final deltaMs = timestampMs - lastTimestampMs;
    return deltaMs < 0 ? 0 : deltaMs;
  }

  PlankHoldEvaluation _effectiveEvaluation({
    required PlankHoldEvaluation evaluation,
    required int timestampMs,
    required int deltaMs,
  }) {
    if (evaluation.status == PlankHoldStatus.holdingGood) {
      _pendingInvalidStartedTimestampMs = null;
      _pendingInvalidIssueCode = null;
      _validHoldMs += deltaMs;
      _lastGoodEvaluation = evaluation;
      return evaluation;
    }

    final issueCode = evaluation.issues.isEmpty
        ? evaluation.status.apiValue
        : evaluation.issues.first.apiValue;
    if (_pendingInvalidStartedTimestampMs == null ||
        _pendingInvalidIssueCode != issueCode) {
      _pendingInvalidStartedTimestampMs = timestampMs;
      _pendingInvalidIssueCode = issueCode;
    }

    final pendingDurationMs = timestampMs - _pendingInvalidStartedTimestampMs!;
    final hasGoodBaseline = _lastGoodEvaluation != null;
    if (!hasGoodBaseline || pendingDurationMs >= invalidGrace.inMilliseconds) {
      _invalidHoldMs += deltaMs;
      return evaluation;
    }

    _validHoldMs += deltaMs;
    return PlankHoldEvaluation(
      status: PlankHoldStatus.holdingGood,
      issues: const <TechniqueIssue>[],
      message: _lastGoodEvaluation!.message,
      metrics: evaluation.metrics,
    );
  }

  int? _confirmedIssueStartedTimestampMs(int fallbackTimestampMs) {
    final pendingStart = _pendingInvalidStartedTimestampMs;
    if (pendingStart == null) {
      return null;
    }
    final confirmedStart = pendingStart + invalidGrace.inMilliseconds;
    return confirmedStart > fallbackTimestampMs
        ? fallbackTimestampMs
        : confirmedStart;
  }
}
