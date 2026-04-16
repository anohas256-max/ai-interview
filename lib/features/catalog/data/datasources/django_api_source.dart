import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/template_entity.dart';
import 'package:sobes/features/interview/domain/entities/session_config.dart';
import 'package:sobes/features/interview/domain/entities/message_entity.dart';
import 'package:sobes/features/history/domain/entities/session_history.dart';

class DjangoApiSource {
  late final Dio _dio;
  final String baseUrl = 'http://127.0.0.1:8000/api';
  final _storage = const FlutterSecureStorage();

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
          final token = await _getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            final refreshToken = prefs.getString('refresh_token');

            if (refreshToken != null) {
              try {
                final refreshDio = Dio(); 
                final response = await refreshDio.post(
                  'http://127.0.0.1:8000/api/auth/jwt/refresh/', 
                  data: {'refresh': refreshToken},
                );

                final newAccessToken = response.data['access'];
                await prefs.setString('access_token', newAccessToken);

                e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final cloneReq = await _dio.fetch(e.requestOptions);
                return handler.resolve(cloneReq);
              } catch (refreshError) {
                await prefs.remove('access_token');
                await prefs.remove('refresh_token');
                return handler.next(e);
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<List<TemplateEntity>> getTemplates(String language) async {
    try {
      final langCode = language == 'English' ? 'en' : 'ru';
      final response = await _dio.get('/templates/?lang=$langCode');
      final List<dynamic> results = response.data['results'] as List<dynamic>;
      return results.map((json) => TemplateEntity.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print("Ошибка загрузки шаблонов: $e");
      return [];
    }
  }

  Future<List<SessionHistory>> getSessionHistory() async {
    try {
      final response = await _dio.get('/history/');
      final List<dynamic> results = (response.data['results'] ?? response.data) as List<dynamic>;
      
      List<SessionHistory> validSessions = [];
      
      for (var json in results) {
        try {
          validSessions.add(SessionHistory.fromMap(json as Map<String, dynamic>));
        } catch (e) {
          print("Пропущена сломанная сессия: $e");
        }
      }
      
      return validSessions; 
    } catch (e) {
      print("Критическая ошибка загрузки истории: $e");
      return []; 
    }
  }

  Future<AiResponseData> getAiResponse({
    required String userMessage,
    required List<MessageEntity> history,
    required SessionConfig config,
    required String userLegend, 
    required List<String> askedQuestions,
    required int sessionId,
    bool isAnalysis = false,
    bool isLimitReached = false,
  }) async {
    try {
      final response = await _dio.post(
        '/chat/',
        data: {
          "sessionId": sessionId,
          "userMessage": userMessage,
          "history": history.map((m) => {"isUser": m.isUser, "text": m.text}).toList(),
          "config": config.toMap(),
          "userLegend": userLegend,
          "askedQuestions": askedQuestions,
          "isAnalysis": isAnalysis,
          "isLimitReached": isLimitReached,
        },
      );
      return AiResponseData.fromJson(response.data as Map<String, dynamic>);
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
      // ВАЖНО: Если ID существует - отправляем PATCH (Обновление)
      if (session.id != null && session.id.toString().isNotEmpty && session.id != 'null') {
        response = await _dio.patch('/history/${session.id}/', data: data);
      } else {
        response = await _dio.post('/history/', data: data);
      }
      return SessionHistory.fromMap(response.data as Map<String, dynamic>);
    } catch (e) {
      print("Ошибка сохранения истории: $e");
      return null;
    }
  }

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
        return {"success": false, "error": "Недостаточно монет ⚡️"};
      }
      return {"success": false, "error": "⚠️ Ошибка связи с сервером"};
    } catch (e) {
      return {"success": false, "error": "⚠️ Внутренняя ошибка"};
    }
  }

  // 👇 МЕТОДЫ ТЕПЕРЬ СТРОГО ВНУТРИ КЛАССА 👇
  Future<bool> deleteSessionHistory(dynamic sessionId) async {
    try {
      await _dio.delete('/history/$sessionId/');
      return true;
    } catch (e) {
      print("Ошибка удаления сессии $sessionId: $e");
      return false;
    }
  }

  Future<bool> clearAllHistory(List<dynamic> sessionIds) async {
    try {
      for (var id in sessionIds) {
        await _dio.delete('/history/$id/');
      }
      return true;
    } catch (e) {
      print("Ошибка очистки истории: $e");
      return false;
    }
  }
} // 👈 ЗДЕСЬ ЗАКАНЧИВАЕТСЯ DjangoApiSource

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