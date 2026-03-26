import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Теперь берем ключ от Опенроутера
  static String get openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? ''; 
}