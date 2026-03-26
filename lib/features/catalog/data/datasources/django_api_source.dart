import 'package:dio/dio.dart';
import '../../domain/entities/template_entity.dart';

class DjangoApiSource {
  final Dio _dio = Dio();
  
  // ⚠️ ВАЖНО: 10.0.2.2 - это спец. адрес, чтобы Android Эмулятор видел localhost твоего компа. 
  // Если тестируешь в Web/Windows - ставь 'http://127.0.0.1:8000/api'
 final String baseUrl = 'http://127.0.0.1:8000/api';

  Future<List<TemplateEntity>> getTemplates() async {
    try {
      final response = await _dio.get('$baseUrl/templates/');
      
      // Наш Django возвращает пагинацию, поэтому данные лежат в ключе "results"
      final List<dynamic> results = response.data['results'];
      
      return results.map((json) => TemplateEntity.fromJson(json)).toList();
    } catch (e) {
      print("Ошибка загрузки шаблонов из Django: $e");
      return [];
    }
  }
}