import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/user.dart';
import '../models/workout.dart';

class ApiService {
  ApiService({
    Dio? dio,
    TokenStorage? storage,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ),
        _storage = storage ?? SecureTokenStorage() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] != true) {
            final token = await _storage.read(key: 'access_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (kDebugMode) {
            debugPrint(
              'API Error: ${error.response?.statusCode} - ${error.message}',
            );
          }
          if (await _shouldRefresh(error)) {
            try {
              final token = await _refreshAccessToken();
              final retryOptions = _copyRequestOptions(error.requestOptions);
              retryOptions.headers['Authorization'] =
                  'Bearer ${token.accessToken}';
              retryOptions.extra['retriedAfterRefresh'] = true;

              final response = await _dio.fetch<dynamic>(retryOptions);
              return handler.resolve(response);
            } catch (refreshError) {
              await logout();
              if (kDebugMode) {
                debugPrint('Token refresh failed: $refreshError');
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        requestBody: false,
        responseBody: false,
        error: true,
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _storage;

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
    final response = await _dio.post(
      ApiConfig.login,
      data: FormData.fromMap({
        'username': email,
        'password': password,
      }),
    );
    final token = AuthToken.fromJson(response.data);
    await _saveToken(token);
    return token;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<void> _saveToken(AuthToken token) async {
    await _storage.write(key: 'access_token', value: token.accessToken);
    await _storage.write(key: 'refresh_token', value: token.refreshToken);
  }

  Future<bool> _shouldRefresh(DioException error) async {
    if (error.response?.statusCode != 401) {
      return false;
    }
    if (error.requestOptions.extra['retriedAfterRefresh'] == true) {
      return false;
    }
    if (error.requestOptions.extra['skipAuth'] == true) {
      return false;
    }
    final refreshToken = await _storage.read(key: 'refresh_token');
    return refreshToken != null;
  }

  Future<AuthToken> _refreshAccessToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      throw StateError('No refresh token found');
    }

    final response = await _dio.post(
      ApiConfig.refresh,
      data: {'refresh_token': refreshToken},
      options: Options(extra: {'skipAuth': true}),
    );
    final token = AuthToken.fromJson(response.data);
    await _saveToken(token);
    return token;
  }

  RequestOptions _copyRequestOptions(RequestOptions requestOptions) {
    return requestOptions.copyWith(
      data: requestOptions.data,
      headers: Map<String, dynamic>.from(requestOptions.headers),
      extra: Map<String, dynamic>.from(requestOptions.extra),
    );
  }

  Future<List<Workout>> getWorkouts() async {
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
    try {
      final response = await _dio.post(
        ApiConfig.workouts,
        data: {
          'exercise_type': exerciseType,
          'rep_count': repCount,
          if (averageQualityScore != null)
            'average_quality_score': averageQualityScore,
          if (analysis != null) 'analysis': analysis,
        },
      );
      final workout = Workout.fromJson(response.data);
      if (kDebugMode) {
        debugPrint('Workout created successfully: ${workout.id}');
      }
      return workout;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to create workout: $e');
      }
      rethrow;
    }
  }
}

abstract class TokenStorage {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String? value});

  Future<void> delete({required String key});
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String? value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}
