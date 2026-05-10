import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/models/workout.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:fitness_ai/screens/workout/workout_analysis_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('analysis screen prioritizes progress summary before fixes', (
    tester,
  ) async {
    final workout = Workout(
      id: 1,
      userId: 1,
      exerciseType: 'pushup',
      repCount: 24,
      date: DateTime.parse('2026-05-06T08:00:00Z'),
      averageQualityScore: 88,
      analysis: const WorkoutAnalysis(
        requiredView: ExerciseView.side,
        readinessTimeSeconds: 5,
        dominantIssues: [TechniqueIssue.hipSag],
        repAnalyses: [
          RepAnalysis(
            repIndex: 1,
            qualityScore: 88,
            qualityLabel: QualityLabel.excellent,
            issues: [TechniqueIssue.hipSag],
            metricsSnapshot: {'body_line_angle': 159},
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('en', 'US'),
        ],
        home: WorkoutAnalysisScreen(workout: workout),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Session analysis'), findsOneWidget);
    expect(find.text('What went well'), findsOneWidget);
    expect(find.text('What to improve next'), findsOneWidget);
    expect(find.textContaining('88/100'), findsOneWidget);
  });

  testWidgets('analysis screen renders hold summary when there are no reps', (
    tester,
  ) async {
    final workout = Workout(
      id: 2,
      userId: 1,
      exerciseType: 'plank',
      repCount: 0,
      date: DateTime.parse('2026-05-06T08:00:00Z'),
      averageQualityScore: 78,
      analysis: const WorkoutAnalysis(
        requiredView: ExerciseView.side,
        readinessTimeSeconds: 5,
        dominantIssues: [TechniqueIssue.hipSag],
        repAnalyses: [],
        holdSummary: HoldAnalysisSummary(
          samples: 2,
          durationSeconds: 2,
          averageQualityScore: 78,
          latestStatus: 'hip_sag',
          latestMetrics: {'hold_body_line_angle': 154},
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('en', 'US'),
        ],
        home: WorkoutAnalysisScreen(workout: workout),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hold breakdown'), findsOneWidget);
    expect(find.text('2 sec hold - 2 analysis samples'), findsOneWidget);
    expect(find.textContaining('78/100'), findsOneWidget);
  });

  testWidgets('analysis screen explains missing technique data', (
    tester,
  ) async {
    final workout = Workout(
      id: 3,
      userId: 1,
      exerciseType: 'squat',
      repCount: 5,
      date: DateTime.parse('2026-05-06T08:00:00Z'),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('en', 'US'),
        ],
        home: WorkoutAnalysisScreen(workout: workout),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Analysis unavailable'), findsOneWidget);
    expect(find.text('5 reps tracked'), findsOneWidget);
    expect(
        find.textContaining('Technique data was not recorded'), findsOneWidget);
    expect(find.text('--/100'), findsNothing);
    expect(find.text('Latest rep breakdown'), findsNothing);
  });
}
