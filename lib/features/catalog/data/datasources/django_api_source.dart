import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 👈 Добавили
import 'package:flutter/foundation.dart' show kIsWeb; // 👈 Добавили
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/template_entity.dart';
import 'package:sobes/features/interview/domain/entities/session_config.dart';
import 'package:sobes/features/interview/domain/entities/message_entity.dart';
import 'package:sobes/features/history/domain/entities/session_history.dart';

class DjangoApiSource {
  late final Dio _dio;
  final String baseUrl = 'http://127.0.0.1:8000/api';
  final _storage = const FlutterSecureStorage(); // 👈 Добавили сейф

  // 👇 НОВЫЙ ПОМОЩНИК ДЛЯ ТОКЕНА 👇
  Future<String?> _getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } else {
      return await _storage.read(key: 'access_token');
    }
  }

  DjangoApiSource() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getAccessToken(); // 👈 ИСПОЛЬЗУЕМ ПРАВИЛЬНЫЙ МЕТОД
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // ... (Здесь оставляй свой старый код с проверкой 401 и refresh токеном)
          // (Главное было починить onRequest)
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString('refresh_token');

            if (refreshToken != null) {
              try {
                // Пытаемся получить новый access_token
                final refreshDio = Dio(); 
                final response = await refreshDio.post(
                  'http://127.0.0.1:8000/api/auth/jwt/refresh/', // Стандартный URL SimpleJWT
                  data: {'refresh': refreshToken},
                );

                final newAccessToken = response.data['access'];
                await prefs.setString('access_token', newAccessToken);

                // Повторяем упавший запрос уже с новым токеном!
                e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final cloneReq = await _dio.fetch(e.requestOptions);
                return handler.resolve(cloneReq);
              } catch (refreshError) {
                // Если и refresh_token протух (прошло много дней) - чистим память
                await prefs.remove('access_token');
                await prefs.remove('refresh_token');
                return handler.next(e);
              }
            }
          }
          return handler.next(e); // Если ошибка не 401, прокидываем дальше
        },
      ),
    );
  }

  // 👇 Теперь методы чистые, без ручного дергания _getToken() 👇

  Future<List<TemplateEntity>> getTemplates(String language) async {
    try {
      final langCode = language == 'English' ? 'en' : 'ru';
      final response = await _dio.get('/templates/?lang=$langCode');
      final List<dynamic> results = response.data['results'];
      return results.map((json) => TemplateEntity.fromJson(json)).toList();
    } catch (e) {
      print("Ошибка загрузки шаблонов из Django: $e");
      return [];
    }
  }

  Future<List<SessionHistory>> getSessionHistory() async {
    try {
      final response = await _dio.get('/session-history/');
      final List<dynamic> results = response.data['results'] ?? response.data;
      return results.map((json) => SessionHistory.fromMap(json)).toList();
    } catch (e) {
      print("Ошибка загрузки истории из Django: $e");
      return []; 
    }
  }

  Future<AiResponseData> getAiResponse({
    required String userMessage,
    required List<MessageEntity> history,
    required SessionConfig config,
    required String userLegend, 
    required List<String> askedQuestions,
    required int sessionId, // 👈 ДОБАВИЛИ ЭТО
    bool isAnalysis = false,
    bool isLimitReached = false, // 👈 ДОБАВИЛИ ФЛАГ ЛИМИТА
  }) async {
    try {
      final response = await _dio.post(
        '/chat/',
        data: {
          "sessionId": sessionId, // 👈 ОТПРАВЛЯЕМ НА СЕРВЕР
          "userMessage": userMessage,
          "history": history.map((m) => {"isUser": m.isUser, "text": m.text}).toList(),
          "config": config.toMap(),
          "userLegend": userLegend,
          "askedQuestions": askedQuestions,
          "isAnalysis": isAnalysis,
          "isLimitReached": isLimitReached, // 👈 ОТПРАВЛЯЕМ НА СЕРВЕР
        },
      );
      return AiResponseData.fromJson(response.data);
    } catch (e) {
      return AiResponseData(text: "⚠️ Ошибка связи с сервером.", inputTokens: 0, outputTokens: 0, cost: 0.0);
    }
  }

  Future<SessionHistory?> saveSessionHistory(SessionHistory session) async {
    try {
      final data = {
        "template_id": null, 
        "score": session.score,
        "is_finished": session.isFinished,
        "is_failed": session.isFailed,
        "full_data_json": session.toFullDataJson(),
      };

      Response response;
      if (session.id is int) {
        response = await _dio.patch('/session-history/${session.id}/', data: data);
      } else {
        response = await _dio.post('/session-history/', data: data);
      }
      return SessionHistory.fromMap(response.data);
    } catch (e) {
      print("Ошибка сохранения истории в Django: $e");
      return null;
    }
  }

  // 👇 НОВЫЙ МЕТОД ВСТАВЛЕН СЮДА (ВНУТРЬ КЛАССА) 👇
  Future<Map<String, dynamic>> startSession(SessionConfig config) async {
    try {
      final response = await _dio.post(
        '/start-session/',
        data: {
          "config": config.toMap(),
        },
      );
      return {
        "success": true,
        "session_id": response.data['session_id'],
        "new_balance": response.data['new_balance'],
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) {
        return {
          "success": false,
          "error": "Недостаточно монет ⚡️",
        };
      }
      return {"success": false, "error": "⚠️ Ошибка связи с сервером"};
    } catch (e) {
      return {"success": false, "error": "⚠️ Внутренняя ошибка"};
    }
  }
} // 👈 ВОТ ЗДЕСЬ ЗАКАНЧИВАЕТСЯ КЛАСС DjangoApiSource

// 👇 А ЭТОТ КЛАСС ОСТАЕТСЯ СНАРУЖИ 👇
class AiResponseData {
  final String text;
  final int inputTokens;
  final int outputTokens;
  final double cost;

  AiResponseData({required this.text, required this.inputTokens, required this.outputTokens, required this.cost});

  factory AiResponseData.fromJson(Map<String, dynamic> json) {
    return AiResponseData(
      text: json['text'] ?? '',
      inputTokens: json['inputTokens'] ?? 0,
      outputTokens: json['outputTokens'] ?? 0,
      cost: (json['cost'] ?? 0.0).toDouble(),
    );
  }
}