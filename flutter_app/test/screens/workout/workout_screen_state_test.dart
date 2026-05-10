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
  });
}
