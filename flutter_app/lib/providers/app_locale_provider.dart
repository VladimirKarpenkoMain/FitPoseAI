import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appLocaleStorageKey = 'app_locale_override';

const supportedAppLocales = <Locale>[
  Locale('ru', 'RU'),
  Locale('en', 'US'),
];

enum AppLanguageOption {
  system,
  english,
  russian,
}

extension AppLanguageOptionX on AppLanguageOption {
  String? get storageValue {
    switch (this) {
      case AppLanguageOption.system:
        return null;
      case AppLanguageOption.english:
        return 'en-US';
      case AppLanguageOption.russian:
        return 'ru-RU';
    }
  }

  Locale? get localeOverride {
    switch (this) {
      case AppLanguageOption.system:
        return null;
      case AppLanguageOption.english:
        return const Locale('en', 'US');
      case AppLanguageOption.russian:
        return const Locale('ru', 'RU');
    }
  }

  static AppLanguageOption fromStorage(String? value) {
    switch (value) {
      case 'en-US':
        return AppLanguageOption.english;
      case 'ru-RU':
        return AppLanguageOption.russian;
      default:
        return AppLanguageOption.system;
    }
  }
}

Locale normalizeSupportedLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'ru':
      return const Locale('ru', 'RU');
    case 'en':
      return const Locale('en', 'US');
    default:
      return const Locale('en', 'US');
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Override sharedPreferencesProvider in main() and tests.',
  );
});

final systemLocaleProvider = Provider<Locale>((ref) {
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  return normalizeSupportedLocale(locale);
});

class AppLanguageNotifier extends Notifier<AppLanguageOption> {
  @override
  AppLanguageOption build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return AppLanguageOptionX.fromStorage(
      prefs.getString(appLocaleStorageKey),
    );
  }

  Future<void> setOption(AppLanguageOption option) async {
    state = option;
    final prefs = ref.read(sharedPreferencesProvider);
    final value = option.storageValue;

    if (value == null) {
      await prefs.remove(appLocaleStorageKey);
      return;
    }

    await prefs.setString(appLocaleStorageKey, value);
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageNotifier, AppLanguageOption>(
  AppLanguageNotifier.new,
);

final appLocaleOverrideProvider = Provider<Locale?>((ref) {
  return ref.watch(appLanguageProvider).localeOverride;
});

final effectiveAppLocaleProvider = Provider<Locale>((ref) {
  final override = ref.watch(appLocaleOverrideProvider);
  final systemLocale = ref.watch(systemLocaleProvider);
  return override ?? systemLocale;
});
