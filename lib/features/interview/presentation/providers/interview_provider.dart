import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/session_config.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/repositories/interview_repository.dart';
import '../../data/datasources/gemini_api_source.dart';

class InterviewProvider extends ChangeNotifier {
  final InterviewRepository repository; 

  final List<MessageEntity> _messages = [];
  SessionConfig? _config;
  String _userLegend = ""; 
  final List<String> _askedQuestions = []; 

  bool _isLoading = false;
  bool _isFailed = false; 
  bool _isFinished = false; 

  // --- ⏱️ ТАЙМЕРЫ ---
  DateTime? _sessionStartTime;
  DateTime? _lastAiResponseTime;
  final List<int> _userResponseDurations = [];

  // --- 📊 АНАЛИТИКА ---
  AnalysisResult? _analysisResult;
  bool _isAnalyzing = false;
  
  // --- 💰 БИЛЛИНГ И ЛОГИ ---
  int _totalInputTokens = 0;
  int _totalOutputTokens = 0;
  double _totalCost = 0.0;
  int _totalRequests = 0;

  InterviewProvider({required this.repository});

  List<MessageEntity> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isFailed => _isFailed;
  bool get isFinished => _isFinished;
  AnalysisResult? get analysisResult => _analysisResult;
  bool get isAnalyzing => _isAnalyzing;

  bool get isLegendPhase => _config?.includeLegend == true && _userLegend.isEmpty && _messages.where((m) => m.isUser).isEmpty;
  
  // 👇 НОВЫЙ ГЕТТЕР (Чтобы Экран Аналитики мог узнать Роль и Персону для сохранения)
  SessionConfig? get config => _config;

  // Геттеры для UI
  String get totalTimeFormatted {
    if (_sessionStartTime == null) return "0m";
    final diff = DateTime.now().difference(_sessionStartTime!);
    return "${diff.inMinutes}m";
  }

  String get avgResponseFormatted {
    if (_userResponseDurations.isEmpty) return "0s";
    final avg = _userResponseDurations.reduce((a, b) => a + b) / _userResponseDurations.length;
    return "${avg.round()}s";
  }

  void setConfig(SessionConfig config) => _config = config;

  void _logToDatabase(AiResponseData data, String actionType) {
    _totalRequests++;
    _totalInputTokens += data.inputTokens;
    _totalOutputTokens += data.outputTokens;
    _totalCost += data.cost;
    
    final modelUsed = _config?.modelName ?? "Unknown Model";
    
    print('\n[DB LOG] === ЗАПРОС №$_totalRequests ($actionType) ===');
    print('[DB LOG] Модель: $modelUsed');
    print('[DB LOG] Токены: Ввод ${data.inputTokens} | Вывод ${data.outputTokens}');
    print('[DB LOG] Цена запроса: \$${data.cost.toStringAsFixed(6)}');
    print('[DB LOG] ОБЩАЯ СТОИМОСТЬ СЕССИИ: \$$_totalCost\n');
  }

