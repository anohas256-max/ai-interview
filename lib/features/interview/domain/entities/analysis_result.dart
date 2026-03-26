class SmartRecap {
  final String topic;
  final String explanation;
  final String recommendation;

  SmartRecap({required this.topic, required this.explanation, required this.recommendation});

  factory SmartRecap.fromJson(Map<String, dynamic> json) {
    return SmartRecap(
      topic: json['topic'] ?? '',
      explanation: json['explanation'] ?? '',
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class AnalysisResult {
  final double score;
  final String performanceText;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<SmartRecap> smartRecap;

  AnalysisResult({
    required this.score,
    required this.performanceText,
    required this.strengths,
    required this.weaknesses,
    this.smartRecap = const [],
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      score: (json['score'] ?? 0.0).toDouble(),
      performanceText: json['performance_text'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      smartRecap: (json['smart_recap'] as List?)?.map((e) => SmartRecap.fromJson(e)).toList() ?? [],
    );
  }
}