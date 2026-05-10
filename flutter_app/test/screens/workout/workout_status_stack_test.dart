import 'package:fitness_ai/screens/workout/widgets/workout_status_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WorkoutStatusStack shows explicit start guide',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkoutStatusStack(
            systemStatus: 'Hold still - start in 3',
            liveCue: '',
            repSummary: '',
            startGuide: 'Start the first rep after the countdown finishes.',
          ),
        ),
      ),
    );

    expect(find.text('Hold still - start in 3'), findsOneWidget);
    expect(find.text('Start guide'), findsOneWidget);
    expect(
      find.text('Start the first rep after the countdown finishes.'),
      findsOneWidget,
    );
  });
}
