import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/session_history.dart';
import '../../../catalog/data/datasources/django_api_source.dart'; // 👈 Добавили API

class HistoryProvider extends ChangeNotifier {
  List<SessionHistory> _sessions = [];
  List<SessionHistory> get sessions => _sessions;
  
  final DjangoApiSource apiSource = DjangoApiSource();
  bool isLoading = false;

  HistoryProvider() {
    loadHistory();
  }

  // 👇 УМНАЯ ЗАГРУЗКА 👇
  Future<void> loadHistory() async {
    isLoading = true;
    notifyListeners();

    // 1. Сначала показываем то, что есть в кэше (чтобы юзер не ждал)
    await _loadFromLocalCache();

    // 2. Пытаемся стянуть свежак с сервера
    final serverSessions = await apiSource.getSessionHistory();
    
    if (serverSessions.isNotEmpty) {
      _sessions = serverSessions;
      _sessions.sort((a, b) => b.date.compareTo(a.date));
      // Синхронизируем локальный кэш с сервером
      await _saveToLocalCache(); 
      notifyListeners();
    }

    isLoading = false;
    notifyListeners();
  }

  // 👇 УМНОЕ СОХРАНЕНИЕ 👇
  Future<void> saveSession(SessionHistory session) async {
    // 1. Сначала оптимистично добавляем/обновляем в локальном списке (чтобы UI моргнул мгновенно)
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
    } else {
      _sessions.insert(0, session);
    }
    notifyListeners();

    // 2. Пытаемся отправить на сервер
    final savedServerSession = await apiSource.saveSessionHistory(session);

    if (savedServerSession != null) {
      // Если сервер успешно сохранил и вернул нам сессию (с новым ID из базы)
      // Мы заменяем нашу локальную сессию на серверную
      final updateIndex = _sessions.indexWhere((s) => s.id == session.id);
      if (updateIndex != -1) {
        _sessions[updateIndex] = savedServerSession;
      }
    }

    // 3. Обновляем локальный кэш
    await _saveToLocalCache();
    notifyListeners();
  }

  // --- Вспомогательные приватные методы ---

  Future<void> _loadFromLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historyJson = prefs.getStringList('interview_history');
    
    if (historyJson != null) {
      _sessions = historyJson.map((jsonStr) => SessionHistory.fromJson(jsonStr)).toList();
      _sessions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  Future<void> _saveToLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyJson = _sessions.map((s) => s.toJson()).toList();
    await prefs.setStringList('interview_history', historyJson);
  }
}