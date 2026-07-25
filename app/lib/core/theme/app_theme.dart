import 'package:flutter/material.dart';

/// Tema Material 3 de FinTrack: mismo seed color para claro y oscuro,
/// alternando según el tema del sistema (ver [ThemeMode.system] en main.dart).
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
