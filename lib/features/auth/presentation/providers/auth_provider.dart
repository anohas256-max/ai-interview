import 'package:flutter/material.dart';
import '../../data/datasources/auth_api_source.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiSource _apiSource = AuthApiSource();

  bool isAuthenticated = false; 
  bool isLoading = false;       
  String? errorMessage;         

  String? currentUsername;
  String? currentEmail;
  String? currentFirstName; // 👈 Добавили переменную для Имени

  AuthProvider() { checkAuth(); }

  Future<void> checkAuth() async {
    final token = await _apiSource.getToken();
    if (token != null) {
      isAuthenticated = true;
      await fetchCurrentUser(); 
    } else {
      isAuthenticated = false;
    }
    notifyListeners();
  }

  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    return await _apiSource.checkUsername(username);
  }

  Future<bool> isEmailTaken(String email) async {
    return await _apiSource.checkEmail(email);
  }

  // 👇 ОБНОВЛЕНО: Теперь забираем с сервера еще и first_name
  Future<void> fetchCurrentUser() async {
    final userData = await _apiSource.getCurrentUser();
    if (userData != null) {
      currentUsername = userData['username'];
      currentEmail = userData['email'];
      currentFirstName = userData['first_name']; 
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final success = await _apiSource.login(username, password);

    if (success) {
      isAuthenticated = true;
      await fetchCurrentUser(); 
    } else {
      errorMessage = "Неверный логин или пароль 😔";
    }

    isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register(String username, String password, String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final success = await _apiSource.register(username, password, email);

    if (!success) {
      errorMessage = "Ошибка при создании аккаунта.";
    }

    isLoading = false;
    notifyListeners();
    return success;
  }

  // 👇 НОВАЯ ФУНКЦИЯ: Сохраняем новое имя на сервер
  Future<bool> updateName(String newName) async {
    isLoading = true;
    notifyListeners();

    final success = await _apiSource.updateFirstName(newName);
    if (success) {
      currentFirstName = newName; // Меняем имя локально
      errorMessage = null;
    } else {
      errorMessage = "Ошибка при обновлении имени";
    }

    isLoading = false;
    notifyListeners();
    return success;
  }

  // 👇 ОБНОВЛЕНО: Стираем first_name при выходе
  Future<void> logout() async {
    await _apiSource.logout();
    isAuthenticated = false;
    currentUsername = null;
    currentEmail = null;
    currentFirstName = null; 
    notifyListeners();
  }
}