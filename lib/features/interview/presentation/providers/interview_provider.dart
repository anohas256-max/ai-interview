import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/session_config.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/repositories/interview_repository.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sobes/features/history/domain/entities/session_history.dart';

class InterviewProvider extends ChangeNotifier {
  final InterviewRepository repository; 

  final List<MessageEntity> _messages = [];
  SessionConfig? _config;
  String _userLegend = ""; 
  final List<String> _askedQuestions = []; 

  bool _isLoading = false; bool _isFailed = false; bool _isFinished = false; 

  // --- ТАЙМЕРЫ И ЧЕРНОВИК ---
  DateTime? _sessionStartTime;
  DateTime? _lastAiResponseTime;
  final List<int> _userResponseDurations = [];
  int _elapsedSeconds = 0; 
  bool _hasDraft = false;

  // --- АНАЛИТИКА И ЛОГИ ---
  AnalysisResult? _analysisResult;
  bool _isAnalyzing = false;

  InterviewProvider({required this.repository}) {
    _checkDraft();
  }

  List<MessageEntity> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isFailed => _isFailed;
  bool get isFinished => _isFinished;
  AnalysisResult? get analysisResult => _analysisResult;
  bool get isAnalyzing => _isAnalyzing;
  bool get isLegendPhase => _config?.includeLegend == true && _userLegend.isEmpty && _messages.where((m) => m.isUser).isEmpty;
  SessionConfig? get config => _config;
  bool get hasDraft => _hasDraft;

  String get totalTimeFormatted {
    int currentSessionSeconds = _sessionStartTime != null ? DateTime.now().difference(_sessionStartTime!).inSeconds : 0;
    return "${((_elapsedSeconds + currentSessionSeconds) / 60).floor()}m";
  }

  String get avgResponseFormatted {
    if (_userResponseDurations.isEmpty) return "0s";
    final avg = _userResponseDurations.reduce((a, b) => a + b) / _userResponseDurations.length;
    return "${avg.round()}s";
  }

  void setConfig(SessionConfig config) => _config = config;

  Future<void> _checkDraft() async {
    final prefs = await SharedPreferences.getInstance();
    _hasDraft = prefs.containsKey('draft_messages');
    notifyListeners();
  }

  Future<void> _saveDraft() async {
    if (_messages.length <= 1) return; 
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('draft_messages', jsonEncode(_messages.map((m) => m.toMap()).toList()));
    await prefs.setString('draft_config', jsonEncode(_config!.toMap()));
    await prefs.setString('draft_legend', _userLegend);
    await prefs.setStringList('draft_asked', _askedQuestions);
    await prefs.setBool('draft_is_failed', _isFailed);
    await prefs.setBool('draft_is_finished', _isFinished);
    
    int currentSessionSeconds = _sessionStartTime != null ? DateTime.now().difference(_sessionStartTime!).inSeconds : 0;
    await prefs.setInt('draft_time', _elapsedSeconds + currentSessionSeconds);
    
    _hasDraft = true;
    notifyListeners();
  }

