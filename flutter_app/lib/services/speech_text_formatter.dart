import 'package:flutter/material.dart';

String ttsLanguageCodeForLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'ru':
      return 'ru-RU';
    case 'en':
      return 'en-US';
    default:
      return 'en-US';
  }
}

String repCountSpeechText(int count, String languageCode) {
  if (languageCode.startsWith('ru')) {
    return _numberToRussianWords(count);
  }
  return _numberToEnglishWords(count);
}

String _numberToEnglishWords(int number) {
  if (number <= 0) {
    return 'Zero';
  }
  if (number > 100) {
    return number.toString();
  }

  const ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  const tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  if (number < 20) {
    return ones[number];
  }
  if (number < 100) {
    final ten = number ~/ 10;
    final one = number % 10;
    return '${tens[ten]}${one > 0 ? ' ${ones[one]}' : ''}';
  }

  return 'One Hundred';
}

String _numberToRussianWords(int number) {
  if (number <= 0) {
    return 'Ноль';
  }
  if (number > 100) {
    return number.toString();
  }

  const ones = [
    '',
    'Один',
    'Два',
    'Три',
    'Четыре',
    'Пять',
    'Шесть',
    'Семь',
    'Восемь',
    'Девять',
    'Десять',
    'Одиннадцать',
    'Двенадцать',
    'Тринадцать',
    'Четырнадцать',
    'Пятнадцать',
    'Шестнадцать',
    'Семнадцать',
    'Восемнадцать',
    'Девятнадцать',
  ];

  const tens = [
    '',
    '',
    'Двадцать',
    'Тридцать',
    'Сорок',
    'Пятьдесят',
    'Шестьдесят',
    'Семьдесят',
    'Восемьдесят',
    'Девяносто',
  ];

  if (number < 20) {
    return ones[number];
  }
  if (number < 100) {
    final ten = number ~/ 10;
    final one = number % 10;
    return '${tens[ten]}${one > 0 ? ' ${ones[one]}' : ''}';
  }

  return 'Сто';
}
