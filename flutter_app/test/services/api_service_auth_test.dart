import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_ai/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createWorkout refreshes access token after 401 and retries request',
      () async {
    final adapter = _QueueAdapter([
      const _JsonResponse(401, {'detail': 'Could not validate credentials'}),
      const _JsonResponse(200, {
        'access_token': 'fresh-access-token',
        'refresh_token': 'stored-refresh-token',
        'token_type': 'bearer',
      }),
      const _JsonResponse(201, {
        'id': 7,
        'user_id': 1,
        'exercise_type': 'squat',
        'rep_count': 12,
        'date': '2026-05-08T12:00:00Z',
        'average_quality_score': 82,
        'analysis': null,
      }),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = adapter;
    final storage = _MemoryTokenStorage();
    await storage.write(key: 'access_token', value: 'expired-access-token');
    await storage.write(key: 'refresh_token', value: 'stored-refresh-token');
    final service = ApiService(dio: dio, storage: storage);

    final workout = await service.createWorkout(
      exerciseType: 'squat',
      repCount: 12,
      averageQualityScore: 82,
    );

    expect(workout.id, 7);
    expect(await storage.read(key: 'access_token'), 'fresh-access-token');
    expect(adapter.requests, hasLength(3));
    expect(adapter.requests[0].path, '/workouts');
    expect(adapter.requests[0].authorization, 'Bearer expired-access-token');
    expect(adapter.requests[1].path, '/refresh');
    expect(adapter.requests[1].authorization, isNull);
    expect(adapter.requests[2].path, '/workouts');
    expect(adapter.requests[2].authorization, 'Bearer fresh-access-token');
  });

  test('auth retry logging does not expose raw tokens', () async {
    final adapter = _QueueAdapter([
      const _JsonResponse(401, {'detail': 'Could not validate credentials'}),
      const _JsonResponse(200, {
        'access_token': 'fresh-access-token',
        'refresh_token': 'stored-refresh-token',
        'token_type': 'bearer',
      }),
      const _JsonResponse(201, {
        'id': 7,
        'user_id': 1,
        'exercise_type': 'squat',
        'rep_count': 12,
        'date': '2026-05-08T12:00:00Z',
        'average_quality_score': 82,
        'analysis': null,
      }),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = adapter;
    final storage = _MemoryTokenStorage();
    await storage.write(key: 'access_token', value: 'expired-access-token');
    await storage.write(key: 'refresh_token', value: 'stored-refresh-token');
    final service = ApiService(dio: dio, storage: storage);
    final logs = <String>[];

    await runZoned(
      () => service.createWorkout(
        exerciseType: 'squat',
        repCount: 12,
        averageQualityScore: 82,
      ),
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) {
          logs.add(line);
        },
      ),
    );

    final joinedLogs = logs.join('\n');
    expect(joinedLogs, isNot(contains('expired-access-token')));
    expect(joinedLogs, isNot(contains('fresh-access-token')));
    expect(joinedLogs, isNot(contains('stored-refresh-token')));
    expect(joinedLogs, isNot(contains('Authorization: Bearer')));
  });

  test('createWorkout logging does not print raw workout analysis payload',
      () async {
    final adapter = _QueueAdapter([
      const _JsonResponse(201, {
        'id': 7,
        'user_id': 1,
        'exercise_type': 'squat',
        'rep_count': 12,
        'date': '2026-05-08T12:00:00Z',
        'average_quality_score': 82,
        'analysis': {
          'analysis_version': '2.0',
          'required_view': 'side',
          'dominant_issues': ['very-large-analysis-marker'],
          'rep_analyses': [],
        },
      }),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = adapter;
    final service = ApiService(dio: dio, storage: _MemoryTokenStorage());
    final logs = <String>[];

    await runZoned(
      () => service.createWorkout(
        exerciseType: 'squat',
        repCount: 12,
        averageQualityScore: 82,
        analysis: const {
          'analysis_version': '2.0',
          'dominant_issues': ['very-large-analysis-marker'],
        },
      ),
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) {
          logs.add(line);
        },
      ),
    );

    final joinedLogs = logs.join('\n');
    expect(joinedLogs, isNot(contains('very-large-analysis-marker')));
    expect(joinedLogs, contains('Workout created successfully: 7'));
  });
}

class _MemoryTokenStorage implements TokenStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }
}

class _CapturedRequest {
  const _CapturedRequest(this.path, this.authorization);

  final String path;
  final String? authorization;
}

class _JsonResponse {
  const _JsonResponse(this.statusCode, this.body);

  final int statusCode;
  final Map<String, dynamic> body;
}

class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this._responses);

  final List<_JsonResponse> _responses;
  final List<_CapturedRequest> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();

    requests.add(
      _CapturedRequest(
        options.path,
        options.headers['Authorization'] as String?,
      ),
    );

    final response = _responses.removeAt(0);
    final bytes = utf8.encode(jsonEncode(response.body));
    return ResponseBody.fromBytes(
      bytes,
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
