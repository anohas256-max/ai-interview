import 'package:dio/dio.dart';
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
  final String _apiKey = AppConfig.openRouterApiKey;
  final Dio _dio = Dio();

  Future<AiResponseData> getAiResponse({
    required String userMessage,
    required List<MessageEntity> history,
    required SessionConfig config,
    required String userLegend, 
    required List<String> askedQuestions, 
  }) async {
    
    String memoryBlock = "ИМЯ КАНДИДАТА: ${config.userName}.\n";
    if (config.userBio.isNotEmpty) memoryBlock += "ПРОФИЛЬ КАНДИДАТА: ${config.userBio}.\n";
    if (userLegend.isNotEmpty) memoryBlock += "ОТВЕТ НА 'РАССКАЖИ О СЕБЕ': $userLegend\n";
    if (askedQuestions.isNotEmpty) memoryBlock += "ТЕМЫ И ВОПРОСЫ, КОТОРЫЕ ТЫ УЖЕ ЗАДАВАЛ (не повторяйся!): ${askedQuestions.join(' | ')}.\n";

    String systemInstruction;

    // 👇 ОБЩЕЕ ПРАВИЛО ДЛЯ ОБОИХ РЕЖИМОВ 👇
    String antiTrollRule = "ЗАЩИТА ОТ ТРОЛЛИНГА: Если пользователь откровенно издевается, спамит бессвязным бредом (например 'не', 'а', 'ы', '123'), матерится или посылает тебя — ты ОБЯЗАН ответить. Сначала напиши 2-3 предложения с максимально строгим и холодным отказом (укажи на недопустимость такого поведения). И ТОЛЬКО ПОСЛЕ ЭТОГО ТЕКСТА, в самом конце сообщения, добавь тег [FAIL]. Никогда не присылай тег [FAIL] без текстового пояснения. ВНИМАНИЕ: Честное признание 'я не знаю' — это НЕ троллинг, за это прерывать сессию запрещено.";
    
    if (config.isRoleplayMode) {
      // ПРОМПТ ДЛЯ СОБЕСЕДОВАНИЙ
      systemInstruction = 
        "Ты проводишь сюжетное собеседование. Роль кандидата: '${config.role}'. Уровень сложности: ${config.difficulty}.\n"
        "Твой характер: ${config.persona}, Стиль: ${config.feedbackStyle}.\n"
        "ПРАВИЛА:\n"
        "1. ПРИДУМАЙ ИМЯ: Назови себя подходящим именем. Никаких [Твоё Имя]!\n"
        "2. ЖИВАЯ РЕЧЬ: КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО цитировать название роли буква в букву. Вплетай название в речь естественно.\n"
        "3. ЛОР: Вопросы должны СТРОГО соответствовать канону вселенной.\n"
        "4. $antiTrollRule\n"
        "5. РЕЖИМ «ДОЖИМ» (Drill-Down): Если кандидат отвечает правильно, НИКОГДА не хвали его. Вместо этого сразу усложни условие задачи.\n"
        "6. ДИНАМИКА И СМЕНА ТЕМ: У тебя лимит вопросов. КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО топтаться на одной теме больше 2 сообщений! Задал вопрос -> получил ответ -> задал 1 уточнение -> СРАЗУ ПЕРЕХОДИШЬ К АБСОЛЮТНО НОВОЙ ТЕМЕ.\n"
        "$memoryBlock";
    } else {
      // ПРОМПТ ДЛЯ ПРОВЕРКИ ЗНАНИЙ
      String difficultyRules = "";
      if (config.difficulty.contains("Легкий")) {
        difficultyRules = "Задавай самые базовые, фундаментальные вопросы. Проверяй основы. Формулируй вопросы просто и понятно.";
      } else if (config.difficulty.contains("Средний")) {
        difficultyRules = "Задавай вопросы среднего уровня, требующие понимания процессов, взаимосвязей и умения решать типовые задачи.";
      } else if (config.difficulty.contains("Сложный")) {
        difficultyRules = "Задавай экспертные, каверзные вопросы. Требуй глубокого понимания неочевидных нюансов, архитектуры или сложных сценариев. Оценивай ответ максимально строго.";
      }

      systemInstruction = 
        "Ты — нейросеть-экзаменатор. Твоя задача — проверить знания пользователя по теме (или профессии): '${config.role}'.\n"
        "Стиль общения: ${config.feedbackStyle}.\n"
        "УРОВЕНЬ СЛОЖНОСТИ: ${config.difficulty}. $difficultyRules\n\n"
        "ПРАВИЛА:\n"
        "1. БЕЗ РОЛЕЙ: Никаких имен, приветствий и HR-шелухи. Переходи сразу к делу.\n"
        "2. ФОРМАТ ДИАЛОГА: Задавай только ОДИН вопрос за раз. Жди ответа. Получив ответ, коротко оцени его (в стиле '${config.feedbackStyle}'), исправь ошибку, если она есть, и СРАЗУ задай следующий вопрос.\n"
        "3. $antiTrollRule\n"
        "4. ДИНАМИКА ТЕМ: Ты должен протестировать пользователя с разных сторон темы '${config.role}'. Задав вопрос и получив ответ (и, если нужно, задав 1 уточняющий вопрос), СТРОГО меняй подтему. Не зацикливайся на одном и том же понятии!\n"
        "5. Если пользователь отвечает 'не знаю' — кратко объясни суть и переходи к следующему вопросу.\n"
        "6. Если пользователь просит уточнить или перефразировать вопрос — сделай это, не считая за ошибку.\n"
        "$memoryBlock";
    }
          
    List<Map<String, String>> messages = [{"role": "system", "content": systemInstruction}];

    final pastMessages = history.length > 1 ? history.sublist(0, history.length - 1) : <MessageEntity>[];
    for (var msg in pastMessages) {
      messages.add({"role": msg.isUser ? "user" : "assistant", "content": msg.text});
    }
    messages.add({"role": "user", "content": userMessage});

    try {
      final response = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'HTTP-Referer': 'https://github.com/anohas256-max/ai-interview', 
            'X-Title': 'AI Interview App', 
          },
        ),
        data: {
          "model": config.modelName, 
          "messages": messages,
          "max_tokens": 8000,
        },
      );

      final data = response.data;
      final String text = data['choices'][0]['message']['content'];
      
      final int inTokens = data['usage']['prompt_tokens'] ?? 0;
      final int outTokens = data['usage']['completion_tokens'] ?? 0;
      final double cost = (data['usage']['total_cost'] ?? 0.0).toDouble();
      
      return AiResponseData(text: text, inputTokens: inTokens, outputTokens: outTokens, cost: cost);
      
    } on DioException catch (e) {
      return AiResponseData(
        text: "⚠️ [СИСТЕМНОЕ СООБЩЕНИЕ]: Ошибка связи. Код: ${e.response?.statusCode}. Детали: ${e.message}", 
        inputTokens: 0, outputTokens: 0, cost: 0.0
      );
    } catch (e) {
      return AiResponseData(
        text: "⚠️ [СИСТЕМНОЕ СООБЩЕНИЕ]: Неизвестная ошибка: $e", 
        inputTokens: 0, outputTokens: 0, cost: 0.0
      );
    }
  }
}