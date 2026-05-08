import 'package:fitness_ai/screens/workout/widgets/workout_status_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('workout status stack separates system status, live cue, and rep result', (
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