  Future<void> startInterview() async {
    if (_messages.isNotEmpty || _config == null || _isLoading) return;
    
    _isLoading = true;
    _sessionStartTime = DateTime.now(); 
    notifyListeners();

    try {
      String prompt = _config!.includeLegend 
          ? "[СИСТЕМНОЕ: Поздоровайся, обратившись по имени (${_config!.userName}), представься в своей роли и попроси собеседника коротко рассказать о себе и своем опыте в сфере '${_config!.role}'.]"
          : "[СИСТЕМНОЕ: Поздоровайся, обратившись по имени (${_config!.userName}), представься и сразу задай первый сложный профильный вопрос, который идеально проверит знания для роли '${_config!.role}'.]";

      final aiData = await repository.sendMessage(
        text: prompt,
        history: [], 
        config: _config!, 
        userLegend: _userLegend, 
        askedQuestions: _askedQuestions,
      );
      
      _logToDatabase(aiData, "START_INTERVIEW"); 
      _lastAiResponseTime = DateTime.now();
      _processAiResponse(aiData.text);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _config == null || _isLoading) return; 

    if (_lastAiResponseTime != null) {
      _userResponseDurations.add(DateTime.now().difference(_lastAiResponseTime!).inSeconds);
    }

    _messages.add(MessageEntity(text: text, isUser: true, timestamp: DateTime.now()));
    if (_config!.includeLegend && _userLegend.isEmpty) _userLegend = text;
    
    _isLoading = true;
    notifyListeners(); 

    try {
      int techAnswersCount = _config!.includeLegend ? _messages.where((m) => m.isUser).length - 1 : _messages.where((m) => m.isUser).length;
      String textToSend = text;
      
      if (!_config!.isEndlessMode && techAnswersCount >= _config!.questionLimit) {
        textToSend = "$text\n\n[СИСТЕМНОЕ: Это последний ответ. Попрощайся и добавь тег [END]]";
      }

      final aiData = await repository.sendMessage(
        text: textToSend, 
        history: _messages.length > 4 ? _messages.sublist(_messages.length - 4) : _messages, 
        config: _config!, userLegend: _userLegend, askedQuestions: _askedQuestions, 
      );
      
      _logToDatabase(aiData, "CHAT_MESSAGE"); 
      _lastAiResponseTime = DateTime.now();
      _processAiResponse(aiData.text);
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  void _processAiResponse(String rawText) {
    if (rawText.contains('[FAIL]')) { rawText = rawText.replaceAll('[FAIL]', '').trim(); _isFailed = true; }
    if (rawText.contains('[END]')) { rawText = rawText.replaceAll('[END]', '').trim(); _isFinished = true; }
    _askedQuestions.add(rawText);
    _messages.add(MessageEntity(text: rawText, isUser: false, timestamp: DateTime.now()));
  }

  // --- ФИНАЛЬНЫЙ БОСС: ГЕНЕРАЦИЯ JSON АНАЛИТИКИ ---
  // 👇 ДОБАВЛЕН ПАРАМЕТР onSuccess 👇
  Future<void> generateAnalysis({VoidCallback? onSuccess}) async {
    if (_isAnalyzing) return; 

    _isAnalyzing = true;
    _analysisResult = null;
    notifyListeners();

    try {
      String fullChat = _messages.map((m) => "${m.isUser ? 'КАНДИДАТ' : 'HR'}: ${m.text}").join('\n\n');
      
      String analysisPrompt = """
      Проанализируй транскрипцию собеседования и верни ответ СТРОГО в формате JSON.
      Не пиши слова "Вот ваш анализ" или форматирование ```json. Только голый JSON.
      
      Шаблон:
      {
        "score": 7.5,
        "performance_text": "Better than 82% of users",
        "strengths": ["Пункт 1", "Пункт 2"],
        "weaknesses": ["Ошибка 1", "Ошибка 2"]
      }

      ТРАНСКРИПЦИЯ:
      $fullChat
      """;

      final aiData = await repository.sendMessage(
        text: analysisPrompt, history: [], config: _config!, userLegend: _userLegend, askedQuestions: [],
      );
      
      _logToDatabase(aiData, "ANALYSIS_GENERATION");
      String rawResponse = aiData.text;
      
      if (rawResponse.contains('⚠️ [СИСТЕМНОЕ СООБЩЕНИЕ]')) {
         throw Exception("Сервер Гугла перегружен (503)"); 
      }

      int startIndex = rawResponse.indexOf('{');
      int endIndex = rawResponse.lastIndexOf('}');
      
      if (startIndex != -1 && endIndex != -1) {
        String jsonString = rawResponse.substring(startIndex, endIndex + 1);
        final Map<String, dynamic> jsonData = jsonDecode(jsonString);
        _analysisResult = AnalysisResult.fromJson(jsonData);
        
        // 👇 МАГИЯ: ВЫЗЫВАЕМ СОХРАНЕНИЕ В БАЗУ ТОЛЬКО ПРИ УСПЕХЕ! 👇
        onSuccess?.call();

      } else {
        throw Exception("ИИ не вернул JSON");
      }

    } catch (e) {
      _analysisResult = AnalysisResult(
        score: 0.0, 
        performanceText: "Ошибка анализа", 
        strengths: ["Не удалось получить данные: $e"], 
        weaknesses: []
      );
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }


  // --- ПОВТОР ОТПРАВКИ ПРИ ОШИБКЕ ---
  Future<void> retryLastMessage() async {
    if (_isLoading || _messages.isEmpty) return;

    if (!_messages.last.isUser && _messages.last.text.contains('⚠️')) {
      _messages.removeLast(); 
      
      if (_messages.isEmpty) {
        notifyListeners(); 
        await startInterview(); 
        return; 
      }
      
      if (_messages.isNotEmpty && _messages.last.isUser) {
        String textToRetry = _messages.last.text;
        _messages.removeLast(); 
        
        await sendMessage(textToRetry); 
      } else {
        notifyListeners(); 
      }
    }
  }

  void clearChat() {
    _messages.clear();
    _isFailed = false; _isFinished = false; _userLegend = ""; _askedQuestions.clear();
    _analysisResult = null; _isAnalyzing = false;
    _totalInputTokens = 0; _totalOutputTokens = 0; _totalCost = 0.0; _totalRequests = 0;
    _userResponseDurations.clear(); _sessionStartTime = null; _lastAiResponseTime = null;
    notifyListeners();
  }
}