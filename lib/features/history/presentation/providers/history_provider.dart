import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/session_history.dart';

class HistoryProvider extends ChangeNotifier {
  List<SessionHistory> _sessions = [];
  List<SessionHistory> get sessions => _sessions;

  // При создании пульта сразу пытаемся загрузить историю
  HistoryProvider() {
    loadHistory();
  }

  // ЗАГРУЗКА ИЗ ПАМЯТИ
  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historyJson = prefs.getStringList('interview_history');
    
    if (historyJson != null) {
      _sessions = historyJson.map((jsonStr) => SessionHistory.fromJson(jsonStr)).toList();
      // Сортируем от новых (сверху) к старым (снизу)
      _sessions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  // СОХРАНЕНИЕ НОВОЙ СЕССИИ
  Future<void> saveSession(SessionHistory session) async {
    _sessions.insert(0, session); // Добавляем новую сессию в самое начало списка
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    // Превращаем весь список обратно в текст и сохраняем
    final List<String> historyJson = _sessions.map((s) => s.toJson()).toList();
    await prefs.setStringList('interview_history', historyJson);
  }
}