  Future<void> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('draft_messages')) return;
    
    final msgsJson = jsonDecode(prefs.getString('draft_messages')!) as List;
    _messages.clear();
    _messages.addAll(msgsJson.map((m) => MessageEntity.fromMap(m)));

    _config = SessionConfig.fromMap(jsonDecode(prefs.getString('draft_config')!));
    _userLegend = prefs.getString('draft_legend') ?? "";
    _askedQuestions.clear(); _askedQuestions.addAll(prefs.getStringList('draft_asked') ?? []);
    
    _elapsedSeconds = prefs.getInt('draft_time') ?? 0;
    _isFailed = prefs.getBool('draft_is_failed') ?? false;
    _isFinished = prefs.getBool('draft_is_finished') ?? false;
    
    _isLoading = false;
    notifyListeners();
  }

  void pauseTimer() {
    if (_sessionStartTime != null) {
      _elapsedSeconds += DateTime.now().difference(_sessionStartTime!).inSeconds;
      _sessionStartTime = null;
      _saveDraft();
    }
  }

  void resumeTimer() {
    if (_sessionStartTime == null && _messages.isNotEmpty) {
      _sessionStartTime = DateTime.now();
    }
  }

  Future<void> startInterview() async {
    if (_messages.isNotEmpty || _config == null || _isLoading) return;
    
    _isLoading = true; _sessionStartTime = DateTime.now(); notifyListeners();
    try {
      String prompt = _config!.includeLegend 
          ? "[СИСТЕМНОЕ: Поздоровайся, обратившись по имени (${_config!.userName}), представься в своей роли и попроси кандидата коротко рассказать о себе.]"
          : "[СИСТЕМНОЕ: Поздоровайся (${_config!.userName}), представься и сразу задай первый сложный профильный вопрос для роли '${_config!.role}'.]";

      final aiData = await repository.sendMessage(text: prompt, history: [], config: _config!, userLegend: _userLegend, askedQuestions: _askedQuestions);
      _lastAiResponseTime = DateTime.now(); _processAiResponse(aiData.text);
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _config == null || _isLoading) return; 

    if (_lastAiResponseTime != null) _userResponseDurations.add(DateTime.now().difference(_lastAiResponseTime!).inSeconds);
    _messages.add(MessageEntity(text: text, isUser: true, timestamp: DateTime.now()));
    if (_config!.includeLegend && _userLegend.isEmpty) _userLegend = text;
    
    _isLoading = true; notifyListeners(); 

    try {
      int techAnswersCount = _config!.includeLegend ? _messages.where((m) => m.isUser).length - 1 : _messages.where((m) => m.isUser).length;
      String textToSend = text;
      
      // 👇 ЖЕСТКОЕ ПРЕРЫВАНИЕ ПО ЛИМИТУ 👇
      if (!_config!.isEndlessMode && techAnswersCount >= _config!.questionLimit) {
        textToSend = "$text\n\n[СИСТЕМНОЕ АБСОЛЮТНОЕ ПРАВИЛО: ЛИМИТ ВОПРОСОВ ИСЧЕРПАН. Задавать новые вопросы КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО. Оцени этот ответ пользователя, коротко попрощайся с ним и в самом конце сообщения ОБЯЗАТЕЛЬНО добавь тег [END].]";
      }

      final aiData = await repository.sendMessage(text: textToSend, history: _messages.length > 4 ? _messages.sublist(_messages.length - 4) : _messages, config: _config!, userLegend: _userLegend, askedQuestions: _askedQuestions);
      _lastAiResponseTime = DateTime.now(); _processAiResponse(aiData.text);
    } finally {
      _isLoading = false; notifyListeners(); 
    }
  }

 void _processAiResponse(String rawText) {
    if (rawText.contains('[FAIL]')) { rawText = rawText.replaceAll('[FAIL]', '').trim(); _isFailed = true; }
    if (rawText.contains('[END]')) { rawText = rawText.replaceAll('[END]', '').trim(); _isFinished = true; }
    
    // 👇 ЖЕСТКИЙ ПЕРЕХВАТ И ПРИНУДИТЕЛЬНОЕ ЗАВЕРШЕНИЕ 👇
    int techAnswersCount = _config!.includeLegend ? _messages.where((m) => m.isUser).length - 1 : _messages.where((m) => m.isUser).length;
    if (!_config!.isEndlessMode && techAnswersCount >= _config!.questionLimit) {
      _isFinished = true; // Убиваем сессию, даже если ИИ забыл написать [END]
    }

    _askedQuestions.add(rawText);
    _messages.add(MessageEntity(text: rawText, isUser: false, timestamp: DateTime.now()));
    
    speak(rawText); 

    _saveDraft(); 
  }

  Future<void> generateAnalysis({VoidCallback? onSuccess}) async {
    if (_isAnalyzing) return; 
    _isAnalyzing = true; _analysisResult = null; notifyListeners();

    try {
      int userMsgCount = 0;
      String fullChat = _messages.map((m) {
        if (m.isUser) {
          userMsgCount++;
          return "КАНДИДАТ [Ответ $userMsgCount]: ${m.text}";
        } else {
          return "HR: ${m.text}";
        }
      }).join('\n\n');

String analysisPrompt = """Проанализируй транскрипцию собеседования. Верни ответ СТРОГО в формате JSON без markdown. 
      Шаблон: 
      {
        "score": 7.5, 
        "performance_text": "Good", 
        "strengths": ["Пункт 1"], 
        "weaknesses": ["Ошибка 1"],
        "smart_recap": [
          {"topic": "Тема ошибки", "explanation": "Краткое объяснение правильного ответа", "recommendation": "Что почитать"}
        ],
        "evaluations": [
          {"id": 1, "is_water": false, "feedback": "Хороший ответ."}
        ]
      }
      ВАЖНО: Массив 'evaluations' должен содержать ровно $userMsgCount элементов.
      ПРАВИЛО 1 (ДЕТЕКТОР): 'is_water' ставь true, если ответ технически неверный, содержит общие фразы, бред, если кандидат признается, что не знает ответа, или уходит от темы.
      ПРАВИЛО 2 (ШПАРГАЛКИ): В массив 'smart_recap' добавь 1-3 шпаргалки ТОЛЬКО по тем темам, на которые кандидат ответил неправильно или неуверенно. Если ошибок нет - оставь 'smart_recap' пустым.
      ТРАНСКРИПЦИЯ: 
      $fullChat""";

      final aiData = await repository.sendMessage(text: analysisPrompt, history: [], config: _config!, userLegend: _userLegend, askedQuestions: []);
      String rawResponse = aiData.text;
      
      if (rawResponse.contains('⚠️')) throw Exception("Сервер перегружен (503)"); 

      int start = rawResponse.indexOf('{'); int end = rawResponse.lastIndexOf('}');
      if (start != -1 && end != -1) {
        final decodedJson = jsonDecode(rawResponse.substring(start, end + 1));
        _analysisResult = AnalysisResult.fromJson(decodedJson);
        
        final evalList = decodedJson['evaluations'] as List?;
        if (evalList != null) {
          int evalIndex = 0;
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].isUser) {
              if (evalIndex < evalList.length) {
                final eval = evalList[evalIndex];
                _messages[i] = _messages[i].copyWith(
                  isWater: eval['is_water'] ?? false,
                  feedback: eval['feedback'] ?? "Нет комментария.",
                );
                evalIndex++;
              }
            }
          }
          _saveDraft(); 
        }

        onSuccess?.call();
      } else { throw Exception("ИИ не вернул JSON"); }

    } catch (e) {
      _analysisResult = AnalysisResult(score: 0.0, performanceText: "Ошибка анализа", strengths: ["Ошибка: $e"], weaknesses: []);
    } finally {
      _isAnalyzing = false; notifyListeners();
    }
  }

  Future<void> retryLastMessage() async {
    if (_isLoading || _messages.isEmpty) return;
    if (!_messages.last.isUser && _messages.last.text.contains('⚠️')) {
      _messages.removeLast(); 
      if (_messages.isEmpty) { notifyListeners(); await startInterview(); return; }
      if (_messages.last.isUser) {
        String textToRetry = _messages.last.text; _messages.removeLast(); await sendMessage(textToRetry); 
      } else { notifyListeners(); }
    }
  }

  Future<void> clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_messages'); await prefs.remove('draft_config'); await prefs.remove('draft_legend'); await prefs.remove('draft_asked'); await prefs.remove('draft_time');
    
    _messages.clear(); _isFailed = false; _isFinished = false; _userLegend = ""; _askedQuestions.clear(); _hasDraft = false;
    _analysisResult = null; _isAnalyzing = false; _elapsedSeconds = 0; _sessionStartTime = null; _lastAiResponseTime = null;
    notifyListeners();
  }



