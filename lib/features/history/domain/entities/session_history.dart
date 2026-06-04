import 'dart:convert';

import 'package:sobes/features/interview/domain/entities/session_config.dart';
import 'package:sobes/features/interview/domain/entities/message_entity.dart';
import 'package:sobes/features/interview/domain/entities/analysis_result.dart';

class SessionHistory {
  final dynamic id;
  final DateTime date;
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

  String get title {
    if (customName != null && customName!.trim().isNotEmpty) {
      return customName!;
    }

    final rawTitle = config.role.trim();

    if (rawTitle.isEmpty ||
        rawTitle.toLowerCase() == 'custom_opt' ||
        rawTitle == 'Свой вариант' ||
        rawTitle == 'Custom') {
      return config.isRoleplayMode ? 'Кастомное собеседование' : 'Кастомный квиз';
    }

    return rawTitle;
  }

  String get subtitle => config.isRoleplayMode ? config.persona : 'Технический опрос';

  double get score => analysisResult?.score ?? 0.0;

  bool get hasAnalysis => analysisResult != null;

  Map<String, dynamic> toFullDataJson() {
    return {
      'config': config.toMap(),
      'messages': messages.map((m) => m.toMap()).toList(),
      'custom_name': customName,
      'analysisResult': analysisResult != null
          ? {
              'score': analysisResult!.score,
              'performance_text': analysisResult!.performanceText,
              'strengths': analysisResult!.strengths,
              'weaknesses': analysisResult!.weaknesses,
              'smart_recap': analysisResult!.smartRecap
                  .map(
                    (r) => {
                      'topic': r.topic,
                      'explanation': r.explanation,
                      'recommendation': r.recommendation,
                    },
                  )
                  .toList(),
            }
          : null,
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

  factory SessionHistory.fromMap(Map map) {
    final fullData = _extractFullData(map);

    final configMap = _extractConfigMap(fullData, map);

    final parsedMessages = <MessageEntity>[];
    final rawMessages = fullData['messages'];

    if (rawMessages is List) {
      for (final m in rawMessages) {
        try {
          if (m is String) {
            parsedMessages.add(MessageEntity.fromMap(jsonDecode(m)));
          } else if (m is Map) {
            parsedMessages.add(
              MessageEntity.fromMap(Map<String, dynamic>.from(m)),
            );
          }
        } catch (e) {
          // ignore broken message
        }
      }
    }

    final analysisMap = fullData['analysis'] ?? fullData['analysisResult'];

    AnalysisResult? parsedAnalysis;
    if (analysisMap is Map) {
  try {
    parsedAnalysis = AnalysisResult.fromJson(
      Map<String, dynamic>.from(analysisMap),
    );
  } catch (_) {}
}

    final parsedConfig = _safeParseConfig(configMap, fullData, map);
    final parsedDate = _safeParseDate(map);

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

  static Map<String, dynamic> _extractFullData(Map map) {
    try {
      final raw = map['full_data_json'];

      if (raw is String && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }

      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } catch (_) {}

    return Map<String, dynamic>.from(map);
  }

  static Map<String, dynamic> _extractConfigMap(
    Map<String, dynamic> fullData,
    Map sourceMap,
  ) {
    final rawConfig = fullData['config'];

    if (rawConfig is Map) {
      return Map<String, dynamic>.from(rawConfig);
    }

    if (rawConfig is String && rawConfig.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawConfig);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    final fallback = <String, dynamic>{};

    final template = sourceMap['template'];
    if (template is Map) {
      fallback['role'] =
          template['title'] ?? template['name'] ?? template['title_en'];
      fallback['persona'] = template['description'] ?? '';
      fallback['isRoleplayMode'] = template['mode'] != 'quiz';
    }

    fallback['role'] ??= fullData['role'] ??
        sourceMap['role'] ??
        fullData['custom_name'] ??
        'Без названия';

    fallback['persona'] ??= fullData['persona'] ?? '';
    fallback['questionLimit'] ??= fullData['questionLimit'] ?? 5;
    fallback['feedbackStyle'] ??= fullData['feedbackStyle'] ?? '';
    fallback['includeLegend'] ??= fullData['includeLegend'] ?? false;
    fallback['difficulty'] ??= fullData['difficulty'] ?? 'Progressive (Адаптивно)';
    fallback['isTeachingMode'] ??= fullData['isTeachingMode'] ?? false;
    fallback['isEndlessMode'] ??= fullData['isEndlessMode'] ?? false;
    fallback['userName'] ??= fullData['userName'] ?? 'Кандидат';
    fallback['userBio'] ??= fullData['userBio'] ?? '';
    fallback['modelName'] ??= fullData['modelName'] ?? 'google/gemini-2.5-flash';
    fallback['isRoleplayMode'] ??= fullData['isRoleplayMode'] ?? true;
    fallback['language'] ??= fullData['language'] ?? 'Русский';

    return fallback;
  }

  static SessionConfig _safeParseConfig(
    Map<String, dynamic> configMap,
    Map<String, dynamic> fullData,
    Map sourceMap,
  ) {
    try {
      return SessionConfig.fromMap(configMap);
    } catch (_) {
      final role = configMap['role'] ??
          fullData['custom_name'] ??
          sourceMap['custom_name'] ??
          'Без названия';

      return SessionConfig(
        role: role.toString(),
        language: configMap['language']?.toString() ?? 'Русский',
        difficulty:
            configMap['difficulty']?.toString() ?? 'Progressive (Адаптивно)',
        isRoleplayMode: configMap['isRoleplayMode'] ?? true,
        persona: configMap['persona']?.toString() ?? '',
        feedbackStyle: configMap['feedbackStyle']?.toString() ?? '',
        includeLegend: configMap['includeLegend'] ?? false,
        questionLimit: configMap['questionLimit'] ?? 5,
        isTeachingMode: configMap['isTeachingMode'] ?? false,
        isEndlessMode: configMap['isEndlessMode'] ?? false,
        userName: configMap['userName']?.toString() ?? 'Кандидат',
        userBio: configMap['userBio']?.toString() ?? '',
        modelName:
            configMap['modelName']?.toString() ?? 'google/gemini-2.5-flash',
      );
    }
  }

  static DateTime _safeParseDate(Map map) {
    try {
      final raw = map['updated_at'] ?? map['created_at'] ?? map['date'];

      if (raw != null) {
        return DateTime.parse(raw.toString());
      }
    } catch (_) {}

    return DateTime.now();
  }

  String toJson() => json.encode(toMap());

  factory SessionHistory.fromJson(String source) {
    return SessionHistory.fromMap(json.decode(source));
  }

  SessionHistory copyWith({
    String? customName,
    DateTime? updatedDate,
  }) {
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