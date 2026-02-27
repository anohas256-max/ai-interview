
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/session_config.dart';
import '../../../../core/config/app_config.dart';

class AiResponseData {
  final String text;
  final int inputTokens;
  final int outputTokens;
  final double cost;

  AiResponseData({required this.text, required this.inputTokens, required this.outputTokens, required this.cost});
}

class GeminiApiSource {
final String _apiKey = AppConfig.geminiApiKey;
  
  double _calculateCost(String modelName, int inputTokens, int outputTokens) {
    double inputPrice = 0.0;
    double outputPrice = 0.0;

    // Прайс-лист для всех версий
    if (modelName.contains('lite') || modelName.contains('2.0-flash')) {
      inputPrice = 0.075; 
      outputPrice = 0.30; 
    } else if (modelName.contains('flash')) {
      inputPrice = 0.10; 
      outputPrice = 0.40; 
    } else if (modelName.contains('pro')) {
      inputPrice = 1.25;
      outputPrice = 5.00;
    }

    return ((inputTokens / 1000000) * inputPrice) + ((outputTokens / 1000000) * outputPrice);
  }

  Future<AiResponseData> getAiResponse({
    required String userMessage,
    required List<MessageEntity> history,
    required SessionConfig config,
    required String userLegend, 
    required List<String> askedQuestions, 
  }) async {
    
    // Берем модель прямо из настроек сессии
    String currentModel = config.modelName; 
    
    String memoryBlock = "";
    memoryBlock += "ИМЯ КАНДИДАТА: ${config.userName}. Обращайся к нему по имени.\n";
    if (config.userBio.isNotEmpty) {
      memoryBlock += "ПРОФИЛЬ КАНДИДАТА (Бэкграунд): ${config.userBio}. Опирайся на этот опыт при общении.\n";
    }

    if (userLegend.isNotEmpty) memoryBlock += "ОТВЕТ НА ВОПРОС 'РАССКАЖИ О СЕБЕ': $userLegend\n";
    if (askedQuestions.isNotEmpty) memoryBlock += "УЖЕ ЗАДАННЫЕ ВОПРОСЫ (НЕ ПОВТОРЯЙ): ${askedQuestions.join(' | ')}.\n";

   final model = GenerativeModel(
      model: currentModel, 
      apiKey: _apiKey,
   systemInstruction: Content.system(
        "Ты профессиональный интервьюер. Твоя задача провести глубокое собеседование/интервью на роль: '${config.role}'.\n"
        "Твой характер и стиль ведения диалога: ${config.persona}, ${config.feedbackStyle}.\n\n"
        "ВАЖНЫЕ ПРАВИЛА (СТРОГО СОБЛЮДАТЬ!):\n"
        "1. Имя собеседника — ${config.userName}. ОБЯЗАТЕЛЬНО обращайся к нему по имени.\n"
        "2. НИКАКИХ ШАБЛОНОВ: Категорически запрещено использовать плейсхолдеры вроде [Ваше Имя], [Название компании], [HR-департамент]. Придумывай реалистичные названия на ходу или просто говори от первого лица.\n"
        "3. ЧЕЛОВЕЧНОСТЬ: Пиши максимально живым, разговорным языком. Избегай роботизированного канцелярита, сложных деепричастных оборотов и нудных маркированных списков. Веди себя как настоящий, живой эксперт в диалоге 1 на 1.\n"
        "4. Твои вопросы должны СТРОГО соответствовать заявленной роли ('${config.role}'). Задавай вопросы исключительно по лору, навыкам и специфике выбранной роли.\n"
        "${config.userBio.isNotEmpty ? "5. Учитывай бэкграунд собеседника: ${config.userBio}\n" : ""}"
        "\n$memoryBlock"
      ),
    );

    final pastMessages = history.length > 1 ? history.sublist(0, history.length - 1) : <MessageEntity>[];
    final List<Content> chatHistory = pastMessages.map((msg) => 
        msg.isUser ? Content.text(msg.text) : Content.model([TextPart(msg.text)])).toList();

    final chat = model.startChat(history: chatHistory);

    try {
      final response = await chat.sendMessage(Content.text(userMessage));
      final inTokens = response.usageMetadata?.promptTokenCount ?? 0;
      final outTokens = response.usageMetadata?.candidatesTokenCount ?? 0;
      final cost = _calculateCost(currentModel, inTokens, outTokens);
      
      return AiResponseData(text: response.text ?? "", inputTokens: inTokens, outputTokens: outTokens, cost: cost);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('Quota exceeded') || errorMessage.contains('429')) {
        errorMessage = "⚠️ [СИСТЕМНОЕ СООБЩЕНИЕ]: Превышен лимит бесплатных запросов к ИИ. Пожалуйста, подождите 30-60 секунд и повторите ответ.";
      } else {
        errorMessage = "⚠️ [СИСТЕМНОЕ СООБЩЕНИЕ]: Ошибка связи с нейросетью. Детали: $errorMessage";
      }
      return AiResponseData(text: errorMessage, inputTokens: 0, outputTokens: 0, cost: 0.0);
    }
  }
}