import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark; // По умолчанию темная
  String currentLanguage = "English";

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners(); // Сообщаем всему приложению: "Перекрашивайся!"
  }

  void setLanguage(String lang) {
    currentLanguage = lang;
    notifyListeners();
  }
}