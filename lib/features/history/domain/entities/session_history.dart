import 'dart:convert';
import 'package:sobes/features/interview/domain/entities/session_config.dart';
import 'package:sobes/features/interview/domain/entities/message_entity.dart';
import 'package:sobes/features/interview/domain/entities/analysis_result.dart';

class SessionHistory {
  final dynamic id; 
  final DateTime date; // Это теперь дата ПОСЛЕДНЕЙ АКТИВНОСТИ
  final SessionConfig config;
  final List<MessageEntity> messages;
  final bool isFinished;
  final bool isFailed;
  final AnalysisResult? analysisResult;
  final String? customName; 

  SessionHistory({
    required this.id,
    required this.date,
    required this.config,
    required this.messages,
    required this.isFinished,
    required this.isFailed,
    this.analysisResult,
    this.customName,
  });

  String get title => customName != null && customName!.isNotEmpty ? customName! : config.role;
  String get subtitle => config.isRoleplayMode ? config.persona : "Технический опрос";
  double get score => analysisResult?.score ?? 0.0;
  bool get hasAnalysis => analysisResult != null;

  // 👇 ВОЗВРАЩАЕМ ТВОЙ ОРИГИНАЛЬНЫЙ НАДЕЖНЫЙ МЕТОД СОХРАНЕНИЯ 👇
  Map<String, dynamic> toFullDataJson() {
    return {
      'config': config.toMap(),
      'messages': messages.map((m) => m.toMap()).toList(),
      'custom_name': customName,
      'analysisResult': analysisResult != null ? {
          'score': analysisResult!.score,
          'performance_text': analysisResult!.performanceText,
          'strengths': analysisResult!.strengths,
          'weaknesses': analysisResult!.weaknesses,
          'smart_recap': analysisResult!.smartRecap.map((r) => {
            'topic': r.topic,
            'explanation': r.explanation,
            'recommendation': r.recommendation,
          }).toList(),
      } : null,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.toString(),
      'date': date.toIso8601String(),
      'full_data_json': toFullDataJson(), 
      'isFinished': isFinished,
      'isFailed': isFailed,
    };
  }

  factory SessionHistory.fromMap(Map<String, dynamic> map) {
    // УЛЬТРА-БЕЗОПАСНЫЙ ПАРСИНГ
    Map<String, dynamic> fullData = {};
    try {
      if (map['full_data_json'] is String) {
        fullData = jsonDecode(map['full_data_json']);
      } else if (map['full_data_json'] is Map) {
        fullData = map['full_data_json'] as Map<String, dynamic>;
      } else {
        fullData = map;
      }
    } catch (_) {}

    final configMap = fullData['config'] is Map ? fullData['config'] as Map<String, dynamic> : <String, dynamic>{};
    
    // БЕЗОПАСНЫЙ ПАРСИНГ СООБЩЕНИЙ
    List<MessageEntity> parsedMessages = [];
    if (fullData['messages'] is List) {
      for (var m in fullData['messages']) {
        try {
          parsedMessages.add(MessageEntity.fromMap(m is String ? jsonDecode(m) : m as Map<String, dynamic>));
        } catch (e) {
          print("Ошибка парсинга одного сообщения: $e");
        }
      }
    }

    final analysisMap = fullData['analysis'] ?? fullData['analysisResult'];
    AnalysisResult? parsedAnalysis;
    if (analysisMap is Map<String, dynamic>) {
      try {
        parsedAnalysis = AnalysisResult.fromJson(analysisMap);
      } catch (_) {}
    }

    SessionConfig parsedConfig;
    try {
      parsedConfig = SessionConfig.fromMap(configMap);
    } catch (e) {
      parsedConfig = SessionConfig(role: "Неизвестная роль", language: "Русский", difficulty: "Легкий", isRoleplayMode: false, persona: "", feedbackStyle: "", includeLegend: false, questionLimit: 5);
    }

    // 👇 БЕРЕМ ДАТУ ПОСЛЕДНЕГО ОБНОВЛЕНИЯ (ДЛЯ СОРТИРОВКИ АКТИВНЫХ ЧАТОВ ВВЕРХ) 👇
    DateTime parsedDate = DateTime.now();
    try {
      if (map['updated_at'] != null) {
        parsedDate = DateTime.parse(map['updated_at'].toString());
      } else if (map['created_at'] != null) {
        parsedDate = DateTime.parse(map['created_at'].toString());
      } else if (map['date'] != null) {
        parsedDate = DateTime.parse(map['date'].toString());
      }
    } catch (_) {}

    return SessionHistory(
      id: map['id'] ?? '',
      date: parsedDate,
      config: parsedConfig,
      messages: parsedMessages, 
      isFinished: map['is_finished'] == true || map['isFinished'] == true,
      isFailed: map['is_failed'] == true || map['isFailed'] == true,
      analysisResult: parsedAnalysis,
      customName: fullData['custom_name']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());
  factory SessionHistory.fromJson(String source) => SessionHistory.fromMap(json.decode(source));

  SessionHistory copyWith({String? customName, DateTime? updatedDate}) {
    return SessionHistory(
      id: id, 
      date: updatedDate ?? date, 
      config: config, 
      messages: messages,
      isFinished: isFinished, 
      isFailed: isFailed, 
      analysisResult: analysisResult,
      customName: customName ?? this.customName,
    );
  }
}