// --- ЗВУК И ОЗВУЧКА ---
  final FlutterTts _tts = FlutterTts();
  bool _isVoiceEnabled = true; // Глобальный рубильник звука
  String? _currentlyPlayingText; // Отслеживаем, какой текст сейчас читается

  bool get isVoiceEnabled => _isVoiceEnabled;
  String? get currentlyPlayingText => _currentlyPlayingText;


void loadSessionFromHistory(SessionHistory session) {
    _config = session.config;
    _messages.clear();
    _messages.addAll(session.messages);
    _isFinished = session.isFinished;
    _isFailed = session.isFailed;
    _analysisResult = session.analysisResult;
    _hasDraft = false;
    notifyListeners();
  }



  void toggleVoice() {
    _isVoiceEnabled = !_isVoiceEnabled;
    if (!_isVoiceEnabled) {
      _tts.stop();
      _currentlyPlayingText = null;
    }
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (!_isVoiceEnabled) return;

    // Если нажали на ту же кнопку, текст которой сейчас играет — останавливаем
    if (_currentlyPlayingText == text) {
      await _tts.stop();
      _currentlyPlayingText = null;
      notifyListeners();
      return;
    }

    // Слушатель завершения (чтобы кнопка сама "отжалась", когда ИИ договорит)
    _tts.setCompletionHandler(() {
      _currentlyPlayingText = null;
      notifyListeners();
    });

    // Останавливаем старый текст, если он был, и запускаем новый
    await _tts.stop();
    _currentlyPlayingText = text;
    notifyListeners();

    await _tts.setLanguage("ru-RU");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(1.0); // 👈 Нормальная скорость! (было 0.5)
    await _tts.speak(text);
  }


  Future<Map<String, dynamic>> startSession(SessionConfig config) async {
    return await repository.startSession(config);
  }
}