import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Берем ключ из .env. Если вдруг файла нет — вернем пустую строку, чтобы приложение не упало с ошибкой
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? ''; 
}