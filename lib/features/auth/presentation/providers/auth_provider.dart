import 'package:flutter/material.dart';
import '../../data/datasources/auth_api_source.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiSource _apiSource = AuthApiSource();

  bool isAuthenticated = false; 
  bool isLoading = false;       
  String? errorMessage;         

  String? currentUsername;
  String? currentEmail;
  String? currentFirstName; 
  double coinsBalance = 0.0;

  int passwordAttempts = 0; // 👈 Внутри класса!

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

  Future<void> fetchCurrentUser() async {
    final userData = await _apiSource.getCurrentUser();
    if (userData != null) {
      currentUsername = userData['username'];
      currentEmail = userData['email'];
      currentFirstName = userData['first_name']; 
      // 👇 Парсим баланс монет (если его нет в ответе, ставим 0)
      coinsBalance = (userData['coins_balance'] ?? 0).toDouble();
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

  Future<bool> updateName(String newName) async {
    isLoading = true;
    notifyListeners();

    final success = await _apiSource.updateFirstName(newName);
    if (success) {
      currentFirstName = newName; 
      errorMessage = null;
    } else {
      errorMessage = "Ошибка при обновлении имени";
    }

    isLoading = false;
    notifyListeners();
    return success;
  }

  // 👇 ВНУТРИ КЛАССА 👇
  Future<String?> changePassword(String old, String newP) async {
    if (passwordAttempts >= 5) {
      return "Too many attempts. Try again later.";
    }

    final result = await _apiSource.changePassword(old, newP);
    
    if (result == 'incorrect') {
      passwordAttempts++;
      return "Текущий пароль неверен";
    }
    
    if (result == null) {
      passwordAttempts = 0; 
    }
    
    return result;
  }

  Future<void> logout() async {
    await _apiSource.logout();
    isAuthenticated = false;
    currentUsername = null;
    currentEmail = null;
    currentFirstName = null; 
    notifyListeners();
  }

void updateBalance(double newBalance) { // 👈 СТАЛО double
    coinsBalance = newBalance;
    notifyListeners();
  }

} 