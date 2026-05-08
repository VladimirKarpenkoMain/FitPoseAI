import 'package:fitness_ai/services/speech_text_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps Russian locale to Android Google TTS code', () {
    expect(ttsLanguageCodeForLocale(const Locale('ru', 'RU')), 'ru-RU');
  });

  test('maps unsupported locale to English TTS code', () {
    expect(ttsLanguageCodeForLocale(const Locale('de', 'DE')), 'en-US');
  });

  test('formats rep counts in English when the language code is English', () {
    expect(repCountSpeechText(5, 'en-US'), 'Five');
  });

  test('formats rep counts in Russian when the language code is Russian', () {
    expect(repCountSpeechText(5, 'ru-RU'), 'Пять');
  });
}
