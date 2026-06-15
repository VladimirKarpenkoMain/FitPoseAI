import 'package:fitness_ai/screens/workout/widgets/workout_hud_overlay.dart';
import 'package:fitness_ai/screens/workout/widgets/workout_progress_card.dart';
import 'package:fitness_ai/screens/workout/widgets/workout_status_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WorkoutHudOverlay uses landscape HUD regions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutHudOverlay(
            title: 'Squat',
            onBack: () {},
            primaryValue: '0',
            primaryLabel: 'reps',
            secondaryText: '10 reps',
            goalText: 'Goal: 10 reps',
            systemStatus: 'Keep one full side of your body visible',
            startGuide:
                'Keep the required body points visible and hold the start pose.',
            liveCue: '',
            repSummary: '',
            progressCard: const Text('progress'),
            statusStack: const Text('status'),
            finishButton: const Text('finish'),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('workout-hud-landscape-progress')),
        findsOneWidget);
    expect(
        find.byKey(const Key('workout-hud-landscape-status')), findsOneWidget);
    expect(
        find.byKey(const Key('workout-hud-landscape-finish')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WorkoutHudOverlay uses light landscape panels', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutHudOverlay(
            title: 'Squat',
            onBack: () {},
            primaryValue: '8',
            primaryLabel: 'reps',
            secondaryText: '2 reps',
            goalText: 'Goal: 10 reps',
            systemStatus: 'Tracking active',
            startGuide: '',
            liveCue: '',
            repSummary: '',
            progressCard: const SizedBox.shrink(),
            statusStack: const SizedBox.shrink(),
            finishButton: const Text('Finish'),
          ),
        ),
      ),
    );

    final counter = tester.widget<Container>(
      find.byKey(const Key('workout-hud-landscape-counter')),
    );
    final counterDecoration = counter.decoration! as BoxDecoration;
    expect(counterDecoration.color, const Color(0xEBFFFFFF));

    final status = tester.widget<Container>(
      find.byKey(const Key('workout-hud-landscape-readable-status')),
    );
    final statusDecoration = status.decoration! as BoxDecoration;
    expect(statusDecoration.color, const Color(0xEBFFFFFF));

    final labelText = tester.widget<Text>(find.text('REPS'));
    expect(labelText.style?.color, const Color(0xFF18212F));
  });

  testWidgets('WorkoutHudOverlay keeps real landscape controls compact', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutHudOverlay(
            title: 'Squat',
            onBack: () {},
            primaryValue: '0',
            primaryLabel: 'reps',
            secondaryText: '10 reps',
            goalText: 'Goal: 10 reps',
            systemStatus: 'Keep one full side of your body visible',
            startGuide:
                'Keep the required body points visible and hold the start pose.',
            liveCue: '',
            repSummary: '',
            progressCard: const WorkoutProgressCard(
              goalText: 'Goal: 10 reps',
              primaryValue: '0',
              primaryLabel: 'reps',
              secondaryText: '10 reps',
              progressFraction: 0,
            ),
            statusStack: const WorkoutStatusStack(
              systemStatus: 'Keep one full side of your body visible',
              liveCue: '',
              repSummary: '',
              startGuide:
                  'Keep the required body points visible and hold the start pose.',
            ),
            finishButton: const Text('Finish'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final progressBox = tester.renderObject<RenderBox>(
      find.byKey(const Key('workout-hud-landscape-progress')),
    );
    final statusBox = tester.renderObject<RenderBox>(
      find.byKey(const Key('workout-hud-landscape-status')),
    );

    expect(progressBox.size.height, lessThanOrEqualTo(96));
    expect(statusBox.size.height, lessThanOrEqualTo(96));
  });

  testWidgets('WorkoutHudOverlay shows readable landscape workout text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutHudOverlay(
            title: 'Squat',
            onBack: () {},
            primaryValue: '12',
            primaryLabel: 'reps',
            secondaryText: '3 reps',
            goalText: 'Goal: 15 reps',
            systemStatus: 'Tracking active',
            startGuide: '',
            liveCue: '',
            repSummary: '',
            progressCard: const SizedBox.shrink(),
            statusStack: const SizedBox.shrink(),
            finishButton: const Text('Finish'),
          ),
        ),
      ),
    );

    expect(
        find.byKey(const Key('workout-hud-landscape-counter')), findsOneWidget);
    expect(find.byKey(const Key('workout-hud-landscape-readable-status')),
        findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Tracking active'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
