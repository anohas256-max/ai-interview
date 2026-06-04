import 'package:flutter/material.dart';

class AppTheme {
  // ===== DARK THEME =====
  static const Color darkScaffoldBackground = Color(0xFF080808);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF333333);

  // ===== LIGHT THEME =====
  static const Color lightScaffoldBackground = Color(0xFFFAF8FC);
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0xFFE8E3EA);

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: 'Inter',

    scaffoldBackgroundColor: lightScaffoldBackground,
    cardColor: lightSurface,
    canvasColor: lightScaffoldBackground,
    primaryColor: Colors.black,

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.light,
      surface: lightSurface,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: lightSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: lightBorder,
          width: 1,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF25242A),
          displayColor: const Color(0xFF25242A),
        ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkScaffoldBackground,
    primaryColor: Colors.white,
    useMaterial3: true,
    fontFamily: 'Inter',

    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.dark,
      surface: darkSurface,
    ),

    cardColor: darkSurface,
    canvasColor: darkScaffoldBackground,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}