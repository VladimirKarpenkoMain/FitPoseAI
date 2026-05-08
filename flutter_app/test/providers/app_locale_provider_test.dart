import 'package:fitness_ai/providers/app_locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to system locale when no override is stored', () async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        systemLocaleProvider.overrideWithValue(const Locale('ru', 'RU')),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appLanguageProvider), AppLanguageOption.system);
    expect(container.read(appLocaleOverrideProvider), isNull);
    expect(
      container.read(effectiveAppLocaleProvider),
      const Locale('ru', 'RU'),
    );
  });

  test('loads a persisted Russian override', () async {
    SharedPreferences.setMockInitialValues({
      appLocaleStorageKey: 'ru-RU',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        systemLocaleProvider.overrideWithValue(const Locale('en', 'US')),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appLanguageProvider), AppLanguageOption.russian);
    expect(
      container.read(appLocaleOverrideProvider),
      const Locale('ru', 'RU'),
    );
    expect(
      container.read(effectiveAppLocaleProvider),
      const Locale('ru', 'RU'),
    );
  });

  test('clears the stored override when switching back to system', () async {
    SharedPreferences.setMockInitialValues({
      appLocaleStorageKey: 'en-US',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        systemLocaleProvider.overrideWithValue(const Locale('ru', 'RU')),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(appLanguageProvider.notifier)
        .setOption(AppLanguageOption.system);

    expect(container.read(appLanguageProvider), AppLanguageOption.system);
    expect(container.read(appLocaleOverrideProvider), isNull);
    expect(prefs.getString(appLocaleStorageKey), isNull);
    expect(
      container.read(effectiveAppLocaleProvider),
      const Locale('ru', 'RU'),
    );
  });
}
