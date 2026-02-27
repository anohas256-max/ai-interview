import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Импорт для .env

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

// Импортируем классы связи с ИИ
import 'features/interview/data/datasources/gemini_api_source.dart';
import 'features/interview/data/repositories/interview_repo_impl.dart';
import 'features/interview/presentation/providers/interview_provider.dart';

import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/history/presentation/providers/history_provider.dart';

// 👇 Делаем main асинхронным, добавив "Future<void>" и "async"
Future<void> main() async {
  // 1. Обязательная строчка перед запуском асинхронного кода во Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Загружаем наш секретный файл .env
  await dotenv.load(fileName: ".env");

  // 3. Создаем телефон с ключом
  final apiSource = GeminiApiSource();
  
  // 4. Нанимаем курьера и даем ему телефон
  final repository = InterviewRepoImpl(apiSource: apiSource);

  runApp(
    // 5. Подключаем пульты ко всему приложению
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InterviewProvider(repository: repository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Interview',
      theme: AppTheme.darkTheme,
      home: const HomePage(), // Запускаем с главного экрана
    );
  }
}