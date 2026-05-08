import 'package:fitness_ai/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app localizations return Russian copy for Russian locale', () {
    final l10n = AppLocalizations(const Locale('ru'));

    expect(l10n.login, 'Войти');
    expect(l10n.register, 'Регистрация');
    expect(l10n.startNow, 'Начать сейчас');
    expect(l10n.historyTitle, 'История тренировок');
  });

  test('app localizations fall back to English for unsupported locales', () {
    final l10n = AppLocalizations(const Locale('es'));

    expect(l10n.login, 'Login');
    expect(l10n.register, 'Register');
    expect(l10n.startNow, 'Start now');
    expect(l10n.historyTitle, 'Workout history');
  });
}
