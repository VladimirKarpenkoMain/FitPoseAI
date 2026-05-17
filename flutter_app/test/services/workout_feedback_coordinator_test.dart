import 'package:fitness_ai/services/feedback_output.dart';
import 'package:fitness_ai/services/workout_feedback_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('start countdown announces each remaining second once', () async {
    final output = _FakeFeedbackOutput();
    final coordinator = WorkoutFeedbackCoordinator(output);

    await coordinator.announceStartCountdown(3);
    await coordinator.announceStartCountdown(3);
    await coordinator.announceStartCountdown(2);

    expect(output.countdowns, [3, 2]);
    expect(output.countdownPriorities, [true, true]);
  });

  test('start countdown can be reset after readiness leaves countdown',
      () async {
    final output = _FakeFeedbackOutput();
    final coordinator = WorkoutFeedbackCoordinator(output);

    await coordinator.announceStartCountdown(3);
    coordinator.resetStartCountdown();
    await coordinator.announceStartCountdown(3);

    expect(output.countdowns, [3, 3]);
  });

  test('start countdown ignores zero and negative values', () async {
    final output = _FakeFeedbackOutput();
    final coordinator = WorkoutFeedbackCoordinator(output);

    await coordinator.announceStartCountdown(0);
    await coordinator.announceStartCountdown(-1);

    expect(output.countdowns, isEmpty);
  });

  test('readiness prompts repeat only after cooldown', () async {
    final output = _FakeFeedbackOutput();
    var now = DateTime(2026, 1, 1);
    final coordinator = WorkoutFeedbackCoordinator(
      output,
      now: () => now,
    );

    await coordinator.announceReadinessPrompt('Step into frame');
    await coordinator.announceReadinessPrompt('Step into frame');
    now = now.add(
      const Duration(
        milliseconds: WorkoutFeedbackCoordinator.readinessPromptCooldownMs - 1,
      ),
    );
    await coordinator.announceReadinessPrompt('Step into frame');
    now = now.add(const Duration(milliseconds: 1));
    await coordinator.announceReadinessPrompt('Step into frame');

    expect(output.spoken, ['Step into frame', 'Step into frame']);
  });

  test('readiness prompt changes are announced immediately', () async {
    final output = _FakeFeedbackOutput();
    final coordinator = WorkoutFeedbackCoordinator(output);

    await coordinator.announceReadinessPrompt('Step into frame');
    await coordinator.announceReadinessPrompt('Turn to your side');

    expect(output.spoken, ['Step into frame', 'Turn to your side']);
  });
}

class _FakeFeedbackOutput implements FeedbackOutput {
  final List<String> spoken = [];
  final List<int> countdowns = [];
  final List<bool> countdownPriorities = [];

  @override
  Future<void> playBeep() async {}

  @override
  Future<void> speak(String text, {bool priority = false}) async {
    spoken.add(text);
  }

  @override
  Future<void> speakRepCount(int count, {bool priority = false}) async {}

  @override
  Future<void> speakStartCountdown(
    int remainingSeconds, {
    bool priority = false,
  }) async {
    countdowns.add(remainingSeconds);
    countdownPriorities.add(priority);
  }

  @override
  Future<void> stop() async {}
}
