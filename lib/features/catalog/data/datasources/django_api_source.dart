import 'package:dio/dio.dart';
import '../../domain/entities/template_entity.dart';

class DjangoApiSource {
  final Dio _dio = Dio();
  
  final String baseUrl = 'http://127.0.0.1:8000/api';

  // 👇 Принимаем язык 👇
  Future<List<TemplateEntity>> getTemplates(String language) async {
    try {
      // Превращаем 'English' в 'en'
      final langCode = language == 'English' ? 'en' : 'ru';
      
      // 👇 Отправляем язык в Джанго 👇
      final response = await _dio.get('$baseUrl/templates/?lang=$langCode');
      
      final List<dynamic> results = response.data['results'];
      
      return results.map((json) => TemplateEntity.fromJson(json)).toList();
    } catch (e) {
      print("Ошибка загрузки шаблонов из Django: $e");
      return [];
    }
  }
}