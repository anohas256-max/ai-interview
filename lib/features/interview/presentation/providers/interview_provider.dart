import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/session_config.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/interview_repository.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:sobes/features/history/domain/entities/session_history.dart';
import 'package:sobes/features/catalog/data/datasources/django_api_source.dart';

class InterviewProvider extends ChangeNotifier {
  final InterviewRepository repository;

  final List<MessageEntity> _messages = [];
  SessionConfig? _config;
  String _userLegend = "";
  final List<String> _askedQuestions = [];

  bool _isLoading = false;
  bool _isFailed = false;
  bool _isFinished = false;

  // --- ЭТАП 3: ID СЕССИИ ДЛЯ АВТОСОХРАНЕНИЯ ---
  int? _currentSessionId;

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
  bool get isLegendPhase =>
      _config?.includeLegend == true &&
      _userLegend.isEmpty &&
      _messages.where((m) => m.isUser).isEmpty;
  SessionConfig? get config => _config;
  bool get hasDraft => _hasDraft;

  String get totalTimeFormatted {
    int currentSessionSeconds = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;
    return "${((_elapsedSeconds + currentSessionSeconds) / 60).floor()}m";
  }

  String get avgResponseFormatted {
    if (_userResponseDurations.isEmpty) return "0s";
    final avg =
        _userResponseDurations.reduce((a, b) => a + b) / _userResponseDurations.length;
    return "${avg.round()}s";
  }

  // 👇 ОБНОВЛЕННЫЙ SETCONFIG 👇
  void setConfig(SessionConfig config) {
    _config = config;
    _currentSessionId = null; // Сбрасываем старый ID при новой настройке
    notifyListeners();
  }

  // 👇 ОБНОВЛЕННЫЙ STARTSESSION (Сохраняем ID из ответа сервера) 👇
  Future<Map<String, dynamic>> startSession(SessionConfig config) async {
    final result = await repository.startSession(config);
    if (result['success'] == true) {
      _currentSessionId = result['session_id'];
    }
    return result;
  }

  Future<void> _checkDraft() async {
    final prefs = await SharedPreferences.getInstance();
    _hasDraft = prefs.containsKey('draft_messages');
    notifyListeners();
  }

  Future<void> _saveDraft() async {
    if (_messages.length <= 1 || _config == null) return;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
        'draft_messages', jsonEncode(_messages.map((m) => m.toMap()).toList()));
    await prefs.setString('draft_config', jsonEncode(_config!.toMap()));
    await prefs.setString('draft_legend', _userLegend);
    await prefs.setStringList('draft_asked', _askedQuestions);
    await prefs.setBool('draft_is_failed', _isFailed);
    await prefs.setBool('draft_is_finished', _isFinished);

    int currentSessionSeconds = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;
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
    _askedQuestions.clear();
    _askedQuestions.addAll(prefs.getStringList('draft_asked') ?? []);

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

