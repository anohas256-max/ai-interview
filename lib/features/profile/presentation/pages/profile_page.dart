import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:sobes/features/profile/presentation/providers/profile_provider.dart';
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart';
import 'package:sobes/features/auth/presentation/pages/login_page.dart';
import 'package:sobes/core/providers/settings_provider.dart';
// 👇 Добавили импорт Каталога
import 'package:sobes/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:sobes/features/history/presentation/providers/history_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  void _editName() {
    final authProvider = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final initialName = authProvider.currentFirstName ?? "";
    TextEditingController controller = TextEditingController(text: initialName);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(settings.t('edit_name_title'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              hintText: settings.t('edit_name_hint'),
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(settings.t('cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: authProvider.isLoading ? null : () async {
                final newName = controller.text.trim();
                setStateDialog(() {}); 
                final success = await authProvider.updateName(newName);
                
                if (success && context.mounted) {
                  Navigator.pop(context);
                  _showDummyAction(settings.t('snack_name_updated'));
                } else if (context.mounted) {
                  setStateDialog(() {}); 
                  _showDummyAction(authProvider.errorMessage ?? settings.t('snack_server_error'));
                }
              },
              child: authProvider.isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(settings.t('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _editAboutMe() {
    final currentBio = context.read<ProfileProvider>().userBio;
    final settings = context.read<SettingsProvider>();
    TextEditingController controller = TextEditingController(text: currentBio);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(settings.t('about_me_title'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: TextField(
          controller: controller,
          maxLines: 4, 
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: settings.t('about_me_hint'),
            hintStyle: const TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(settings.t('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<ProfileProvider>().updateBio(controller.text);
              Navigator.pop(context);
            },
            child: Text(settings.t('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool _obsOld = true;
  bool _obsNew = true;
  bool _obsConf = true;

  void _changePassword() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final settings = context.read<SettingsProvider>();

    String? errorMessage; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          title: Text(settings.t('pass_setting'), style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null) ...[
                    Text(errorMessage!, style: const TextStyle(color: Color(0xFFFF453A), fontSize: 13, fontWeight: FontWeight.bold)),
                    const Gap(12),
                  ],
                  _buildDialogField(settings.t('old_pass'), oldController, _obsOld, () => setStateDialog(() => _obsOld = !_obsOld)),
                  const Gap(12),
                  _buildDialogField(settings.t('new_pass'), newController, _obsNew, () => setStateDialog(() => _obsNew = !_obsNew)),
                  const Gap(12),
                  _buildDialogField(settings.t('confirm_pass'), confController, _obsConf, () => setStateDialog(() => _obsConf = !_obsConf)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(settings.t('cancel'), style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                setStateDialog(() => errorMessage = null); 

                if (newController.text != confController.text) {
                  setStateDialog(() => errorMessage = settings.t('pass_mismatch'));
                  return;
                }
                if (newController.text.length < 6) {
                  setStateDialog(() => errorMessage = settings.t('short_pass'));
                  return;
                }

                final authProvider = context.read<AuthProvider>();
                final errorFromServer = await authProvider.changePassword(oldController.text, newController.text);
                
                if (context.mounted) {
                  if (errorFromServer == null) {
                    Navigator.pop(context); 
                    _showDummyAction(settings.t('snack_pass_updated')); 
                  } else {
                    setStateDialog(() => errorMessage = errorFromServer); 
                  }
                }
              },
              child: Text(settings.t('update')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String hint, TextEditingController ctr, bool obscure, VoidCallback toggle) {
    return TextFormField(
      controller: ctr,
      obscureText: obscure,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: toggle),
      ),
    );
  }

  void _showDummyAction(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2C2C2E),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authData = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>(); 
    
    final currentUsername = authData.currentUsername ?? "Loading...";
    final currentEmail = authData.currentEmail ?? "Loading...";
    
    final displayName = (authData.currentFirstName != null && authData.currentFirstName!.isNotEmpty) 
        ? authData.currentFirstName! 
        : currentUsername;

    final currentBio = context.watch<ProfileProvider>().userBio;

    String initials = displayName.trim().isNotEmpty && displayName != "Loading..."
        ? displayName.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join()
        : "?";

    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Gap(10),

              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        initials, 
                        style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showDummyAction(settings.t('snack_coming_soon')),
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              
              const Gap(16),

              GestureDetector(
                onTap: _editName,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(displayName, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    Icon(Icons.edit, color: Colors.grey[600], size: 16),
                  ],
                ),
              ),
              const Gap(4),
              Text("@$currentUsername • $currentEmail", style: const TextStyle(color: Colors.grey, fontSize: 13)),

              const Gap(32),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _editAboutMe,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(settings.t('about_me_title'), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            Icon(Icons.edit_outlined, color: Colors.grey[600], size: 18),
                          ],
                        ),
                        const Gap(12),
                        Text(currentBio, style: TextStyle(color: textColor, fontSize: 15, height: 1.5)),
                      ],
                    ),
                  ),
                ),
              ),

              const Gap(24),

              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: settings.t('lang_setting'), 
                      trailingText: settings.currentLanguage,
                      textColor: textColor,
                      onTap: () {
                        // 👇 МАГИЯ ПРОИСХОДИТ ЗДЕСЬ 👇
                        final newLang = settings.currentLanguage == "English" ? "Русский" : "English";
                        settings.setLanguage(newLang); // Меняем локально
                        context.read<CatalogProvider>().updateLanguage(newLang); // Дергаем сервер
                      },
                    ),
                    Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: settings.t('pass_setting'),
                      textColor: textColor,
                      onTap: _changePassword,
                    ),
                  ],
                ),
              ),

              const Gap(16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dark_mode_outlined, color: Colors.grey, size: 20),
                        const Gap(12),
                        Text(settings.t('dark_mode'), style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Switch(
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: (value) => settings.toggleTheme(),
                      activeColor: Colors.blueAccent,
                      activeTrackColor: Colors.grey[300],
                    ),
                  ],
                ),
              ),

              const Gap(40),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    // 👇 СНАЧАЛА ОЧИЩАЕМ ИСТОРИЮ (ЧТОБЫ ДРУГОЙ ЮЗЕР ЕЕ НЕ УВИДЕЛ) 👇
                    context.read<HistoryProvider>().clear(); 
                    
                    await context.read<AuthProvider>().logout();
                    
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: Text(settings.t('sign_out'), style: const TextStyle(color: Color(0xFFFF453A), fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              
              const Gap(40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, String? trailingText, Color? textColor, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.grey, size: 20),
                  const Gap(12),
                  Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                children: [
                  if (trailingText != null) ...[
                    Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const Gap(8),
                  ],
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}