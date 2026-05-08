import 'package:fitness_ai/models/workout_analysis.dart';
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
}
