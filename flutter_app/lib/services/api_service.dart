import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/user.dart';
import '../models/workout.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )),
        _storage = const FlutterSecureStorage() {
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔑 Token added to request: ${options.path}');
        } else {
          print('⚠️ No token found for request: ${options.path}');
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('❌ API Error: ${error.response?.statusCode} - ${error.message}');
        return handler.next(error);
      },
    ));

    // Add logging interceptor (debug only)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  // ============ AUTH ============

  Future<User> register(String email, String password) async {
    final response = await _dio.post(
      ApiConfig.register,
      data: {
        'email': email,
        'password': password,
      },
    );
    return User.fromJson(response.data);
  }

  Future<AuthToken> login(String email, String password) async {
    print('🔐 Logging in...');
    final response = await _dio.post(
      ApiConfig.login,
      data: FormData.fromMap({
        'username': email,
        'password': password,
      }),
    );
    final token = AuthToken.fromJson(response.data);
    await _storage.write(key: 'access_token', value: token.accessToken);
    print('✅ Token saved: ${token.accessToken.substring(0, 20)}...');
    return token;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    print('🚪 Logged out');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    print('🔍 Checking auth status: ${token != null}');
    return token != null;
  }

  // ============ WORKOUTS ============

  Future<List<Workout>> getWorkouts() async {
    print('📋 Fetching workouts...');
    final response = await _dio.get(ApiConfig.workouts);
    return (response.data as List)
        .map((json) => Workout.fromJson(json))
        .toList();
  }

  Future<Workout> createWorkout({
    required String exerciseType,
    required int repCount,
    int? averageQualityScore,
    Map<String, dynamic>? analysis,
  }) async {
    print('💪 Creating workout: $exerciseType, $repCount reps');
    try {
      final response = await _dio.post(
        ApiConfig.workouts,
        data: {
          'exercise_type': exerciseType,
          'rep_count': repCount,
          if (averageQualityScore != null) 'average_quality_score': averageQualityScore,
          if (analysis != null) 'analysis': analysis,
        },
      );
      print('✅ Workout created successfully: ${response.data}');
      return Workout.fromJson(response.data);
    } catch (e) {
      print('❌ Failed to create workout: $e');
      rethrow;
    }
  }
}
