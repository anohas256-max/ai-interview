import '../entities/message_entity.dart';
import '../entities/session_config.dart';
import '../../data/datasources/gemini_api_source.dart'; // Для AiResponseData

abstract class InterviewRepository {
  Future<AiResponseData> sendMessage({
    required String text,
    required List<MessageEntity> history,
    required SessionConfig config,
    required String userLegend,         // <--- Добавили
    required List<String> askedQuestions, // <--- Добавили
  });
}