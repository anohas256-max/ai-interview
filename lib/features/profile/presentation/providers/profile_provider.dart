import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  // Дефолтные данные на случай самого первого запуска
  String userName = "John Doe";
  String userBio = "Male, 25, Junior level Developer looking for mid-level roles. Background in Computer Science.";

  // При создании пульта сразу достаем данные из памяти
  ProfileProvider() {
    _loadProfile();
  }

  // --- ЗАГРУЗКА ИЗ ПАМЯТИ ---
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Пытаемся прочитать. Если там пусто (null), оставляем старое значение
    userName = prefs.getString('profile_name') ?? userName;
    userBio = prefs.getString('profile_bio') ?? userBio;
    
    notifyListeners(); // Говорим экранам обновиться
  }

  // --- СОХРАНЕНИЕ ИМЕНИ ---
  Future<void> updateName(String newName) async {
    userName = newName;
    notifyListeners();
    
    // Тихо записываем в память телефона
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', newName);
  }

  // --- СОХРАНЕНИЕ БИО ---
  Future<void> updateBio(String newBio) async {
    userBio = newBio;
    notifyListeners();
    
    // Тихо записываем в память телефона
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_bio', newBio);
  }
}