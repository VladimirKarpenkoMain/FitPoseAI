import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/models/workout.dart';
import 'package:fitness_ai/providers/workout_provider.dart';
import 'package:fitness_ai/screens/home_screen.dart';
import 'package:fitness_ai/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('start now opens the default workout setup flow', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/workout-setup/squat',
          builder: (context, state) => const Scaffold(
            body: Text('Workout setup destination'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutProvider.overrideWith(
            (ref) => _FakeWorkoutNotifier(const WorkoutState(workouts: [])),
          ),
        ],
        child: MaterialApp.router(
          locale: const Locale('en', 'US'),
          routerConfig: router,
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start now'));
    await tester.pumpAndSettle();

    expect(find.text('Workout setup destination'), findsOneWidget);
  });

  testWidgets('home dashboard renders Russian copy when locale is Russian', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutProvider.overrideWith(
            (ref) => _FakeWorkoutNotifier(
              WorkoutState(
                workouts: [
                  Workout(
                    id: 1,
                    userId: 1,
                    exerciseType: 'squat',
                    repCount: 14,
                    date: DateTime.parse('2026-05-06T07:30:00Z'),
                    averageQualityScore: 81,
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

class _FakeWorkoutNotifier extends WorkoutNotifier {
  _FakeWorkoutNotifier(WorkoutState state) : super(_FakeApiService()) {
    this.state = state;
  }

  @override
  Future<void> fetchWorkouts() async {}
}

class _FakeApiService extends ApiService {}
