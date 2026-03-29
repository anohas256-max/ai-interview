import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiSource {
  final Dio _dio = Dio();
  final String baseUrl = 'http://127.0.0.1:8000/api';

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post('$baseUrl/auth/jwt/create/', data: {'username': username, 'password': password});
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', response.data['access']);
        await prefs.setString('refresh_token', response.data['refresh']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String username, String password, String email) async {
    try {
      final response = await _dio.post('$baseUrl/register/', data: {'username': username, 'password': password, 'email': email});
      return response.statusCode == 201; 
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkUsername(String username) async {
    try {
      final response = await _dio.get('$baseUrl/check-username/', queryParameters: {'username': username});
      return response.data['is_taken'] ?? false;
    } catch (e) { return false; }
  }

  // 👇 НОВЫЙ МЕТОД ДЛЯ EMAIL 👇
  Future<bool> checkEmail(String email) async {
    try {
      final response = await _dio.get('$baseUrl/check-email/', queryParameters: {'email': email});
      return response.data['is_taken'] ?? false;
    } catch (e) { return false; }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      final response = await _dio.get('$baseUrl/users/me/', options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (response.statusCode == 200) return response.data; 
      return null;
    } catch (e) { return null; }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
}