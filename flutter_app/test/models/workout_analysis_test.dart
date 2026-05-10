import 'package:fitness_ai/models/workout.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Workout parses nested analysis payload and preserves summary fields',
      () {
    final json = {
      'id': 17,
      'user_id': 4,
      'exercise_type': 'squat',
      'rep_count': 8,
      'date': '2026-05-05T10:30:00Z',
      'average_quality_score': 74,
      'analysis': {
        'analysis_version': '2.0',
        'required_view': 'side',
        'readiness_time_seconds': 10,
        'stabilization_enabled': true,
        'thresholds': {
          'phase_dwell_frames': 2,
          'min_rep_frames': 8,
        },
        'dominant_issues': ['depth_too_shallow'],
        'issue_events': [
          {
            'code': 'excessive_forward_lean',
            'message': 'Torso leaned too far forward.',
            'exercise_type': 'squat',
            'rep_index': 1,
            'frame_index': 54,
            'timestamp_ms': 1800,
            'phase': 'descent',
            'metric_name': 'phase_torso_vertical_tilt',
            'actual_value': 42.5,
            'threshold': 35,
            'severity': 'moderate',
            'metrics_snapshot': {'phase_torso_vertical_tilt': 42.5},
          },
        ],
        'rep_analyses': [
          {
            'rep_index': 1,
            'quality_score': 62,
            'quality_label': 'fair',
            'issues': ['depth_too_shallow'],
            'metrics_snapshot': {
              'min_knee_angle': 108,
            },
            'started_timestamp_ms': 1200,
            'finished_timestamp_ms': 3600,
            'duration_ms': 2400,
            'visited_phases': ['descent', 'bottom', 'lockout'],
            'issue_events': [
              {
                'code': 'excessive_forward_lean',
                'message': 'Torso leaned too far forward.',
                'exercise_type': 'squat',
                'rep_index': 1,
                'frame_index': 54,
                'timestamp_ms': 1800,
                'phase': 'descent',
                'metric_name': 'phase_torso_vertical_tilt',
                'actual_value': 42.5,
                'threshold': 35,
                'severity': 'moderate',
                'metrics_snapshot': {'phase_torso_vertical_tilt': 42.5},
              },
            ],
            'min_metrics': {'phase_knee_angle': 108},
            'max_metrics': {'phase_torso_vertical_tilt': 42.5},
            'avg_metrics': {'phase_knee_angle': 138},
          },
        ],
      },
    };

    final workout = Workout.fromJson(json);

    expect(workout.averageQualityScore, 74);
    expect(workout.analysis, isNotNull);
    expect(workout.analysis!.analysisVersion, '2.0');
    expect(workout.analysis!.requiredView, ExerciseView.side);
    expect(workout.analysis!.readinessTimeSeconds, 10);
    expect(workout.analysis!.stabilizationEnabled, isTrue);
    expect(workout.analysis!.thresholds['phase_dwell_frames'], 2);
    expect(workout.analysis!.dominantIssues, [TechniqueIssue.depthTooShallow]);
    expect(
        workout.analysis!.repAnalyses.single.qualityLabel, QualityLabel.fair);
    expect(workout.analysis!.issueEvents.single.phase, MotionPhase.descent);
    expect(workout.analysis!.repAnalyses.single.issueEvents.single.timestampMs,
        1800);
    expect(
      workout.toJson()['analysis']['rep_analyses'][0]['metrics_snapshot']
          ['min_knee_angle'],
      108,
    );
  });

  test('Workout parses hold summary analysis payload', () {
    final workout = Workout.fromJson({
      'id': 18,
      'user_id': 4,
      'exercise_type': 'plank',
      'rep_count': 0,
      'date': '2026-05-05T10:30:00Z',
      'average_quality_score': 78,
      'analysis': {
        'analysis_version': '2.0',
        'required_view': 'side',
        'readiness_time_seconds': 5,
        'dominant_issues': ['hip_sag'],
        'rep_analyses': [],
        'hold_summary': {
          'samples': 2,
          'duration_seconds': 2,
          'average_quality_score': 78,
          'latest_status': 'hip_sag',
          'latest_metrics': {'hold_body_line_angle': 154},
        },
      },
    });

    expect(workout.analysis!.holdSummary, isNotNull);
    expect(workout.analysis!.holdSummary!.samples, 2);
    expect(workout.analysis!.holdSummary!.durationSeconds, 2);
    expect(workout.analysis!.holdSummary!.averageQualityScore, 78);
    expect(workout.analysis!.holdSummary!.latestStatus, 'hip_sag');
    expect(
      workout.toJson()['analysis']['hold_summary']['latest_metrics']
          ['hold_body_line_angle'],
      154,
    );
  });
}
