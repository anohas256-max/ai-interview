import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  // Эти данные ИИ будет забирать для генерации диалога
  String userName = "John Doe";
  String userBio = "Male, 25, Junior level Developer looking for mid-level roles. Background in Computer Science.";

  // Функции для обновления (пригодятся позже для БД)
  void updateName(String newName) {
    userName = newName;
    notifyListeners();
  }

  void updateBio(String newBio) {
    userBio = newBio;
    notifyListeners();
  }
}