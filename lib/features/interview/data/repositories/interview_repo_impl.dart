import '../../domain/entities/message_entity.dart';
import '../../domain/entities/session_config.dart';
import '../../domain/repositories/interview_repository.dart';
import '../datasources/gemini_api_source.dart';

class InterviewRepoImpl implements InterviewRepository {
  final GeminiApiSource apiSource;

  InterviewRepoImpl({required this.apiSource});

  @override
  Future<AiResponseData> sendMessage({
    required String text,
    required List<MessageEntity> history,
    required SessionConfig config,
    required String userLegend,
    required List<String> askedQuestions,
  }) async {
    // Передаем все новые параметры в API
    return await apiSource.getAiResponse(
      userMessage: text,
      history: history,
      config: config,
      userLegend: userLegend,
      askedQuestions: askedQuestions,
    );
  }
}