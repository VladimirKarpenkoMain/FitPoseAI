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
  testWidgets('history screen renders quality and detail CTA for each workout', (
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
    expect(find.textContaining('81/100'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);
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
