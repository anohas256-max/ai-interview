import 'dart:convert';
import 'package:sobes/features/interview/domain/entities/session_config.dart';
import 'package:sobes/features/interview/domain/entities/message_entity.dart';
import 'package:sobes/features/interview/domain/entities/analysis_result.dart';

class SessionHistory {
  final String id;
  final DateTime date;
  
  // 1. Настройки, с которыми стартовали
  final SessionConfig config;
  
  // 2. Вся переписка
  final List<MessageEntity> messages;
  
  // 3. Статусы завершения
  final bool isFinished;
  final bool isFailed;
  
  // 4. Результаты анализа
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'config': config.toMap(),
      'messages': messages.map((m) => m.toMap()).toList(),
      'isFinished': isFinished,
      'isFailed': isFailed,
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

  factory SessionHistory.fromMap(Map<String, dynamic> map) {
    return SessionHistory(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date']),
      config: SessionConfig.fromMap(map['config']),
      messages: List<MessageEntity>.from(map['messages']?.map((x) => MessageEntity.fromMap(x)) ?? []),
      isFinished: map['isFinished'] ?? false,
      isFailed: map['isFailed'] ?? false,
      analysisResult: map['analysisResult'] != null ? AnalysisResult.fromJson(map['analysisResult']) : null,
    );
  }

  String toJson() => json.encode(toMap());
  factory SessionHistory.fromJson(String source) => SessionHistory.fromMap(json.decode(source));
}