import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

class WorkoutState {
  final List<Workout> workouts;
  final bool isLoading;
  final String? errorMessage;

  const WorkoutState({
    this.workouts = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WorkoutState copyWith({
    List<Workout>? workouts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WorkoutState(
      workouts: workouts ?? this.workouts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  final ApiService _apiService;

  WorkoutNotifier(this._apiService) : super(const WorkoutState());

  Future<void> fetchWorkouts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final workouts = await _apiService.getWorkouts();
      state = state.copyWith(workouts: workouts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load workouts',
      );
    }
  }

  Future<void> addWorkout(String exerciseType, int repCount) async {
    try {
      final workout = await _apiService.createWorkout(
        exerciseType: exerciseType,
        repCount: repCount,
      );
      state = state.copyWith(workouts: [workout, ...state.workouts]);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save workout');
    }
  }

  Future<Workout> createWorkout({
    required String exerciseType,
    required int repCount,
    int? averageQualityScore,
    Map<String, dynamic>? analysis,
  }) async {
    try {
      final workout = await _apiService.createWorkout(
        exerciseType: exerciseType,
        repCount: repCount,
        averageQualityScore: averageQualityScore,
        analysis: analysis,
      );
      await fetchWorkouts();
      return workout;
    } catch (e) {
      rethrow;
    }
  }
}

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return WorkoutNotifier(apiService);
});
