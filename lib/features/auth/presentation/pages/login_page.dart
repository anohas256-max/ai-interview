import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/pages/home_page.dart'; // Импорт следующего экрана

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Контроллеры для текста (пока просто чтобы были)
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground, // Черный фон
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Логотип / Иконка
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.terminal, color: Colors.white, size: 32),
              ),
              const Gap(24),

              // 2. Заголовки
              Text(
                "Welcome back",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Gap(8),
              const Text(
                "Sign in to continue your interview training.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const Gap(48),

              // 3. Поля ввода
              _buildTextField(label: "Email", icon: Icons.email_outlined, controller: emailController),
              const Gap(16),
              _buildTextField(label: "Password", icon: Icons.lock_outline, isPassword: true, controller: passwordController),

              const Gap(32),

              // 4. Кнопка Входа
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // ЗАГЛУШКА: Имитируем успешный вход
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              const Spacer(),

              // 5. Футер
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Вспомогательный метод для полей ввода (чтобы код был чище)
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1A1A), // Темно-серый фон поля
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
      ),
    );
  }
}