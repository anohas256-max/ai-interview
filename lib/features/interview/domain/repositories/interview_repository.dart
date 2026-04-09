import '../entities/message_entity.dart';
import '../entities/session_config.dart';
// 👇 УКАЗЫВАЕМ НОВЫЙ ПУТЬ К AiResponseData 👇
import 'package:sobes/features/catalog/data/datasources/django_api_source.dart';

abstract class InterviewRepository {
  Future<Map<String, dynamic>> startSession(SessionConfig config);
  
  Future<AiResponseData> sendMessage({
    required String text,
    required List<MessageEntity> history,
    required SessionConfig config,
    required String userLegend,
    required List<String> askedQuestions,
  });
}