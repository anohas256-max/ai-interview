class SessionConfig {
  final String role; final String persona; final int questionLimit; final String feedbackStyle;
  final bool includeLegend; final String difficulty;  
  final bool isTeachingMode; final bool isEndlessMode;  
  final String userName; final String userBio; final String modelName; 
  final bool isRoleplayMode; 
  final String language; // 👈 ДОБАВИЛИ НОВЫЙ ПАРАМЕТР ЯЗЫКА

  SessionConfig({
    required this.role, required this.persona, required this.questionLimit, required this.feedbackStyle,
    this.includeLegend = true, this.difficulty = 'Progressive (Адаптивно)',
    this.isTeachingMode = false, this.isEndlessMode = false,
    this.userName = 'Кандидат', this.userBio = '', this.modelName = 'google/gemini-2.5-flash', 
    this.isRoleplayMode = true, 
    this.language = 'Русский', // 👈 По умолчанию
  });

  Map<String, dynamic> toMap() => {
    'role': role, 'persona': persona, 'questionLimit': questionLimit, 'feedbackStyle': feedbackStyle,
    'includeLegend': includeLegend, 'difficulty': difficulty, 'isTeachingMode': isTeachingMode,
    'isEndlessMode': isEndlessMode, 'userName': userName, 'userBio': userBio, 'modelName': modelName,
    'isRoleplayMode': isRoleplayMode, 
    'language': language, // 👈 СОХРАНЯЕМ
  };

  factory SessionConfig.fromMap(Map<String, dynamic> map) => SessionConfig(
    role: map['role'], persona: map['persona'], questionLimit: map['questionLimit'], feedbackStyle: map['feedbackStyle'],
    includeLegend: map['includeLegend'], difficulty: map['difficulty'], isTeachingMode: map['isTeachingMode'],
    isEndlessMode: map['isEndlessMode'], userName: map['userName'], userBio: map['userBio'], modelName: map['modelName'],
    isRoleplayMode: map['isRoleplayMode'] ?? true, 
    language: map['language'] ?? 'Русский', // 👈 ЧИТАЕМ (с защитой от старых сохранений)
  );
}