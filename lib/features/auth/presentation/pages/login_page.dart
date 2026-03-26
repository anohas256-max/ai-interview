import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart'; 
import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/pages/home_page.dart';
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart'; 
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController(); 
  final passwordController = TextEditingController();

  void _handleLogin() async {
    FocusScope.of(context).unfocus(); 
    
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.login(username, password);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Растягиваем по ширине
            children: [
              // Логотип
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.terminal, color: Colors.white, size: 32),
                ),
              ),
              const Gap(24),

              // Заголовки (На русском)
              Text(
                "С возвращением",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Gap(8),
              const Text(
                "Войдите, чтобы продолжить тренировки.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const Gap(48),

              // Блок ошибки
              if (authProvider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Text(
                    authProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                const Gap(16),
              ],

              // Поля ввода (На русском)
              _buildTextField(label: "Логин", icon: Icons.person_outline, controller: usernameController),
              const Gap(16),
              _buildTextField(label: "Пароль", icon: Icons.lock_outline, isPassword: true, controller: passwordController),

              const Gap(32),

              // Кнопка Входа
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleLogin, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey[800], 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("Войти", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              const Gap(16), // 👈 Небольшой отступ вместо Spacer

              // Кнопка Регистрации (Сделали ярче и на русском)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()), 
                  );
                },
                child: const Text(
                  "Нет аккаунта? Зарегистрироваться", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), // 👈 Сделали белым и жирным
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        fillColor: const Color(0xFF1A1A1A),
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