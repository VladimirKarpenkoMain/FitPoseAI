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
}
