import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/models/workout.dart';
import 'package:fitness_ai/providers/auth_provider.dart';
import 'package:fitness_ai/providers/workout_provider.dart';
import 'package:fitness_ai/router/app_router.dart';
import 'package:fitness_ai/screens/home_screen.dart';
import 'package:fitness_ai/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home and history share bottom navigation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              const AuthState(status: AuthStatus.authenticated),
            ),
          ),
          workoutProvider.overrideWith(
            (ref) => _FakeWorkoutNotifier(const WorkoutState(workouts: [])),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            return MaterialApp.router(
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
              routerConfig: ref.watch(routerProvider),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Workout history'), findsOneWidget);

    await tester.tap(find.text('Workout history').first);
    await tester.pumpAndSettle();

    expect(find.text('Workout history'), findsWidgets);
    expect(find.text('No completed sessions yet'), findsOneWidget);
  });

  testWidgets('bottom navigation labels follow the app locale', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              const AuthState(status: AuthStatus.authenticated),
            ),
          ),
          workoutProvider.overrideWith(
            (ref) => _FakeWorkoutNotifier(const WorkoutState(workouts: [])),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            return MaterialApp.router(
              locale: const Locale('ru', 'RU'),
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
              routerConfig: ref.watch(routerProvider),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Главная'), findsOneWidget);
    expect(find.text('История тренировок'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('History'), findsNothing);
  });

  testWidgets('home starts with workout choices without weekly progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutProvider.overrideWith(
            (ref) => _FakeWorkoutNotifier(const WorkoutState(workouts: [])),
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
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start now'), findsNothing);
    expect(find.text('Your AI coach for cleaner reps'), findsNothing);
    expect(find.text('START WORKOUT'), findsOneWidget);
    expect(find.text('This week'), findsNothing);
    expect(find.text('See full history'), findsNothing);
  });

  testWidgets('home does not show latest workout preview', (
    tester,
  ) async {
    final latestWorkout = Workout(
      id: 1,
      userId: 1,
      exerciseType: 'squat',
      repCount: 14,
      date: DateTime.parse('2026-05-06T07:30:00Z'),
      averageQualityScore: 81,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              const AuthState(status: AuthStatus.authenticated),
            ),
          ),
          workoutProvider.overrideWith(
            (ref) => _FakeWorkoutNotifier(
              WorkoutState(workouts: [latestWorkout]),
            ),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            return MaterialApp.router(
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
              routerConfig: ref.watch(routerProvider),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latest session'), findsNothing);
    expect(find.text('Open analysis'), findsNothing);
    expect(find.text('SQUAT'), findsNothing);
  });

  testWidgets('home highlights only weekly workout count', (
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
                  Workout(
                    id: 2,
                    userId: 1,
                    exerciseType: 'pushup',
                    repCount: 8,
                    date: DateTime.parse('2026-05-07T07:30:00Z'),
                    averageQualityScore: 79,
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
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Train with cleaner form'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('workouts this week'), findsOneWidget);
    expect(find.text('Average quality'), findsNothing);
    expect(find.text('total reps'), findsNothing);
  });

  testWidgets('exercise labels are constrained inside their cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workoutProvider.overrideWith(
            (ref) => _FakeWorkoutNotifier(const WorkoutState(workouts: [])),
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
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final jumpingJacksText =
        tester.widget<Text>(find.text('JUMPING JACKS').first);
    expect(jumpingJacksText.maxLines, 2);
    expect(jumpingJacksText.overflow, TextOverflow.ellipsis);
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

    expect(find.text('Начать сейчас'), findsNothing);
    expect(find.text('НАЧАТЬ ТРЕНИРОВКУ'), findsOneWidget);
    expect(find.text('Эта неделя'), findsNothing);
  });
}

class _FakeWorkoutNotifier extends WorkoutNotifier {
  _FakeWorkoutNotifier(WorkoutState state) : super(_FakeApiService()) {
    this.state = state;
  }

  @override
  Future<void> fetchWorkouts() async {}
}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(AuthState state) : super(_FakeApiService()) {
    this.state = state;
  }

  @override
  Future<void> checkAuthStatus() async {}
}

class _FakeApiService extends ApiService {}
