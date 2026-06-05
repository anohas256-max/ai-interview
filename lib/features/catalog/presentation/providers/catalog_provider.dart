import 'package:flutter/material.dart';

import '../../data/datasources/django_api_source.dart';
import '../../domain/entities/template_entity.dart';

class CatalogProvider extends ChangeNotifier {
  final DjangoApiSource apiSource = DjangoApiSource();

  List<TemplateEntity> templates = [];

  List<Map<String, dynamic>> customRoleplayPresetItems = [];
  List<Map<String, dynamic>> customQuizPresetItems = [];

  bool isLoading = false;
  String _currentLang = '';

  CatalogProvider() {
    loadTemplates('Русский');
    loadCustomPresets();
  }

  List<String> get customRoleplayPresets {
    return customRoleplayPresetItems
        .map((item) => item['title']?.toString() ?? '')
        .where((title) => title.trim().isNotEmpty)
        .toList();
  }

  List<String> get customQuizPresets {
    return customQuizPresetItems
        .map((item) => item['title']?.toString() ?? '')
        .where((title) => title.trim().isNotEmpty)
        .toList();
  }

  List<String> get interviewRoles {
    final roles = templates
        .where((t) => t.mode == 'roleplay')
        .map((t) => t.title)
        .toList();

    final result = [
      ...roles,
      ...customRoleplayPresets,
    ];

    return result.isNotEmpty ? result : ['Loading...'];
  }

  List<String> get quizTopics {
    final topics = templates
        .where((t) => t.mode == 'quiz')
        .map((t) => t.title)
        .toList();

    final result = [
      ...topics,
      ...customQuizPresets,
    ];

    return result.isNotEmpty ? result : ['Loading...'];
  }

  bool isCustomRoleplayPreset(String title) {
    return customRoleplayPresets.any(
      (item) => item.toLowerCase() == title.toLowerCase(),
    );
  }

  bool isCustomQuizPreset(String title) {
    return customQuizPresets.any(
      (item) => item.toLowerCase() == title.toLowerCase(),
    );
  }

  int? _findCustomPresetId({
    required String mode,
    required String title,
  }) {
    final list = mode == 'roleplay'
        ? customRoleplayPresetItems
        : customQuizPresetItems;

    for (final item in list) {
      final itemTitle = item['title']?.toString() ?? '';

      if (itemTitle.toLowerCase() == title.toLowerCase()) {
        final rawId = item['id'];

        if (rawId is int) return rawId;
        return int.tryParse(rawId.toString());
      }
    }

    return null;
  }

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

  Future<void> loadCustomPresets() async {
    final roleplay = await apiSource.getCustomPresets('roleplay');
    final quiz = await apiSource.getCustomPresets('quiz');

    customRoleplayPresetItems = roleplay;
    customQuizPresetItems = quiz;

    notifyListeners();
  }

  Future<bool> saveCustomRoleplayPreset(String title) async {
    final normalized = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 2) return false;

    final result = await apiSource.createCustomPreset(
      mode: 'roleplay',
      title: normalized,
    );

    if (result == null) return false;

    await loadCustomPresets();
    return true;
  }

  Future<bool> saveCustomQuizPreset(String title) async {
    final normalized = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 2) return false;

    final result = await apiSource.createCustomPreset(
      mode: 'quiz',
      title: normalized,
    );

    if (result == null) return false;

    await loadCustomPresets();
    return true;
  }

  Future<bool> deleteCustomRoleplayPreset(String title) async {
    final id = _findCustomPresetId(
      mode: 'roleplay',
      title: title,
    );

    if (id == null) return false;

    final ok = await apiSource.deleteCustomPreset(id);

    if (ok) {
      await loadCustomPresets();
    }

    return ok;
  }

  Future<bool> deleteCustomQuizPreset(String title) async {
    final id = _findCustomPresetId(
      mode: 'quiz',
      title: title,
    );

    if (id == null) return false;

    final ok = await apiSource.deleteCustomPreset(id);

    if (ok) {
      await loadCustomPresets();
    }

    return ok;
  }
}