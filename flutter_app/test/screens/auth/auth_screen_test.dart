import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('auth screen renders redesigned Russian login shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ru', 'RU'),
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
          home: AuthScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Тренируйся умнее'), findsOneWidget);
    expect(find.text('Войти'), findsWidgets);
    expect(find.text('Живые AI-подсказки'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('auth screen toggles into English registration mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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
          home: AuthScreen(),
        ),
      ),
    );

    await tester.tap(find.text('Register').last);
    await tester.pumpAndSettle();

    expect(find.text('Train smarter'), findsOneWidget);
    expect(
      find.text('Create an account and track your progress'),
      findsOneWidget,
    );
    expect(find.text('Register'), findsWidgets);
  });
}
