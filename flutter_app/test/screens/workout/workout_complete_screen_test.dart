import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/models/workout.dart';
import 'package:fitness_ai/models/workout_analysis.dart';
import 'package:fitness_ai/screens/workout/workout_complete_screen.dart';
import 'package:fitness_ai/screens/workout/workout_route_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('workout complete screen shows summary and CTA to analysis', (
    tester,
  ) async {
    final workout = Workout(
      id: 1,
      userId: 1,
      exerciseType: 'squat',
      repCount: 18,
      date: DateTime.parse('2026-05-06T08:00:00Z'),
      averageQualityScore: 84,
      analysis: const WorkoutAnalysis(
        requiredView: ExerciseView.side,
        readinessTimeSeconds: 5,
        dominantIssues: [TechniqueIssue.depthTooShallow],
        repAnalyses: [],
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
        home: WorkoutCompleteScreen(
          args: WorkoutCompleteArgs(
            workout: workout,
            goalLabel: '18 reps',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.textContaining('18 reps'), findsOneWidget);
    expect(find.text('View analysis'), findsOneWidget);
    expect(find.text('Back to home'), findsOneWidget);
  });

  testWidgets('view analysis keeps completion screen in back stack', (
    tester,
  ) async {
    final workout = Workout(
      id: 2,
      userId: 1,
      exerciseType: 'squat',
      repCount: 12,
      date: DateTime.parse('2026-05-06T08:00:00Z'),
      averageQualityScore: 82,
      analysis: const WorkoutAnalysis(
        requiredView: ExerciseView.side,
        readinessTimeSeconds: 5,
        dominantIssues: [],
        repAnalyses: [],
      ),
    );
    final router = GoRouter(
      initialLocation: '/workout-complete',
      routes: [
        GoRoute(
          path: '/workout-complete',
          builder: (context, state) => WorkoutCompleteScreen(
            args: WorkoutCompleteArgs(workout: workout, goalLabel: '12 reps'),
          ),
        ),
        GoRoute(
          path: '/analysis',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Analysis route')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
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
        routerConfig: router,
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('View analysis'));
    await tester.pumpAndSettle();

    expect(find.text('Analysis route'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Workout complete'), findsOneWidget);
  });
}
