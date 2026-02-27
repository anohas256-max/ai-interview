class AnalysisResult {
  final double score;
  final String performanceText;
  final List<String> strengths;
  final List<String> weaknesses;

  AnalysisResult({
    required this.score,
    required this.performanceText,
    required this.strengths,
    required this.weaknesses,
  });

  // Фабрика для безопасного парсинга JSON от ИИ
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      performanceText: json['performance_text'] ?? "Нет данных",
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
    );
  }
}