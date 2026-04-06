import 'package:flutter/material.dart';
import '../../data/datasources/django_api_source.dart';
import '../../domain/entities/template_entity.dart';

class CatalogProvider extends ChangeNotifier {
  final DjangoApiSource apiSource = DjangoApiSource();
  
  List<TemplateEntity> templates = [];
  bool isLoading = false;
  String _currentLang = ''; // Храним текущий язык

  // 👇 ДОБАВИЛИ КЛЮЧ СЮДА ЖЕ 👇
  final String customOptRu = 'Свой вариант ✍️';
  final String customOptEn = 'Custom ✍️';

  CatalogProvider() {
    loadTemplates('Русский'); // Грузим при старте
  }

  List<String> get interviewRoles {
    final roles = templates.where((t) => t.mode == 'roleplay').map((t) => t.title).toList();
    return roles.isNotEmpty ? roles : ['Loading...'];
  }

  List<String> get quizTopics {
    final topics = templates.where((t) => t.mode == 'quiz').map((t) => t.title).toList();
    return topics.isNotEmpty ? topics : ['Loading...'];
  }

  // 👇 Умная загрузка (скачивает заново, только если язык реально изменился) 👇
  Future<void> updateLanguage(String language) async {
    if (_currentLang == language) return;
    _currentLang = language;
    await loadTemplates(language);
  }

  Future<void> loadTemplates(String language) async {
    isLoading = true;
    notifyListeners();

    templates = await apiSource.getTemplates(language);

    isLoading = false;
    notifyListeners();
  }
}