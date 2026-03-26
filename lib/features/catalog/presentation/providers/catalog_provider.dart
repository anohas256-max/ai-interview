import 'package:flutter/material.dart';
import '../../data/datasources/django_api_source.dart';
import '../../domain/entities/template_entity.dart';

class CatalogProvider extends ChangeNotifier {
  final DjangoApiSource apiSource = DjangoApiSource();
  
  List<TemplateEntity> templates = [];
  bool isLoading = false;

  CatalogProvider() {
    loadTemplates();
  }

  // 👇 СПИСКИ ДЛЯ ВЫПАДАЮЩИХ МЕНЮ 👇
  // Берем только те, где mode == 'roleplay', и вытаскиваем только их названия
  List<String> get interviewRoles {
    final roles = templates.where((t) => t.mode == 'roleplay').map((t) => t.title).toList();
    return roles.isNotEmpty ? roles : ['Загрузка...'];
  }

  // Берем только те, где mode == 'quiz'
  List<String> get quizTopics {
    final topics = templates.where((t) => t.mode == 'quiz').map((t) => t.title).toList();
    return topics.isNotEmpty ? topics : ['Загрузка...'];
  }

  Future<void> loadTemplates() async {
    isLoading = true;
    notifyListeners();

    templates = await apiSource.getTemplates();

    isLoading = false;
    notifyListeners();
  }
}