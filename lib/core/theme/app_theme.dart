import 'package:flutter/material.dart';

class AppTheme {
  // Цвета
  static const Color scaffoldBackground = Color(0xFF080808); // Почти черный
  static const Color surface = Color(0xFF1A1A1A);           // Темно-серый для карточек
  static const Color border = Color(0xFF333333);            // Рамки
  static const Color textSecondary = Colors.grey;
  
  // Сама тема приложения
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: scaffoldBackground,
    primaryColor: Colors.white,
    useMaterial3: true,
    fontFamily: 'Inter', // Если шрифт не подключен, возьмет стандартный
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    // Стиль кнопок по умолчанию
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}