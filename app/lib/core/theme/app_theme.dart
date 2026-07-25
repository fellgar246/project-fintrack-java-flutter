import 'package:flutter/material.dart';

/// FinTrack's Material 3 theme: same seed color for light and dark,
/// switching based on the system theme (see [ThemeMode.system] in main.dart).
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF2E7D32);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      );
}
