import 'dart:convert';
import 'package:sobes/features/interview/domain/entities/session_config.dart';
import 'package:sobes/features/interview/domain/entities/message_entity.dart';
import 'package:sobes/features/interview/domain/entities/analysis_result.dart';

class SessionHistory {
  // ID теперь может быть int (если пришел из базы Джанго) или String (если временный локальный)
  final dynamic id; 
  final DateTime date;
  final SessionConfig config;
  final List<MessageEntity> messages;
  final bool isFinished;
  final bool isFailed;
  final AnalysisResult? analysisResult;

  SessionHistory({
    required this.id,
    required this.date,
    required this.config,
    required this.messages,
    required this.isFinished,
    required this.isFailed,
    this.analysisResult,
  });

  String get title => config.role;
  String get subtitle => config.isRoleplayMode ? config.persona : "Технический опрос";
  double get score => analysisResult?.score ?? 0.0;
  bool get hasAnalysis => analysisResult != null;

  // Этот метод мы используем для отправки full_data_json в Django
  Map<String, dynamic> toFullDataJson() {
    return {
      'config': config.toMap(),
      'messages': messages.map((m) => m.toMap()).toList(),
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

  // А этот для локального кэша SharedPreferences (чтобы работало без интернета)
  Map<String, dynamic> toMap() {
    return {
      'id': id.toString(),
      'date': date.toIso8601String(),
      'full_data_json': toFullDataJson(), // 👈 Заворачиваем внутренности
      'isFinished': isFinished,
      'isFailed': isFailed,
    };
  }

  factory SessionHistory.fromMap(Map<String, dynamic> map) {
    // Джанго присылает данные внутри ключа 'full_data_json'
    final fullData = map['full_data_json'] ?? map; // Фолбэк для старых локальных сохранений

    return SessionHistory(
      id: map['id'] ?? '',
      date: map['created_at'] != null ? DateTime.parse(map['created_at']) : (map['date'] != null ? DateTime.parse(map['date']) : DateTime.now()),
      config: SessionConfig.fromMap(fullData['config'] ?? {}),
      messages: List<MessageEntity>.from(fullData['messages']?.map((x) => MessageEntity.fromMap(x)) ?? []),
      isFinished: map['is_finished'] ?? map['isFinished'] ?? false,
      isFailed: map['is_failed'] ?? map['isFailed'] ?? false,
      analysisResult: fullData['analysisResult'] != null ? AnalysisResult.fromJson(fullData['analysisResult']) : null,
    );
  }

  String toJson() => json.encode(toMap());
  factory SessionHistory.fromJson(String source) => SessionHistory.fromMap(json.decode(source));
}