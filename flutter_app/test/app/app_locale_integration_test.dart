import 'package:fitness_ai/main.dart';
import 'package:fitness_ai/providers/api_provider.dart';
import 'package:fitness_ai/providers/app_locale_provider.dart';
import 'package:fitness_ai/providers/auth_provider.dart';
import 'package:fitness_ai/providers/workout_provider.dart';
import 'package:fitness_ai/router/app_router.dart';
import 'package:fitness_ai/screens/home_screen.dart';
import 'package:fitness_ai/screens/settings_screen.dart';
import 'package:fitness_ai/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first launch follows the system locale', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          systemLocaleProvider.overrideWithValue(const Locale('ru', 'RU')),
          apiServiceProvider.overrideWithValue(_FakeApiService()),
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              const AuthState(status: AuthStatus.authenticated),
            ),
          ),
          workoutProvider.overrideWith(
            (ref) => _FakeWorkoutNotifier(const WorkoutState(workouts: [])),
          ),
          routerProvider.overrideWithValue(_buildRouter()),
        ],
        child: const FitnessAIApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Настройки'), findsNothing);
    expect(find.text('Начать сейчас'), findsOneWidget);
  });

  testWidgets('persisted override wins after app rebuild', (tester) async {
    SharedPreferences.setMockInitialValues({
      appLocaleStorageKey: 'ru-RU',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          systemLocaleProvider.overrideWithValue(const Locale('en', 'US')),
          apiServiceProvider.overrideWithValue(_FakeApiService()),
          authProvider.overrideWith(
            (ref) => _FakeAuthNotifier(
              const AuthState(status: AuthStatus.authenticated),
            ),
          ),
          workoutProvider.overrideWith(
            (ref) => _FakeWorkoutNotifier(const WorkoutState(workouts: [])),
          ),
          routerProvider.overrideWithValue(_buildRouter()),
        ],
        child: const FitnessAIApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Начать сейчас'), findsOneWidget);
  });
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
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
