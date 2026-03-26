import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart'; 
import 'features/home/presentation/pages/home_page.dart';
// 👇 ДОБАВИЛИ ДВА ИМПОРТА 👇
import 'features/auth/presentation/pages/login_page.dart'; 
import 'features/auth/presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: AppProviders.getGlobalProviders(),
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
      
      // 👇 УМНЫЙ ЗАПУСК: Слушаем статус авторизации 👇
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Если пропуск (токен) есть -> летим на Главную
          if (authProvider.isAuthenticated) {
            return const HomePage();
          } 
          // Если пропуска нет -> показываем окно Входа
          else {
            return const LoginPage();
          }
        },
      ), 
    );
  }
}