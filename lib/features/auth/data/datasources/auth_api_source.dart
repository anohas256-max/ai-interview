import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiSource {
  final Dio _dio = Dio();
  
  final String baseUrl = 'http://127.0.0.1:8000/api';

  // --- ЛОГИН ---
  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/jwt/create/',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', response.data['access']);
        await prefs.setString('refresh_token', response.data['refresh']);
        return true;
      }
      return false;
    } catch (e) {
      print("Ошибка авторизации: $e");
      return false;
    }
  }

  // --- РЕГИСТРАЦИЯ (НОВЫЙ МЕТОД) ---
  Future<bool> register(String username, String password, String email) async {
    try {
      final response = await _dio.post(
        '$baseUrl/register/',
        data: {
          'username': username,
          'password': password,
          'email': email,
        },
      );
      // HTTP 201 означает "Успешно создано"
      return response.statusCode == 201; 
    } catch (e) {
      print("Ошибка регистрации: $e");
      return false;
    }
  }

  // --- ВЫХОД ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // --- ПРОВЕРКА ТОКЕНА ---
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}