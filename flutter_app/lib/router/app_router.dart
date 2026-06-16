import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../models/exercise_type.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/settings_screen.dart';
import '../screens/workout/workout_analysis_screen.dart';
import '../screens/workout/workout_complete_screen.dart';
import '../screens/workout/workout_route_args.dart';
import '../screens/workout/workout_screen.dart';
import '../screens/workout/workout_setup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        return null;
      }

      if (!isAuth && !isAuthRoute) {
        return '/auth';
      }

      if (isAuth && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainScaffold(currentIndex: 0),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const MainScaffold(currentIndex: 1),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/analysis',
        name: 'analysis',
        builder: (context, state) {
          final workout = state.extra! as Workout;
          return WorkoutAnalysisScreen(workout: workout);
        },
      ),
      GoRoute(
        path: '/workout-complete',
        name: 'workout_complete',
        builder: (context, state) {
          final args = state.extra! as WorkoutCompleteArgs;
          return WorkoutCompleteScreen(args: args);
        },
      ),
      GoRoute(
        path: '/workout-setup/:exerciseType',
        name: 'workout_setup',
        builder: (context, state) {
          final exerciseTypeParam = state.pathParameters['exerciseType'];
          final exerciseType =
              ExerciseTypeExtension.fromString(exerciseTypeParam);
          return WorkoutSetupScreen(exerciseType: exerciseType);
        },
      ),
      GoRoute(
        path: '/workout/:exerciseType',
        name: 'workout',
        builder: (context, state) {
          final exerciseTypeParam = state.pathParameters['exerciseType'];
          final exerciseType =
              ExerciseTypeExtension.fromString(exerciseTypeParam);
          final plan = state.extra is WorkoutPlan
              ? state.extra! as WorkoutPlan
              : WorkoutPlan(
                  exerciseType: exerciseType,
                  goalMode: WorkoutGoalMode.reps,
                  targetValue: 10,
                );
          return WorkoutScreen(plan: plan);
        },
      ),
      // Default workout route (defaults to squat)
      GoRoute(
        path: '/workout',
        name: 'workout_default',
        builder: (context, state) => const WorkoutScreen(
          plan: WorkoutPlan(
            exerciseType: ExerciseType.squat,
            goalMode: WorkoutGoalMode.reps,
            targetValue: 10,
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(AppLocalizations.of(context).pageNotFound(state.error)),
      ),
    ),
  );
});
