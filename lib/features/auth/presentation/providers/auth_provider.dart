import 'dart:async'; // 👈 Добавили для таймера
import 'package:flutter/material.dart';
import '../../data/datasources/auth_api_source.dart';
// 👇 Импортируем DjangoApiSource для доступа к новым методам
import '../../../catalog/data/datasources/django_api_source.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiSource _apiSource = AuthApiSource();
  final DjangoApiSource _djangoApiSource = DjangoApiSource(); // 👈 Добавили

  bool isAuthenticated = false; 
  bool isLoading = false;       
  String? errorMessage;         

  String? currentUsername;
  String? currentEmail;
  String? currentFirstName; 
  double coinsBalance = 0.0;

  int passwordAttempts = 0;

  // ==========================================
  // 👇 ЛОГИКА ТАЙМЕРА И ЭНЕРГИИ 👇
  // ==========================================
  int _secondsUntilReward = 0;
  Timer? _rewardTimer;

  int get secondsUntilReward => _secondsUntilReward;
  bool get isRewardReady => _secondsUntilReward <= 0;

  String get formattedRewardTime {
    if (_secondsUntilReward <= 0) return "Готово!";
    int h = _secondsUntilReward ~/ 3600;
    int m = (_secondsUntilReward % 3600) ~/ 60;
    int s = _secondsUntilReward % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> fetchDailyRewardInfo() async {
    final result = await _djangoApiSource.checkDailyReward();
    
    if (result.containsKey('balance')) {
      coinsBalance = (result['balance'] as num).toDouble();
    }

    if (result.containsKey('seconds_left')) {
      _secondsUntilReward = result['seconds_left'] as int;
      _startTimer();
    }
    notifyListeners();
  }

  Future<void> claimDailyReward() async {
    if (!isRewardReady) return; 
    await fetchDailyRewardInfo(); 
  }

  Future<void> buyEnergy(double amount) async {
    final result = await _djangoApiSource.addEnergy(amount);
    if (result['success'] == true && result.containsKey('balance')) {
      coinsBalance = (result['balance'] as num).toDouble();
      notifyListeners();
    }
  }

  void _startTimer() {
    _rewardTimer?.cancel(); 
    if (_secondsUntilReward > 0) {
      _rewardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsUntilReward > 0) {
          _secondsUntilReward--;
          notifyListeners();
        } else {
          timer.cancel();
          notifyListeners();
        }
      });
    }
  }

  @override
  void dispose() {
    _rewardTimer?.cancel(); 
    super.dispose();
  }
  // ==========================================

  AuthProvider() { checkAuth(); }

  Future<void> checkAuth() async {
    final token = await _apiSource.getToken();
    if (token != null) {
      isAuthenticated = true;
      await fetchCurrentUser(); 
      await fetchDailyRewardInfo(); // 👈 ЗАПУСКАЕМ ТАЙМЕР ПРИ УСПЕШНОМ ВХОДЕ
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
      await fetchDailyRewardInfo(); // 👈 ЗАПУСКАЕМ ТАЙМЕР ПОСЛЕ ЛОГИНА
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
    if (!success) errorMessage = "Ошибка при создании аккаунта.";

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

  Future<String?> changePassword(String old, String newP) async {
    if (passwordAttempts >= 5) return "Too many attempts. Try again later.";

    final result = await _apiSource.changePassword(old, newP);
    if (result == 'incorrect') {
      passwordAttempts++;
      return "Текущий пароль неверен";
    }
    if (result == null) passwordAttempts = 0; 
    return result;
  }

  Future<void> logout() async {
    await _apiSource.logout();
    isAuthenticated = false;
    currentUsername = null;
    currentEmail = null;
    currentFirstName = null; 
    _rewardTimer?.cancel(); // 👈 УБИВАЕМ ТАЙМЕР ПРИ ВЫХОДЕ ИЗ АККАУНТА
    notifyListeners();
  }

  void updateBalance(double newBalance) {
    coinsBalance = newBalance;
    notifyListeners();
  }
}