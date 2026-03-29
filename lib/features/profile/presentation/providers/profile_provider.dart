import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  // Теперь здесь хранится только локальная инфа для ИИ
  String userBio = "I am a Junior developer preparing for technical interviews. Please ask me questions about algorithms and clean code.";

  ProfileProvider() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userBio = prefs.getString('profile_bio') ?? userBio;
    notifyListeners(); 
  }

  Future<void> updateBio(String newBio) async {
    userBio = newBio;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_bio', newBio);
  }
}