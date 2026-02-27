import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

// Подключаем наш пульт профиля! (Убедись, что путь правильный для твоего проекта)
import 'package:sobes/features/profile/presentation/providers/profile_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Локально оставляем только визуал (тему и email, если он пока не нужен ИИ)
  bool _isDarkMode = true;
  String _userEmail = "john.doe@example.com";

  // --- ФУНКЦИИ ДЛЯ ВСПЛЫВАЮЩИХ ОКОН ---

  // 1. Изменение имени
  void _editName() {
    // Читаем текущее имя из Провайдера
    final currentName = context.read<ProfileProvider>().userName;
    TextEditingController controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Name", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: "Enter your name",
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // 👇 СОХРАНЯЕМ НОВОЕ ИМЯ ПРЯМО В ПУЛЬТ 👇
              context.read<ProfileProvider>().updateName(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 2. Изменение текста "Обо мне"
  void _editAboutMe() {
    // Читаем текущее био из Провайдера
    final currentBio = context.read<ProfileProvider>().userBio;
    TextEditingController controller = TextEditingController(text: currentBio);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Context", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 4, 
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: "Tell AI about your experience...",
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!), borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              // 👇 СОХРАНЯЕМ НОВУЮ ИНФУ ПРЯМО В ПУЛЬТ 👇
              context.read<ProfileProvider>().updateBio(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 3. Изменение пароля (пока заглушка)
  void _changePassword() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Change Password", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: true, 
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: "New password",
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDummyAction("Password updated successfully!");
            },
            child: const Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
    // 👇 СЛУШАЕМ ДАННЫЕ НАПРЯМУЮ ИЗ ПРОВАЙДЕРА 👇
    final profileData = context.watch<ProfileProvider>();
    final currentName = profileData.userName;
    final currentBio = profileData.userBio;

    // Вычисляем инициалы из имени
    String initials = currentName.trim().isNotEmpty 
        ? currentName.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join()
        : "?";

    return Scaffold(
      backgroundColor: Colors.black,
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Gap(10),

              // 1. Аватарка
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: 1),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials, 
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showDummyAction("Upload photo feature coming soon"),
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

              // 2. Имя и Email
              GestureDetector(
                onTap: _editName,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(currentName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), // 👈 БЕРЕМ ИЗ ПРОВАЙДЕРА
                    const Gap(8),
                    Icon(Icons.edit, color: Colors.grey[600], size: 16),
                  ],
                ),
              ),
              const Gap(4),
              Text(_userEmail, style: TextStyle(color: Colors.grey[500], fontSize: 14)),

              const Gap(32),

              // 3. Карточка "Обо мне / Контекст"
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _editAboutMe,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: Colors.white.withOpacity(0.1),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("ABOUT ME / CONTEXT", style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            Icon(Icons.edit_outlined, color: Colors.grey[600], size: 18),
                          ],
                        ),
                        const Gap(12),
                        Text(currentBio, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)), // 👈 БЕРЕМ ИЗ ПРОВАЙДЕРА
                      ],
                    ),
                  ),
                ),
              ),

              const Gap(24),

              // 4. БЛОК ДОП. НАСТРОЕК
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: "Language",
                      trailingText: "English",
                      onTap: () => _showDummyAction("Language selection coming soon"),
                    ),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: "Change Password",
                      onTap: _changePassword,
                    ),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    _buildSettingsTile(
                      icon: Icons.notifications_none,
                      title: "Notifications",
                      onTap: () => _showDummyAction("Notification settings coming soon"),
                    ),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      onTap: () => _showDummyAction("Support page coming soon"),
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // 5. Переключатель темы
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.dark_mode_outlined, color: Colors.grey, size: 20),
                        Gap(12),
                        Text("Dark Mode", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Switch(
                      value: _isDarkMode,
                      onChanged: (value) => setState(() => _isDarkMode = value),
                      activeColor: Colors.black,
                      activeTrackColor: Colors.white,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.black,
                    ),
                  ],
                ),
              ),

              const Gap(40),

              // 6. Кнопка выхода
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showDummyAction("Logging out..."),
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Colors.red.withOpacity(0.2),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: Text("Sign Out", style: TextStyle(color: Color(0xFFFF453A), fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _buildSettingsTile({required IconData icon, required String title, String? trailingText, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.05),
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
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
              Row(
                children: [
                  if (trailingText != null) ...[
                    Text(trailingText, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const Gap(8),
                  ],
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}