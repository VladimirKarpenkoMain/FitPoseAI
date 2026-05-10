import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:fitness_ai/analysis/plank_hold_analyzer.dart';
import 'package:fitness_ai/services/workout_session_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'session recorder aggregates rep quality and emits extended analysis payload',
      () {
    final recorder = WorkoutSessionRecorder(
      requiredView: ExerciseView.side,
      thresholds: const {
        'phase_dwell_frames': 2,
        'min_rep_frames': 8,
      },
    );

    recorder.recordRep(
      const RepAnalysis(
        repIndex: 1,
        qualityScore: 62,
        qualityLabel: QualityLabel.fair,
        issues: [TechniqueIssue.depthTooShallow],
        metricsSnapshot: {'min_knee_angle': 108},
        issueEvents: [
          RepIssueEvent(
            code: 'depth_too_shallow',
            message: 'Depth target was not reached.',
            exerciseType: 'squat',
            repIndex: 1,
            frameIndex: 12,
            timestampMs: 1200,
            phase: MotionPhase.bottom,
            metricName: 'phase_knee_angle',
            actualValue: 108,
            threshold: 100,
            severity: IssueSeverity.moderate,
            metricsSnapshot: {'phase_knee_angle': 108},
          ),
        ],
        startedTimestampMs: 800,
        finishedTimestampMs: 1800,
        durationMs: 1000,
        visitedPhases: ['descent', 'bottom', 'lockout'],
        minMetrics: {'phase_knee_angle': 108},
        maxMetrics: {'phase_torso_vertical_tilt': 28},
        avgMetrics: {'phase_knee_angle': 142},
      ),
    );
    recorder.recordRep(
      const RepAnalysis(
        repIndex: 2,
        qualityScore: 88,
        qualityLabel: QualityLabel.excellent,
        issues: [],
        metricsSnapshot: {'min_knee_angle': 92},
      ),
    );

    final payload = recorder.buildAnalysisPayload(readinessTimeSeconds: 10);

    expect(payload['required_view'], 'side');
    expect(payload['analysis_version'], '2.0');
    expect(payload['readiness_time_seconds'], 10);
    expect(payload['stabilization_enabled'], isTrue);
    expect(payload['thresholds']['phase_dwell_frames'], 2);
    expect(payload['dominant_issues'], ['depth_too_shallow']);
    expect(payload['issue_events'][0]['timestamp_ms'], 1200);
    expect(payload['rep_analyses'][0]['quality_score'], 62);
    expect(payload['rep_analyses'][0]['visited_phases'],
        ['descent', 'bottom', 'lockout']);
    expect(recorder.averageQualityScore, 75);
  });

  test('session recorder emits analysis payload for hold-based workouts', () {
    final recorder = WorkoutSessionRecorder(
      requiredView: ExerciseView.side,
      thresholds: const {
        'hold_hip_offset': {'hip_sag_threshold': 0.14},
      },
    );

    recorder.recordHoldUpdate(
      const PlankHoldUpdate(
        status: PlankHoldStatus.holdingGood,
        timestampMs: 1000,
        holdDuration: Duration(seconds: 1),
        validHoldDuration: Duration(seconds: 1),
        invalidHoldDuration: Duration.zero,
        issues: [],
        message: 'Hold this position.',
        metrics: {'hold_body_line_angle': 174},
      ),
    );
    recorder.recordHoldUpdate(
      const PlankHoldUpdate(
        status: PlankHoldStatus.hipSag,
        timestampMs: 2000,
        holdDuration: Duration(seconds: 2),
        validHoldDuration: Duration(seconds: 1),
        invalidHoldDuration: Duration(seconds: 1),
        issues: [TechniqueIssue.hipSag],
        message: 'Lift hips back into a straight line.',
        metrics: {'hold_body_line_angle': 154},
      ),
    );

    final payload = recorder.buildAnalysisPayload(readinessTimeSeconds: 5);

    expect(recorder.hasAnalysis, isTrue);
    expect(recorder.averageQualityScore, 78);
    expect(payload['dominant_issues'], ['hip_sag']);
    expect(payload['hold_summary']['samples'], 2);
    expect(payload['hold_summary']['duration_seconds'], 2);
    expect(payload['hold_summary']['valid_hold_time'], 1.0);
    expect(payload['hold_summary']['invalid_hold_time'], 1.0);
    expect(payload['hold_summary']['average_quality_score'], 78);
  });

  test('session recorder emits debounced hold error events', () {
    final recorder = WorkoutSessionRecorder(
      requiredView: ExerciseView.side,
    );

    recorder.recordHoldUpdate(
      const PlankHoldUpdate(
        status: PlankHoldStatus.holdingGood,
        timestampMs: 0,
        holdDuration: Duration.zero,
        validHoldDuration: Duration.zero,
        invalidHoldDuration: Duration.zero,
        issues: [],
        message: 'Hold this position.',
        metrics: {'hold_body_line_angle': 176},
      ),
    );
    recorder.recordHoldUpdate(
      const PlankHoldUpdate(
        status: PlankHoldStatus.hipSag,
        timestampMs: 500,
        holdDuration: Duration(milliseconds: 400),
        validHoldDuration: Duration(milliseconds: 400),
        invalidHoldDuration: Duration(milliseconds: 100),
        issues: [TechniqueIssue.hipSag],
        message: 'Lift hips back into a straight line.',
        metrics: {'hold_body_line_angle': 154},
      ),
    );
    recorder.recordHoldUpdate(
      const PlankHoldUpdate(
        status: PlankHoldStatus.holdingGood,
        timestampMs: 900,
        holdDuration: Duration(milliseconds: 800),
        validHoldDuration: Duration(milliseconds: 800),
        invalidHoldDuration: Duration(milliseconds: 100),
        issues: [],
        message: 'Hold this position.',
        metrics: {'hold_body_line_angle': 176},
      ),
    );

    final payload = recorder.buildAnalysisPayload(readinessTimeSeconds: 5);
    final events = payload['hold_summary']['error_events'] as List<dynamic>;
    final errors = payload['hold_summary']['errors'] as List<dynamic>;

    expect(events, hasLength(1));
    expect(errors, events);
    expect(events.single['type'], 'hip_sag');
    expect(events.single['message'], 'Lift hips back into a straight line.');
    expect(events.single['start_time'], 0.5);
    expect(events.single['end_time'], 0.9);
  });
}
