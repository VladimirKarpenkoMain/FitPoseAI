import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_ai/providers/workout_provider.dart';
import 'package:fitness_ai/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createWorkout appends created workout without refetching history',
      () async {
    final adapter = _QueueAdapter([
      const _JsonResponse(201, {
        'id': 7,
        'user_id': 1,
        'exercise_type': 'squat',
        'rep_count': 12,
        'date': '2026-05-08T12:00:00Z',
        'average_quality_score': 82,
        'analysis': null,
      }),
      const _JsonResponse(200, []),
    ]);
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = adapter;
    final service = ApiService(dio: dio, storage: _MemoryTokenStorage());
    final notifier = WorkoutNotifier(service);

    final workout = await notifier.createWorkout(
      exerciseType: 'squat',
      repCount: 12,
      averageQualityScore: 82,
    );

    expect(workout.id, 7);
    expect(notifier.state.workouts.map((item) => item.id), [7]);
    expect(adapter.requests, ['/workouts']);
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

class _JsonResponse {
  const _JsonResponse(this.statusCode, this.body);

  final int statusCode;
  final dynamic body;
}

class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this._responses);

  final List<_JsonResponse> _responses;
  final List<String> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    requests.add(options.path);

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
