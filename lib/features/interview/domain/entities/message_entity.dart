class MessageEntity {
  final String text;
  final bool isUser; 
  final DateTime timestamp; 
  final String? inputType; 
  final String? timeTaken; 
  final bool isWater; 
  final String? feedback; 

  MessageEntity({
    required this.text, required this.isUser, required this.timestamp,
    this.inputType, this.timeTaken, this.isWater = false, this.feedback,
  });

  // Превращаем сообщение в Map для сохранения
  Map<String, dynamic> toMap() => {
    'text': text, 'isUser': isUser, 'timestamp': timestamp.toIso8601String(),
    'inputType': inputType, 'timeTaken': timeTaken,
    'isWater': isWater, 'feedback': feedback,
  };

  // Достаем из базы
  factory MessageEntity.fromMap(Map<String, dynamic> map) => MessageEntity(
    text: map['text'], isUser: map['isUser'], timestamp: DateTime.parse(map['timestamp']),
    inputType: map['inputType'], timeTaken: map['timeTaken'],
    isWater: map['isWater'] ?? false, feedback: map['feedback'],
  );



  // 👇 ДОБАВЛЯЕМ ЭТОТ БЛОК В КОНЕЦ КЛАССА 👇
  MessageEntity copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? inputType,
    String? timeTaken,
    bool? isWater,
    String? feedback,
  }) {
    return MessageEntity(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      inputType: inputType ?? this.inputType,
      timeTaken: timeTaken ?? this.timeTaken,
      isWater: isWater ?? this.isWater,
      feedback: feedback ?? this.feedback,
    );
  }
}