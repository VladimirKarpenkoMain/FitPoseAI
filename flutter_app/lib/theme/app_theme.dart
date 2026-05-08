import 'package:flutter/material.dart';

class AppTheme {
  static const Color _background = Color(0xFFF4F7FB);
  static const Color _surface = Colors.white;
  static const Color _surfaceTint = Color(0xFFF8FBFF);
  static const Color _primary = Color(0xFFFF7A00);
  static const Color _secondary = Color(0xFF12B3FF);
  static const Color _danger = Color(0xFFFF5A5F);
  static const Color _text = Color(0xFF18212F);
  static const Color _muted = Color(0xFF6C7788);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
      error: _danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme.copyWith(
        primary: _primary,
        secondary: _secondary,
        surface: _surface,
      ),
      scaffoldBackgroundColor: _background,
      cardTheme: const CardThemeData(
        color: _surface,
        surfaceTintColor: _surfaceTint,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: _text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: _text,
          height: 1.05,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: _text,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: _muted,
          height: 1.45,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD9E2EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD9E2EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}
