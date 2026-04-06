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
    
    // 👇 Теперь API достает язык прямо из конфига сессии 👇
    final bool isEng = config.language == 'English';

    // ДИНАМИЧЕСКИЙ БЛОК ПАМЯТИ
    String memoryBlock = isEng 
      ? "CANDIDATE NAME: ${config.userName}.\n"
      : "ИМЯ КАНДИДАТА: ${config.userName}.\n";
    
    if (config.userBio.isNotEmpty) {
      memoryBlock += isEng 
        ? "CANDIDATE PROFILE: ${config.userBio}.\n" 
        : "ПРОФИЛЬ КАНДИДАТА: ${config.userBio}.\n";
    }
    
    if (userLegend.isNotEmpty) {
      memoryBlock += isEng 
        ? "ANSWER TO 'TELL ME ABOUT YOURSELF': $userLegend\n"
        : "ОТВЕТ НА 'РАССКАЖИ О СЕБЕ': $userLegend\n";
    }
    
    if (askedQuestions.isNotEmpty) {
      memoryBlock += isEng 
        ? "TOPICS AND QUESTIONS YOU ALREADY ASKED (do not repeat!): ${askedQuestions.join(' | ')}.\n"
        : "ТЕМЫ И ВОПРОСЫ, КОТОРЫЕ ТЫ УЖЕ ЗАДАВАЛ (не повторяйся!): ${askedQuestions.join(' | ')}.\n";
    }

    String systemInstruction;

    // ОБЩЕЕ ПРАВИЛО ДЛЯ ОБОИХ РЕЖИМОВ (Анти-троллинг)
    String antiTrollRule = isEng
      ? "ANTI-TROLLING RULE: If the user is explicitly mocking, spamming incoherent nonsense (e.g. 'no', 'a', 'uh', '123'), swearing, or insulting you — you MUST respond. First, write 2-3 sentences with a strictly cold and firm refusal (point out the unacceptability of such behavior). And ONLY AFTER THIS TEXT, at the very end of the message, add the tag [FAIL]. Never send the [FAIL] tag without a textual explanation. ATTENTION: An honest admission 'I don't know' is NOT trolling, terminating the session for this is forbidden."
      : "ЗАЩИТА ОТ ТРОЛЛИНГА: Если пользователь откровенно издевается, спамит бессвязным бредом (например 'не', 'а', 'ы', '123'), матерится или посылает тебя — ты ОБЯЗАН ответить. Сначала напиши 2-3 предложения с максимально строгим и холодным отказом (укажи на недопустимость такого поведения). И ТОЛЬКО ПОСЛЕ ЭТОГО ТЕКСТА, в самом конце сообщения, добавь тег [FAIL]. Никогда не присылай тег [FAIL] без текстового пояснения. ВНИМАНИЕ: Честное признание 'я не знаю' — это НЕ троллинг, за это прерывать сессию запрещено.";
    
    // ЖЕСТКОЕ ПРАВИЛО ЯЗЫКА
    String langRule = isEng 
      ? "CRITICAL RULE: YOU MUST SPEAK EXCLUSIVELY IN ENGLISH. ALL YOUR RESPONSES, QUESTIONS AND FEEDBACK MUST BE IN ENGLISH."
      : "КРИТИЧЕСКОЕ ПРАВИЛО: ТЫ ОБЯЗАН ГОВОРИТЬ ИСКЛЮЧИТЕЛЬНО НА РУССКОМ ЯЗЫКЕ. ВСЕ ТВОИ ОТВЕТЫ, ВОПРОСЫ И ФИДБЕК ДОЛЖНЫ БЫТЬ НА РУССКОМ.";

    if (config.isRoleplayMode) {
      // ПРОМПТ ДЛЯ СОБЕСЕДОВАНИЙ
      systemInstruction = isEng
        ? "You are conducting a roleplay interview. Candidate's role: '${config.role}'. Difficulty: ${config.difficulty}.\n"
          "Your persona: ${config.persona}, Style: ${config.feedbackStyle}.\n"
          "RULES:\n"
          "1. INVENT A NAME: Call yourself a suitable name. No [Your Name] placeholders!\n"
          "2. NATURAL SPEECH: DO NOT quote the role title word-for-word. Weave it naturally into speech.\n"
          "3. LORE: Questions must STRICTLY follow the universe's canon.\n"
          "4. $antiTrollRule\n"
          "5. DRILL-DOWN MODE: If the candidate answers correctly, NEVER praise them. Instead, immediately complicate the condition.\n"
          "6. DYNAMICS AND TOPIC CHANGE: You have a question limit. DO NOT stall on one topic for more than 2 messages! Asked -> answered -> 1 clarification -> MOVE TO A NEW TOPIC.\n"
          "7. $langRule\n"
          "$memoryBlock"
        : "Ты проводишь сюжетное собеседование. Роль кандидата: '${config.role}'. Уровень сложности: ${config.difficulty}.\n"
          "Твой характер: ${config.persona}, Стиль: ${config.feedbackStyle}.\n"
          "ПРАВИЛА:\n"
          "1. ПРИДУМАЙ ИМЯ: Назови себя подходящим именем. Никаких [Твоё Имя]!\n"
          "2. ЖИВАЯ РЕЧЬ: КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО цитировать название роли буква в букву. Вплетай название в речь естественно.\n"
          "3. ЛОР: Вопросы должны СТРОГО соответствовать канону вселенной.\n"
          "4. $antiTrollRule\n"
          "5. РЕЖИМ «ДОЖИМ» (Drill-Down): Если кандидат отвечает правильно, НИКОГДА не хвали его. Вместо этого сразу усложни условие задачи.\n"
          "6. ДИНАМИКА И СМЕНА ТЕМ: У тебя лимит вопросов. КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО топтаться на одной теме больше 2 сообщений! Задал вопрос -> получил ответ -> задал 1 уточнение -> СРАЗУ ПЕРЕХОДИШЬ К АБСОЛЮТНО НОВОЙ ТЕМЕ.\n"
          "7. $langRule\n"
          "$memoryBlock";
    } else {
      // ПРОМПТ ДЛЯ ПРОВЕРКИ ЗНАНИЙ
      String difficultyRules = "";
      if (config.difficulty.contains("Легкий") || config.difficulty.contains("Junior")) {
        difficultyRules = isEng 
          ? "Ask the most basic, fundamental questions. Check the foundation." 
          : "Задавай самые базовые, фундаментальные вопросы. Проверяй основы. Формулируй вопросы просто и понятно.";
      } else if (config.difficulty.contains("Средний") || config.difficulty.contains("Middle")) {
        difficultyRules = isEng 
          ? "Ask intermediate level questions requiring understanding of processes and typical tasks." 
          : "Задавай вопросы среднего уровня, требующие понимания процессов, взаимосвязей и умения решать типовые задачи.";
      } else if (config.difficulty.contains("Сложный") || config.difficulty.contains("Senior")) {
        difficultyRules = isEng 
          ? "Ask expert, tricky questions. Demand deep understanding of architecture and complex scenarios. Evaluate strictly." 
          : "Задавай экспертные, каверзные вопросы. Требуй глубокого понимания неочевидных нюансов, архитектуры или сложных сценариев. Оценивай ответ максимально строго.";
      }

      systemInstruction = isEng
        ? "You are an AI-examiner. Task: test the user's knowledge on the topic (or profession): '${config.role}'.\n"
          "Communication style: ${config.feedbackStyle}.\n"
          "DIFFICULTY: ${config.difficulty}. $difficultyRules\n\n"
          "RULES:\n"
          "1. NO ROLEPLAY: No names, greetings, or HR fluff. Get straight to business.\n"
          "2. DIALOG FORMAT: Ask ONE question at a time. Wait for an answer. Briefly evaluate it (in '${config.feedbackStyle}' style), correct mistakes if any, and IMMEDIATELY ask the next question.\n"
          "3. $antiTrollRule\n"
          "4. DYNAMICS: Test from different angles. Strictly change subtopics. Do not loop on one concept!\n"
          "5. If user says 'I don't know' - briefly explain and move on.\n"
          "6. If user asks to clarify the question - do it, do not count it as a mistake.\n"
          "7. $langRule\n"
          "$memoryBlock"
        : "Ты — нейросеть-экзаменатор. Твоя задача — проверить знания пользователя по теме (или профессии): '${config.role}'.\n"
          "Стиль общения: ${config.feedbackStyle}.\n"
          "УРОВЕНЬ СЛОЖНОСТИ: ${config.difficulty}. $difficultyRules\n\n"
          "ПРАВИЛА:\n"
          "1. БЕЗ РОЛЕЙ: Никаких имен, приветствий и HR-шелухи. Переходи сразу к делу.\n"
          "2. ФОРМАТ ДИАЛОГА: Задавай только ОДИН вопрос за раз. Жди ответа. Получив ответ, коротко оцени его (в стиле '${config.feedbackStyle}'), исправь ошибку, если она есть, и СРАЗУ задай следующий вопрос.\n"
          "3. $antiTrollRule\n"
          "4. ДИНАМИКА ТЕМ: Ты должен протестировать пользователя с разных сторон темы '${config.role}'. Задав вопрос и получив ответ (и, если нужно, задав 1 уточняющий вопрос), СТРОГО меняй подтему. Не зацикливайся на одном и том же понятии!\n"
          "5. Если пользователь отвечает 'не знаю' — кратко объясни суть и переходи к следующему вопросу.\n"
          "6. Если пользователь просит уточнить или перефразировать вопрос — сделай это, не считая за ошибку.\n"
          "7. $langRule\n"
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
      final err = isEng ? "System Error" : "Системная ошибка";
      return AiResponseData(
        text: "⚠️ [$err]: ${e.response?.statusCode}. ${e.message}", 
        inputTokens: 0, outputTokens: 0, cost: 0.0
      );
    } catch (e) {
      final err = isEng ? "Unknown Error" : "Неизвестная ошибка";
      return AiResponseData(
        text: "⚠️ [$err]: $e", 
        inputTokens: 0, outputTokens: 0, cost: 0.0
      );
    }
  }
}