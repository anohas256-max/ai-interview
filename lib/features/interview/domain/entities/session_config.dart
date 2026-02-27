class SessionConfig {
  final String role;
  final String persona;
  final int questionLimit;
  final String feedbackStyle;
  
  final bool includeLegend; 
  final String difficulty;  
  
  final bool isTeachingMode; 
  final bool isEndlessMode;  

  final String userName;
  final String userBio;

  // 👇 ДОБАВЛЯЕМ ПЕРЕМЕННУЮ МОДЕЛИ 👇
  final String modelName; 

  SessionConfig({
    required this.role,
    required this.persona,
    required this.questionLimit,
    required this.feedbackStyle,
    this.includeLegend = true, 
    this.difficulty = 'Progressive (Адаптивно)',
    this.isTeachingMode = false,
    this.isEndlessMode = false,
    this.userName = 'Кандидат', 
    this.userBio = '',          
    this.modelName = 'gemini-3.1-pro-preview', // По умолчанию ставим рабочую лошадку
  });
}