import 'package:fitness_ai/screens/workout/widgets/workout_status_stack.dart';
import 'package:fitness_ai/screens/workout/widgets/workout_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('workout progress card presents compact coach HUD progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkoutProgressCard(
            goalText: 'Goal: 10 reps',
            primaryValue: '3',
            primaryLabel: 'reps',
            secondaryText: '7 reps left',
            progressFraction: 0.3,
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('Goal: 10 reps'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);

    final card = tester.widget<Container>(
      find.byKey(const Key('workout-progress-card-container')),
    );
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xEBFFFFFF));

    final primaryValue = tester.widget<Text>(find.text('3'));
    expect(primaryValue.style?.color, const Color(0xFFFF7A00));

    final goalText = tester.widget<Text>(find.text('Goal: 10 reps'));
    expect(goalText.style?.color, const Color(0xFF6C7788));
  });

  testWidgets(
      'workout status stack separates system status, live cue, and rep result',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkoutStatusStack(
            systemStatus: 'Turn to your side',
            liveCue: 'Go lower',
            repSummary: 'Rep counted: 62/100, depth too shallow',
          ),
        ),
      ),
    );

    expect(find.text('System status'), findsOneWidget);
    expect(find.text('Live cue'), findsOneWidget);
    expect(find.text('Last rep'), findsOneWidget);

    final stack = tester.widget<Container>(
      find.byKey(const Key('workout-status-stack-container')),
    );
    final decoration = stack.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xF2FFFFFF));

    final statusText = tester.widget<Text>(find.text('Turn to your side'));
    expect(statusText.style?.color, const Color(0xFF18212F));
  });

  testWidgets('workout status stack keeps live cue briefly after it clears', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkoutStatusStack(
            systemStatus: 'Tracking active',
            liveCue: 'Go lower',
            repSummary: '',
          ),
        ),
      ),
    );

    expect(find.text('Go lower'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkoutStatusStack(
            systemStatus: 'Tracking active',
            liveCue: '',
            repSummary: '',
          ),
        ),
      ),
    );

    expect(find.text('Go lower'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.text('Go lower'), findsNothing);
  });
}
