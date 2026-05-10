import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/models/workout.dart';
import 'package:fitness_ai/providers/workout_provider.dart';
import 'package:fitness_ai/screens/history_screen.dart';
import 'package:fitness_ai/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('history tab content renders title without an app bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutProvider.overrideWith(
            (ref) => _HistoryNotifier(const WorkoutState(workouts: [])),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en', 'US'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          home: HistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Workout history'), findsOneWidget);
  });

  testWidgets('history screen renders summary and grouped workout rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutProvider.overrideWith(
            (ref) => _HistoryNotifier(
              WorkoutState(
                workouts: [
                  Workout(
                    id: 1,
                    userId: 1,
                    exerciseType: 'squat',
                    repCount: 16,
                    date: DateTime.parse('2026-05-06T07:30:00Z'),
                    averageQualityScore: 81,
                  ),
                  Workout(
                    id: 2,
                    userId: 1,
                    exerciseType: 'pushup',
                    repCount: 9,
                    date: DateTime.parse('2026-05-06T09:45:00Z'),
                    averageQualityScore: 64,
                  ),
                  Workout(
                    id: 3,
                    userId: 1,
                    exerciseType: 'jumping_jacks',
                    repCount: 4,
                    date: DateTime.parse('2026-05-05T20:15:00Z'),
                    averageQualityScore: 84,
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en', 'US'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          home: HistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Workout history'), findsOneWidget);
    expect(find.text('Average quality'), findsOneWidget);
    expect(find.text('76/100'), findsOneWidget);
    expect(find.text('Workouts'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('05/06/2026'), findsOneWidget);
    expect(find.text('05/05/2026'), findsOneWidget);
    expect(find.text('Push-ups'), findsOneWidget);
    expect(find.textContaining('9 reps'), findsOneWidget);
    expect(find.textContaining('09:45'), findsOneWidget);
    expect(find.text('View details'), findsNothing);
  });
}

class _HistoryNotifier extends WorkoutNotifier {
  _HistoryNotifier(WorkoutState state) : super(_FakeApiService()) {
    this.state = state;
  }

  @override
  Future<void> fetchWorkouts() async {}
}

class _FakeApiService extends ApiService {}
