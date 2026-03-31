import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthApiSource {
  late final Dio _dio;
  final String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Создаем экземпляр защищенного сейфа
  final _storage = const FlutterSecureStorage();

  AuthApiSource() {
    // Настраиваем базовый URL, чтобы не писать его каждый раз
    _dio = Dio(BaseOptions(baseUrl: baseUrl));

    // 👇 НАШ УМНЫЙ ОХРАННИК 👇
    _dio.interceptors.add(
      InterceptorsWrapper(
        // 1. ПЕРЕД КАЖДЫМ ЗАПРОСОМ: Достаем токен из сейфа и приклеиваем
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        // 2. ПРИ ОШИБКЕ: Ловим 401 (протухший токен) и обновляем его
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final isRefreshed = await _refreshToken();

            if (isRefreshed) {
              // Если успешно обновили — берем новый токен и ПОВТОРЯЕМ запрос
              final newToken = await _storage.read(key: 'access_token');
              e.requestOptions.headers['Authorization'] = 'Bearer $newToken';

              try {
                final response = await Dio().fetch(e.requestOptions);
                return handler.resolve(response);
              } catch (e2) {
                return handler.next(e);
              }
            } else {
              // Если refresh_token тоже умер — выкидываем из аккаунта
              await logout();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // --- СКРЫТЫЙ МЕТОД ДЛЯ ОБНОВЛЕНИЯ ТОКЕНА ---
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      // Используем новый чистый Dio, чтобы охранник не зациклил сам себя
      final response = await Dio().post(
        '$baseUrl/auth/jwt/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        await _storage.write(key: 'access_token', value: response.data['access']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- ЛОГИН ---
  Future<bool> login(String username, String password) async {
    try {
      // Используем чистый Dio для логина (нам тут не нужен токен в заголовках)
      final response = await Dio().post(
        '$baseUrl/auth/jwt/create/',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        // Кладем токены в защищенный сейф
        await _storage.write(key: 'access_token', value: response.data['access']);
        await _storage.write(key: 'refresh_token', value: response.data['refresh']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- РЕГИСТРАЦИЯ ---
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

  // --- ПРОВЕРКИ ---
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

  // --- ПРОФИЛЬ ---
  // Токены подставляются автоматически!
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

  // --- ВЫХОД ---
  Future<void> logout() async {
    await _storage.deleteAll(); // Уничтожаем всё в сейфе
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
}