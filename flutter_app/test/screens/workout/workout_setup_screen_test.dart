import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/models/exercise_type.dart';
import 'package:fitness_ai/screens/workout/workout_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'setup screen surfaces localized coaching message and goal hierarchy',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en', 'US'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
          ],
          home: WorkoutSetupScreen(exerciseType: ExerciseType.squat),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workout setup'), findsOneWidget);
      expect(
        find.text('AI will track your form, pace, and repeat quality live.'),
        findsOneWidget,
      );
      expect(find.text('Choose your target'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
    },
  );
}
