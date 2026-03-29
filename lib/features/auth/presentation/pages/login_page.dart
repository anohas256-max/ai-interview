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
  // 👇 ДОБАВИЛИ КЛЮЧ ФОРМЫ И ФЛАГ 👇
  final _formKey = GlobalKey<FormState>();
  bool _hasSubmitted = false;

  final usernameController = TextEditingController(); 
  final passwordController = TextEditingController();

  // Добавили очистку старых ошибок при входе
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().clearError();
    });
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus(); 
    
    // 👇 ГОВОРИМ ФОРМЕ "КНОПКА НАЖАТА, ПРОВЕРЯЙ!" 👇
    setState(() {
      _hasSubmitted = true;
    });

    if (!_formKey.currentState!.validate()) return; // Останавливаем, если пусто

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

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
          // 👇 ОБЕРНУЛИ В FORM 👇
          child: Form(
            key: _formKey,
            autovalidateMode: _hasSubmitted ? AutovalidateMode.always : AutovalidateMode.disabled,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
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

                // 👇 ТЕПЕРЬ ОНИ РУГАЮТСЯ НА ПУСТОТУ 👇
                _buildTextField(
                  label: "Логин", 
                  icon: Icons.person_outline, 
                  controller: usernameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return "Введите логин";
                    return null;
                  }
                ),
                const Gap(16),
                _buildTextField(
                  label: "Пароль", 
                  icon: Icons.lock_outline, 
                  isPassword: true, 
                  controller: passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Введите пароль";
                    return null;
                  }
                ),

                const Gap(32),

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

                const Gap(16),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpPage()), 
                    );
                  },
                  child: const Text(
                    "Нет аккаунта? Зарегистрироваться", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), 
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 👇 ПЕРЕДЕЛАЛИ В TextFormField 👇
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    String? Function(String?)? validator, // Добавили параметр валидатора
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      validator: validator, // Подключили валидатор
      onChanged: (value) => context.read<AuthProvider>().clearError(), // Сброс ошибки при вводе
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
        // Добавили красные рамки для ошибок:
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1)
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1)
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
    );
  }
}