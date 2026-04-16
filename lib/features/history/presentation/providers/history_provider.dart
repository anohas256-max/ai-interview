import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/session_history.dart';
import '../../../catalog/data/datasources/django_api_source.dart';

// Перечисление для сортировки
enum HistorySortType { dateDesc, dateAsc, scoreDesc }
// Перечисление для фильтров
enum HistoryFilterType { all, finished, unfinished }

class HistoryProvider extends ChangeNotifier {
  List<SessionHistory> _sessions = [];
  List<SessionHistory> get sessions => _getFilteredAndSortedSessions(); // 👈 Выдаем отфильтрованный список
  
  final DjangoApiSource apiSource = DjangoApiSource();
  bool isLoading = false;

  // Текущие фильтры
  HistorySortType currentSort = HistorySortType.dateDesc;
  HistoryFilterType currentFilter = HistoryFilterType.all;

  HistoryProvider() {
    loadHistory();
  }

  // 👇 ПРИМЕНЯЕМ СОРТИРОВКУ И ФИЛЬТР 👇
  List<SessionHistory> _getFilteredAndSortedSessions() {
    List<SessionHistory> result = List.from(_sessions);

    // 1. Фильтруем
    if (currentFilter == HistoryFilterType.finished) {
      result.retainWhere((s) => s.isFinished);
    } else if (currentFilter == HistoryFilterType.unfinished) {
      result.retainWhere((s) => !s.isFinished);
    }

    // 2. Сортируем
    if (currentSort == HistorySortType.dateDesc) {
      result.sort((a, b) => b.date.compareTo(a.date)); // Сначала новые
    } else if (currentSort == HistorySortType.dateAsc) {
      result.sort((a, b) => a.date.compareTo(b.date)); // Сначала старые
    } else if (currentSort == HistorySortType.scoreDesc) {
      result.sort((a, b) => b.score.compareTo(a.score)); // Сначала высокий балл
    }

    return result;
  }

  void setSort(HistorySortType sortType) {
    currentSort = sortType;
    notifyListeners();
  }

  void setFilter(HistoryFilterType filterType) {
    currentFilter = filterType;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    isLoading = true;
    notifyListeners();

    await _loadFromLocalCache();

    final serverSessions = await apiSource.getSessionHistory();
    
    if (serverSessions.isNotEmpty) {
      _sessions = serverSessions;
      await _saveToLocalCache(); 
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> saveSession(SessionHistory session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
    } else {
      _sessions.insert(0, session);
    }
    notifyListeners();

    final savedServerSession = await apiSource.saveSessionHistory(session);

    if (savedServerSession != null) {
      final updateIndex = _sessions.indexWhere((s) => s.id == session.id);
      if (updateIndex != -1) {
        _sessions[updateIndex] = savedServerSession;
      }
    }

    await _saveToLocalCache();
    notifyListeners();
  }

  // 👇 ПЕРЕИМЕНОВАНИЕ СЕССИИ 👇
  Future<void> renameSession(SessionHistory session, String newName) async {
    final updatedSession = session.copyWith(customName: newName);
    await saveSession(updatedSession); // Сохраняем локально и пушим в Джанго
  }

  // 👇 УДАЛЕНИЕ 1 СЕССИИ 👇
  Future<void> deleteSession(dynamic sessionId) async {
    // Оптимистичное удаление из UI
    _sessions.removeWhere((s) => s.id == sessionId);
    notifyListeners();
    await _saveToLocalCache();

    // Удаляем с сервера
    await apiSource.deleteSessionHistory(sessionId);
  }

  // 👇 УДАЛЕНИЕ ВСЕЙ ИСТОРИИ 👇
  Future<void> clearAllHistoryFromDB() async {
    final idsToDelete = _sessions.map((s) => s.id).toList();
    _sessions.clear();
    notifyListeners();
    await _saveToLocalCache();

    await apiSource.clearAllHistory(idsToDelete);
  }

  Future<void> _loadFromLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? historyJson = prefs.getStringList('interview_history');
    if (historyJson != null) {
      _sessions = historyJson.map((jsonStr) => SessionHistory.fromJson(jsonStr)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveToLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historyJson = _sessions.map((s) => s.toJson()).toList();
    await prefs.setStringList('interview_history', historyJson);
  }

  void clear() {
    _sessions.clear();
    notifyListeners();
  }
}