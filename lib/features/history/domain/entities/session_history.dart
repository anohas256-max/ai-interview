import 'dart:convert';

class SessionHistory {
  final String id;
  final String role;
  final String persona;
  final double score;
  final DateTime date;

  SessionHistory({
    required this.id,
    required this.role,
    required this.persona,
    required this.score,
    required this.date,
  });

  // Превращаем объект в Map для сохранения
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'persona': persona,
      'score': score,
      'date': date.toIso8601String(),
    };
  }

  // Достаем объект из базы данных
  factory SessionHistory.fromMap(Map<String, dynamic> map) {
    return SessionHistory(
      id: map['id'] ?? '',
      role: map['role'] ?? '',
      persona: map['persona'] ?? '',
      score: map['score']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
    );
  }

  // Магия для shared_preferences (сохранение в виде строки)
  String toJson() => json.encode(toMap());
  factory SessionHistory.fromJson(String source) => SessionHistory.fromMap(json.decode(source));
}