import 'package:fitness_ai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app theme uses light sport-tech defaults', () {
    final theme = AppTheme.light();

    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF4F7FB));
    expect(theme.colorScheme.primary, const Color(0xFFFF7A00));
    expect(theme.colorScheme.secondary, const Color(0xFF12B3FF));
    expect(theme.cardTheme.color, Colors.white);
    expect(theme.useMaterial3, isTrue);
  });
}
