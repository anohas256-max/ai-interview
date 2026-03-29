import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../providers/auth_provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>(); 
  bool _hasSubmitted = false; 

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // 👇 ПЕРЕМЕННЫЕ ДЛЯ ТАЙМЕРОВ 👇
  Timer? _debounce;
  String? _usernameError;
  
  Timer? _debounceEmail;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    // Сбрасываем старые ошибки при входе на экран
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); 
    _debounceEmail?.cancel(); // 👈 Не забываем убивать таймер почты
    super.dispose();
  }

  // --- ЛОГИКА УМНОЙ ПРОВЕРКИ ИМЕНИ ---
  void _onUsernameChanged(String value) {
    context.read<AuthProvider>().clearError();
    
    if (_usernameError != null) {
      setState(() => _usernameError = null);
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      if (value.trim().length >= 3) {
        final isTaken = await context.read<AuthProvider>().isUsernameTaken(value.trim());
        if (isTaken && mounted) {
          setState(() {
            _usernameError = "Это имя уже занято 😔";
          });
        }
      }
    });
  }

  // 👇 НОВАЯ ЛОГИКА УМНОЙ ПРОВЕРКИ EMAIL 👇
  void _onEmailChanged(String value) {
    context.read<AuthProvider>().clearError();
    
    if (_emailError != null) {
      setState(() => _emailError = null);
    }

    if (_debounceEmail?.isActive ?? false) _debounceEmail!.cancel();
    
    _debounceEmail = Timer(const Duration(milliseconds: 800), () async {
      final emailValid = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value.trim());
      if (emailValid) {
        final isTaken = await context.read<AuthProvider>().isEmailTaken(value.trim());
        if (isTaken && mounted) {
          setState(() {
            _emailError = "На этот емайл уже создан акк 😔";
          });
        }
      }
    });
  }

  void _onOtherFieldChanged(String value) {
    context.read<AuthProvider>().clearError();
  }

  void _handleSignUp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _hasSubmitted = true;
    });

    // 👈 Блокируем отправку, если есть ошибки логина ИЛИ почты
    if (!_formKey.currentState!.validate() || _usernameError != null || _emailError != null) {
      return; 
    }

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final authProvider = context.read<AuthProvider>();

    final registerSuccess = await authProvider.register(username, password, email);

    if (registerSuccess && mounted) {
      final loginSuccess = await authProvider.login(username, password);
      
      if (loginSuccess && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 32),
                  ),
                ),
                const Gap(24),

                Text(
                  "Регистрация",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Gap(8),
                const Text("Присоединяйтесь и начните тренировки.", style: TextStyle(color: Colors.grey, fontSize: 16)),

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

                _buildTextFormField(
                  label: "Логин", 
                  icon: Icons.person_outline, 
                  controller: usernameController,
                  onChanged: _onUsernameChanged, 
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return _hasSubmitted ? "Введите логин" : null;
                    if (value.trim().length < 3) return "Логин слишком короткий";
                    if (_usernameError != null) return _usernameError; 
                    return null; 
                  },
                ),
                const Gap(16),
                
                _buildTextFormField(
                  label: "Email", 
                  icon: Icons.email_outlined, 
                  controller: emailController,
                  onChanged: _onEmailChanged, // 👈 Подключили проверку почты
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return _hasSubmitted ? "Введите email" : null;
                    final emailValid = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value.trim());
                    if (!emailValid) return "Некорректный формат почты";
                    if (_emailError != null) return _emailError; // 👈 Выводим ошибку, если занято
                    return null;
                  },
                ),
                const Gap(16),
                
                _buildTextFormField(
                  label: "Пароль (минимум 6 символов)", 
                  icon: Icons.lock_outline, 
                  controller: passwordController,
                  obscureText: !_isPasswordVisible, 
                  onChanged: _onOtherFieldChanged,
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return _hasSubmitted ? "Введите пароль" : null;
                    if (value.length < 6) return "Пароль должен быть не менее 6 символов"; 
                    return null;
                  },
                ),
                const Gap(16),

                _buildTextFormField(
                  label: "Подтвердите пароль", 
                  icon: Icons.lock_reset, 
                  controller: confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible, 
                  onChanged: _onOtherFieldChanged,
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return _hasSubmitted ? "Подтвердите пароль" : null;
                    if (value != passwordController.text) return "Пароли не совпадают"; 
                    return null;
                  },
                ),

                const Gap(32),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text("Зарегистрироваться", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator, 
    bool obscureText = false, 
    Widget? suffixIcon,       
    void Function(String)? onChanged, 
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged, 
      style: const TextStyle(color: Colors.white),
      validator: validator, 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffixIcon, 
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 1)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
    );
  }
}