import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // 👈 Магия проверки платформы

class AuthApiSource {
  late final Dio _dio;
  final String baseUrl = 'http://127.0.0.1:8000/api';
  
  final _storage = const FlutterSecureStorage();

  AuthApiSource() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));

    // Наш умный охранник
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Охранник просит токен у умного помощника 👇
          final token = await _getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final isRefreshed = await _refreshToken();

            if (isRefreshed) {
              final newToken = await _getAccessToken();
              e.requestOptions.headers['Authorization'] = 'Bearer $newToken';

              try {
                final response = await Dio().fetch(e.requestOptions);
                return handler.resolve(response);
              } catch (e2) {
                return handler.next(e);
              }
            } else {
              await logout();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // =======================================================
  // 👇 УМНЫЕ ПОМОЩНИКИ ДЛЯ КРОССПЛАТФОРМЫ 👇
  // =======================================================

  Future<void> _saveTokens(String access, String refresh) async {
    if (kIsWeb) {
      // Если Веб — пишем в обычный блокнот
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', access);
      await prefs.setString('refresh_token', refresh);
    } else {
      // Если Телефон — прячем в сейф
      await _storage.write(key: 'access_token', value: access);
      await _storage.write(key: 'refresh_token', value: refresh);
    }
  }

  Future<String?> _getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } else {
      return await _storage.read(key: 'access_token');
    }
  }

  Future<String?> _getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refresh_token');
    } else {
      return await _storage.read(key: 'refresh_token');
    }
  }

  Future<void> _clearTokens() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    } else {
      await _storage.deleteAll();
    }
  }

  // =======================================================
  // 👆 КОНЕЦ ПОМОЩНИКОВ 👆
  // =======================================================

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '$baseUrl/auth/jwt/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        // Обновляем только access токен
        if (kIsWeb) {
           final prefs = await SharedPreferences.getInstance();
           await prefs.setString('access_token', response.data['access']);
        } else {
           await _storage.write(key: 'access_token', value: response.data['access']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await Dio().post(
        '$baseUrl/auth/jwt/create/',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        await _saveTokens(response.data['access'], response.data['refresh']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String username, String password, String email) async {
    try {
      final response = await Dio().post(
        '$baseUrl/register/',
        data: {'username': username, 'password': password, 'email': email},
      );
      return response.statusCode == 201; 
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkUsername(String username) async {
    try {
      final response = await _dio.get('/check-username/', queryParameters: {'username': username});
      return response.data['is_taken'] ?? false;
    } catch (e) { return false; }
  }

  Future<bool> checkEmail(String email) async {
    try {
      final response = await _dio.get('/check-email/', queryParameters: {'email': email});
      return response.data['is_taken'] ?? false;
    } catch (e) { return false; }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me/');
      if (response.statusCode == 200) return response.data; 
      return null;
    } catch (e) { return null; }
  }

  Future<bool> updateFirstName(String newName) async {
    try {
      final response = await _dio.patch(
        '/users/me/',
        data: {'first_name': newName},
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.post(
        '/change-password/',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) return null; 
      return 'error';
    } catch (e) {
      // 👇 ДОБАВИЛИ ЗАЩИТУ "e.response?.data is Map" 👇
      if (e is DioException && e.response?.statusCode == 400) {
        if (e.response?.data is Map && e.response?.data['error'] == 'current_password_incorrect') {
          return 'incorrect';
        }
      }
      return 'unknown';
    }
  }

  Future<void> logout() async {
    await _clearTokens(); 
  }

  Future<String?> getToken() async {
    return await _getAccessToken();
  }
}