import 'package:flutter/material.dart';
import '../../data/datasources/auth_api_source.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiSource _apiSource = AuthApiSource();

  bool isAuthenticated = false; 
  bool isLoading = false;       
  String? errorMessage;         

  AuthProvider() {
    checkAuth(); 
  }

  Future<void> checkAuth() async {
    final token = await _apiSource.getToken();
    isAuthenticated = token != null;
    notifyListeners();
  }

  // --- ЛОГИН ---
  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final success = await _apiSource.login(username, password);

    if (success) {
      isAuthenticated = true;
    } else {
      errorMessage = "Неверный логин или пароль 😔";
    }

    isLoading = false;
    notifyListeners();
    return success;
  }

  // --- РЕГИСТРАЦИЯ (НОВЫЙ МЕТОД) ---
  Future<bool> register(String username, String password, String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final success = await _apiSource.register(username, password, email);

    if (!success) {
      errorMessage = "Ошибка при создании аккаунта. Возможно, имя уже занято.";
    }

    isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _apiSource.logout();
    isAuthenticated = false;
    notifyListeners();
  }
}