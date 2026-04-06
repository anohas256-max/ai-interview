import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../providers/auth_provider.dart';
import 'package:sobes/core/providers/settings_provider.dart'; // 👈 Провайдер

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

  Timer? _debounce;
  String? _usernameError;
  Timer? _debounceEmail;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AuthProvider>().clearError());
  }

  @override
  void dispose() {
    _debounce?.cancel(); 
    _debounceEmail?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    context.read<AuthProvider>().clearError();
    if (_usernameError != null) setState(() => _usernameError = null);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      if (value.trim().length >= 3) {
        final isTaken = await context.read<AuthProvider>().isUsernameTaken(value.trim());
        if (isTaken && mounted) setState(() => _usernameError = context.read<SettingsProvider>().t('taken_login'));
      }
    });
  }

  void _onEmailChanged(String value) {
    context.read<AuthProvider>().clearError();
    if (_emailError != null) setState(() => _emailError = null);
    if (_debounceEmail?.isActive ?? false) _debounceEmail!.cancel();
    
    _debounceEmail = Timer(const Duration(milliseconds: 800), () async {
      final emailValid = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value.trim());
      if (emailValid) {
        final isTaken = await context.read<AuthProvider>().isEmailTaken(value.trim());
        if (isTaken && mounted) setState(() => _emailError = context.read<SettingsProvider>().t('taken_email'));
      }
    });
  }

  void _onOtherFieldChanged(String value) => context.read<AuthProvider>().clearError();

  void _handleSignUp() async {
    FocusScope.of(context).unfocus();
    setState(() => _hasSubmitted = true);

    if (!_formKey.currentState!.validate() || _usernameError != null || _emailError != null) return; 

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final authProvider = context.read<AuthProvider>();

    final registerSuccess = await authProvider.register(username, password, email);
    if (registerSuccess && mounted) {
      final loginSuccess = await authProvider.login(username, password);
      if (loginSuccess && mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
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
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.person_add_alt_1, color: textColor, size: 32),
                  ),
                ),
                const Gap(24),
                Text(settings.t('register_title'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                const Gap(8),
                Text(settings.t('register_subtitle'), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const Gap(48),

                if (authProvider.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.5))),
                    child: Text(authProvider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                  const Gap(16),
                ],

                _buildTextFormField(
                  label: settings.t('login'), icon: Icons.person_outline, controller: usernameController, onChanged: _onUsernameChanged, 
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return _hasSubmitted ? settings.t('empty_login') : null;
                    if (value.trim().length < 3) return settings.t('short_login');
                    if (_usernameError != null) return _usernameError; 
                    return null; 
                  },
                ),
                const Gap(16),
                _buildTextFormField(
                  label: settings.t('email_hint'), icon: Icons.email_outlined, controller: emailController, onChanged: _onEmailChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return _hasSubmitted ? settings.t('empty_email') : null;
                    final emailValid = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value.trim());
                    if (!emailValid) return settings.t('invalid_email');
                    if (_emailError != null) return _emailError;
                    return null;
                  },
                ),
                const Gap(16),
                _buildTextFormField(
                  label: settings.t('password_min'), icon: Icons.lock_outline, controller: passwordController, obscureText: !_isPasswordVisible, onChanged: _onOtherFieldChanged,
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return _hasSubmitted ? settings.t('empty_pass') : null;
                    if (value.length < 6) return settings.t('short_pass'); 
                    return null;
                  },
                ),
                const Gap(16),
                _buildTextFormField(
                  label: settings.t('confirm_pass'), icon: Icons.lock_reset, controller: confirmPasswordController, obscureText: !_isConfirmPasswordVisible, onChanged: _onOtherFieldChanged,
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return _hasSubmitted ? settings.t('confirm_pass') : null;
                    if (value != passwordController.text) return settings.t('pass_mismatch'); 
                    return null;
                  },
                ),
                const Gap(32),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleSignUp,
                    child: authProvider.isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(settings.t('register_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({required String label, required IconData icon, required TextEditingController controller, required String? Function(String?) validator, bool obscureText = false, Widget? suffixIcon, void Function(String)? onChanged}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return TextFormField(
      controller: controller, obscureText: obscureText, onChanged: onChanged, 
      style: TextStyle(color: textColor),
      validator: validator, 
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey), suffixIcon: suffixIcon, 
        filled: true, fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: textColor ?? Colors.white, width: 1)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
        errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
    );
  }
}