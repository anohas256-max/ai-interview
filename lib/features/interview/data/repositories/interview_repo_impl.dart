import '../../domain/entities/message_entity.dart';
import '../../domain/entities/session_config.dart';
import '../../domain/repositories/interview_repository.dart';
import 'package:sobes/features/catalog/data/datasources/django_api_source.dart'; 

class InterviewRepoImpl implements InterviewRepository {
  final DjangoApiSource apiSource;

  InterviewRepoImpl({required this.apiSource});

  @override
  Future<Map<String, dynamic>> startSession(SessionConfig config) async {
    return await apiSource.startSession(config);
  }
  
  @override
  Future<AiResponseData> sendMessage({
    required String text,
    required List<MessageEntity> history,
    required SessionConfig config,
    required String userLegend,
    required List<String> askedQuestions,
    required int sessionId, // 👈 ПРИНИМАЕМ ЕГО ЗДЕСЬ
  }) async {
    return await apiSource.getAiResponse(
      userMessage: text,
      history: history,
      config: config,
      userLegend: userLegend,
      askedQuestions: askedQuestions,
      sessionId: sessionId, // 👈 И ПЕРЕДАЕМ В API ЗДЕСЬ
    );
  }
}