import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:fitness_ai/providers/app_locale_provider.dart';
import 'package:fitness_ai/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows system default as the initial language option', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          systemLocaleProvider.overrideWithValue(const Locale('en', 'US')),
        ],
        child: const _SettingsTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.byType(RadioListTile<AppLanguageOption>), findsNWidgets(3));
  });

  testWidgets('selecting Russian stores the override and updates locale', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          systemLocaleProvider.overrideWithValue(const Locale('en', 'US')),
        ],
        child: const _SettingsTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('app-language-russian')));
    await tester.pumpAndSettle();

    expect(prefs.getString(appLocaleStorageKey), 'ru-RU');
    expect(find.text('Настройки'), findsOneWidget);
  });
}

class _SettingsTestApp extends ConsumerWidget {
  const _SettingsTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      locale: ref.watch(appLocaleOverrideProvider),
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SettingsScreen(),
    );
  }
}
