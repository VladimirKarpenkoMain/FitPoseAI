import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/models/workout.dart';
import 'package:fitness_ai/providers/workout_provider.dart';
import 'package:fitness_ai/screens/home_screen.dart';
import 'package:fitness_ai/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app-level smoke uses Russian copy when locale is Russian', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutProvider.overrideWith(
            (ref) => _WidgetTestWorkoutNotifier(
              WorkoutState(
                workouts: [
                  Workout(
                    id: 1,
                    userId: 1,
                    exerciseType: 'squat',
                    repCount: 10,
                    date: DateTime.parse('2026-05-06T07:00:00Z'),
                    averageQualityScore: 80,
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ru', 'RU'),
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
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Начать сейчас'), findsOneWidget);
    expect(find.text('Эта неделя'), findsOneWidget);
  });
}

class _WidgetTestWorkoutNotifier extends WorkoutNotifier {
  _WidgetTestWorkoutNotifier(WorkoutState state) : super(_FakeApiService()) {
    this.state = state;
  }

  @override
  Future<void> fetchWorkouts() async {}
}

class _FakeApiService extends ApiService {}