  // 👇 ОБНОВЛЕННЫЙ STARTINTERVIEW (Передаем ID) 👇
  Future<void> startInterview() async {
    if (_messages.isNotEmpty || _config == null || _isLoading) return;

    _isLoading = true;
    _sessionStartTime = DateTime.now();
    notifyListeners();
    try {
      // 🛑 Отправляем чистую команду Джанго. В историю это НЕ запишется!
      final aiData = await repository.sendMessage(
        text: "START_INTERVIEW", 
        history: [],
        config: _config!,
        userLegend: _userLegend,
        askedQuestions: _askedQuestions,
        sessionId: _currentSessionId ?? 0,
      );
      _lastAiResponseTime = DateTime.now();
      _processAiResponse(aiData.text);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _config == null || _isLoading) return;

    if (_lastAiResponseTime != null)
      _userResponseDurations.add(DateTime.now().difference(_lastAiResponseTime!).inSeconds);
    _messages.add(MessageEntity(text: text, isUser: true, timestamp: DateTime.now()));
    if (_config!.includeLegend && _userLegend.isEmpty) _userLegend = text;

    _isLoading = true;
    notifyListeners();

    try {
      int techAnswersCount = _config!.includeLegend
          ? _messages.where((m) => m.isUser).length - 1
          : _messages.where((m) => m.isUser).length;

      // 🛑 Вычисляем флаг лимита
      bool limitReached = !_config!.isEndlessMode && techAnswersCount >= _config!.questionLimit;

      final aiData = await repository.sendMessage(
        text: text, // 👈 ШЛЕМ ТОЛЬКО ЧИСТЫЙ ТЕКСТ ЮЗЕРА! НИКАКИХ ПРИПИСОК!
        history: _messages.length > 4 ? _messages.sublist(_messages.length - 4) : _messages,
        config: _config!,
        userLegend: _userLegend,
        askedQuestions: _askedQuestions,
        sessionId: _currentSessionId ?? 0,
        isLimitReached: limitReached, // 👈 ПЕРЕДАЕМ ФЛАГ ДЖАНГО
      );
      _lastAiResponseTime = DateTime.now();
      _processAiResponse(aiData.text);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processAiResponse(String rawText) {
    if (rawText.contains('[FAIL]')) {
      rawText = rawText.replaceAll('[FAIL]', '').trim();
      _isFailed = true;
    }
    if (rawText.contains('[END]')) {
      rawText = rawText.replaceAll('[END]', '').trim();
      _isFinished = true;
    }

    int techAnswersCount = _config!.includeLegend
        ? _messages.where((m) => m.isUser).length - 1
        : _messages.where((m) => m.isUser).length;
    if (!_config!.isEndlessMode && techAnswersCount >= _config!.questionLimit) {
      _isFinished = true;
    }

    _askedQuestions.add(rawText);
    _messages.add(MessageEntity(text: rawText, isUser: false, timestamp: DateTime.now()));

    speak(rawText);
    _saveDraft();
  }

  Future<void> generateAnalysis({VoidCallback? onSuccess}) async {
    if (_isAnalyzing) return;
    _isAnalyzing = true;
    _analysisResult = null;
    notifyListeners();

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

     String analysisPrompt = """Проанализируй транскрипцию собеседования. Верни ответ СТРОГО в формате JSON. Никакого текста до или после. Никаких маркдаун-блоков вроде ```json. Только чистый JSON-объект.
      Шаблон: 
      {
        "score": 7.5, 
        "performance_text": "Good", 
        "strengths": ["Пункт 1"], 
        "weaknesses": ["Ошибка 1"],
        "smart_recap": [
          {"topic": "Тема", "explanation": "Объяснение", "recommendation": "Что читать"}
        ],
        "evaluations": [
          {"id": 1, "is_water": false, "feedback": "Текст."}
        ]
      }
      ВАЖНО: Массив 'evaluations' должен содержать ровно $userMsgCount элементов.
      ТРАНСКРИПЦИЯ: 
      $fullChat""";

      final aiData = await repository.sendMessage(
        text: analysisPrompt,
        history: [],
        config: _config!,
        userLegend: _userLegend,
        askedQuestions: [],
        sessionId: _currentSessionId ?? 0,
        isAnalysis: true, 
      );
      String rawResponse = aiData.text;

      if (rawResponse.contains('⚠️')) throw Exception("Сервер перегружен (503)");

      int start = rawResponse.indexOf('{');
      int end = rawResponse.lastIndexOf('}');
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
      } else {
        throw Exception("ИИ не вернул JSON");
      }
    } catch (e) {
      _analysisResult = AnalysisResult(
          score: 0.0,
          performanceText: "Ошибка анализа",
          strengths: ["Ошибка: $e"],
          weaknesses: []);
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> retryLastMessage() async {
    if (_isLoading || _messages.isEmpty) return;
    if (!_messages.last.isUser && _messages.last.text.contains('⚠️')) {
      _messages.removeLast();
      if (_messages.isEmpty) {
        notifyListeners();
        await startInterview();
        return;
      }
      if (_messages.last.isUser) {
        String textToRetry = _messages.last.text;
        _messages.removeLast();
        await sendMessage(textToRetry);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> clearChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_messages');
    await prefs.remove('draft_config');
    await prefs.remove('draft_legend');
    await prefs.remove('draft_asked');
    await prefs.remove('draft_time');

    _messages.clear();
    _isFailed = false;
    _isFinished = false;
    _userLegend = "";
    _askedQuestions.clear();
    _hasDraft = false;
    _analysisResult = null;
    _isAnalyzing = false;
    _elapsedSeconds = 0;
    _sessionStartTime = null;
    _lastAiResponseTime = null;
    _currentSessionId = null; // Чистим ID сессии
    notifyListeners();
  }

  // --- ЗВУК И ОЗВУЧКА ---
  final FlutterTts _tts = FlutterTts();
  bool _isVoiceEnabled = true;
  String? _currentlyPlayingText;

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
    _currentSessionId = session.id is int ? session.id as int : null; // Подхватываем ID из истории
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
    if (_currentlyPlayingText == text) {
      await _tts.stop();
      _currentlyPlayingText = null;
      notifyListeners();
      return;
    }
    _tts.setCompletionHandler(() {
      _currentlyPlayingText = null;
      notifyListeners();
    });
    await _tts.stop();
    _currentlyPlayingText = text;
    notifyListeners();

    await _tts.setLanguage("ru-RU");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(1.0);
    await _tts.speak(text);
  }
}