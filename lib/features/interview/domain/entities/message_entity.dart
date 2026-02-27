class MessageEntity {
  final String text;
  final bool isUser; // true - если это мы, false - если это HR-бот
  final DateTime timestamp; // Время отправки
  
  // Дополнительные поля для нашего Детектора воды и Анализа
  final String? inputType; // "Text" или "Voice"
  final String? timeTaken; // "14s"
  final bool isWater; // Пометка, что юзер налил воды
  final String? feedback; // Комментарий от ИИ после разбора

  MessageEntity({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.inputType,
    this.timeTaken,
    this.isWater = false,
    this.feedback,
  });
}