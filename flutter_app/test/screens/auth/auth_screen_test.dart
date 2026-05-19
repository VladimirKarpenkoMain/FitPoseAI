import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/providers/auth_provider.dart';
import 'package:fitness_ai/screens/auth_screen.dart';
import 'package:fitness_ai/services/api_service.dart';
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

    await tester.pumpAndSettle();
    final registerModeButton = find.widgetWithText(TextButton, 'Register');
    await tester.ensureVisible(registerModeButton);
    await tester.tap(registerModeButton);
    await tester.pumpAndSettle();

    expect(find.text('Train smarter'), findsOneWidget);
    expect(
      find.text('Create an account and track your progress'),
      findsOneWidget,
    );
    expect(find.text('Register'), findsWidgets);
  });

  testWidgets('auth screen shows login progress while submitting', (
    tester,
  ) async {
    final authNotifier = _ControlledAuthNotifier();

    await tester.pumpWidget(
      _AuthTestApp(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Signing in...'), findsOneWidget);
  });

  testWidgets('auth screen shows registration progress and success notice', (
    tester,
  ) async {
    final authNotifier = _ControlledAuthNotifier();

    await tester.pumpWidget(
      _AuthTestApp(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final registerModeButton = find.widgetWithText(TextButton, 'Register');
    await tester.ensureVisible(registerModeButton);
    await tester.tap(registerModeButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    final registerButton = find.widgetWithText(ElevatedButton, 'Register');
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Registering...'), findsOneWidget);

    authNotifier.completeRegister();
    await tester.pump();

    expect(find.text('Account created'), findsOneWidget);
  });
}

class _AuthTestApp extends StatelessWidget {
  const _AuthTestApp({required this.overrides});

  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
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
    );
  }
}

class _ControlledAuthNotifier extends AuthNotifier {
  _ControlledAuthNotifier() : super(_FakeApiService()) {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
  }

  @override
  Future<void> register(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
  }

  void completeRegister() {
    state = const AuthState(status: AuthStatus.authenticated);
  }
}

class _FakeApiService extends ApiService {}
