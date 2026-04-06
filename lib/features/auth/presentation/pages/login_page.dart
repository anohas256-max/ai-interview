import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart'; 
import '../../../home/presentation/pages/home_page.dart';
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart'; 
import 'package:sobes/core/providers/settings_provider.dart'; // 👈 Провайдер настроек
import 'sign_up_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _hasSubmitted = false;
  final usernameController = TextEditingController(); 
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().clearError();
    });
  }

  void _handleLogin() async {
    FocusScope.of(context).unfocus(); 
    setState(() => _hasSubmitted = true);
    if (!_formKey.currentState!.validate()) return;

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.login(username, password);
    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>(); // 👈 Настройки (Тема и Язык)
    final textColor = Theme.of(context).textTheme.bodyLarge?.color; // Адаптивный цвет текста

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Адаптивный фон
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.terminal, color: textColor, size: 32),
                  ),
                ),
                const Gap(24),
                Text(
                  settings.t('login_title'), // 👈 Перевод
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor),
                ),
                const Gap(8),
                Text(settings.t('login_subtitle'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const Gap(48),

                if (authProvider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.5))),
                    child: Text(authProvider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                  const Gap(16),
                ],

                _buildTextField(
                  label: settings.t('login'), 
                  icon: Icons.person_outline, 
                  controller: usernameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return settings.t('empty_login');
                    return null;
                  }
                ),
                const Gap(16),
                _buildTextField(
                  label: settings.t('password_hint'), 
                  icon: Icons.lock_outline, 
                  isPassword: true, 
                  controller: passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return settings.t('empty_pass');
                    return null;
                  }
                ),
                const Gap(32),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin, 
                    // Стиль кнопки берется из AppTheme автоматически!
                    child: authProvider.isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(settings.t('sign_in_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const Gap(16),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage())),
                  child: Text(settings.t('no_account'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required IconData icon, required TextEditingController controller, bool isPassword = false, String? Function(String?)? validator}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: textColor), // Адаптивный цвет
      validator: validator, 
      onChanged: (value) => context.read<AuthProvider>().clearError(), 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Theme.of(context).cardColor, // Адаптивный цвет поля
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textColor ?? Colors.white, width: 1)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
    );
  }
}