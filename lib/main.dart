import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart'; 
// 👇 Подключили провайдер настроек
import 'core/providers/settings_provider.dart';

import 'features/home/presentation/pages/home_page.dart';
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
    // 👇 Слушаем настройки темы
    final themeMode = context.watch<SettingsProvider>().themeMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Interview',
      themeMode: themeMode, // 👈 Теперь тема динамическая
      theme: ThemeData.light(), // Если нет светлой темы, Flutter подставит стандартную
      darkTheme: AppTheme.darkTheme,
      
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isAuthenticated) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ), 
    );
  }
}