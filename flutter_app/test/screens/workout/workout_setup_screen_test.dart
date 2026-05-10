import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/models/exercise_type.dart';
import 'package:fitness_ai/screens/workout/workout_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('squat setup screen uses the squat pose asset', (tester) async {
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

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            widget.color == null &&
            (widget.image as AssetImage).assetName ==
                'assets/images/squat_pose.png',
      ),
      findsOneWidget,
    );
  });

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

      await tester.drag(find.byType(ListView), const Offset(0, -760));
      await tester.pumpAndSettle();

      expect(find.text('Choose your target'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
    },
  );

  testWidgets('setup screen explains preparation and technique before start',
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

    expect(find.text('Position'), findsOneWidget);
    expect(find.text('Technique'), findsOneWidget);
    expect(find.text('Mistakes'), findsOneWidget);
    expect(find.text('Before you start'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();

    expect(find.text('What AI checks'), findsOneWidget);
  });

  testWidgets('setup guide tabs switch between technique and mistakes',
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

    await tester.tap(find.text('Technique'));
    await tester.pumpAndSettle();

    expect(find.text('Technique cues'), findsWidgets);
    expect(find.textContaining('hips back'), findsOneWidget);

    await tester.tap(find.text('Mistakes'));
    await tester.pumpAndSettle();

    expect(find.text('Common mistakes'), findsWidgets);
    expect(find.textContaining('shallow'), findsOneWidget);
  });

  testWidgets('setup guidance changes for hold exercises', (tester) async {
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
        home: WorkoutSetupScreen(exerciseType: ExerciseType.plank),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(find.textContaining('forearm plank'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, 240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Technique'));
    await tester.pumpAndSettle();

    expect(find.textContaining('straight line'), findsOneWidget);
    expect(find.textContaining('hips'), findsWidgets);
  });

  testWidgets('back closes setup even when a guide tab is selected', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
          Locale('en', 'US'),
        ],
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const WorkoutSetupScreen(
          exerciseType: ExerciseType.squat,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Technique'));
    await tester.pumpAndSettle();

    expect(find.textContaining('hips back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutSetupScreen), findsNothing);
  });

  testWidgets('setup app bar is opaque so scrolled tabs do not bleed behind it',
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
        home: WorkoutSetupScreen(exerciseType: ExerciseType.shoulderPress),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final appBar = scaffold.appBar! as AppBar;

    expect(appBar.backgroundColor, isNotNull);
    expect(appBar.backgroundColor, isNot(Colors.transparent));
  });

  testWidgets('setup list bottom padding includes device safe area',
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
        home: MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.only(bottom: 34),
          ),
          child: WorkoutSetupScreen(exerciseType: ExerciseType.shoulderPress),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listView = tester.widget<ListView>(find.byType(ListView));
    final padding = listView.padding! as EdgeInsets;

    expect(padding.bottom, greaterThanOrEqualTo(62));
  });
}
