import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'setup_page.dart'; 
import 'setup_quiz_page.dart'; 

class ModeSelectionPage extends StatelessWidget {
  const ModeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Выбор формата", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true, // 👈 Центрируем заголовок
      ),
      body: Center( // 👈 ЦЕНТРИРУЕМ ВЕСЬ КОНТЕНТ (ДЛЯ ВЕБА)
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // 👈 Делаем красивую ширину 600px
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // 👈 Карточки будут одинаковой ширины
              children: [
                _buildModeCard(
                  context,
                  title: "Сюжетное собеседование",
                  description: "Полное погружение в роль. HR-менеджер, вопросы по резюме, отыгрыш ситуаций и проверка софт-скиллов.",
                  icon: Icons.cases_rounded,
                  color: Colors.blueAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupPage())),
                ),
                const Gap(24),
                _buildModeCard(
                  context,
                  title: "Проверка знаний",
                  description: "Строгий фокус на хард-скиллах и теории. Никакой воды, только вопросы по выбранной теме и оценка ответов.",
                  icon: Icons.psychology_rounded,
                  color: Colors.greenAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupQuizPage())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(BuildContext context, {required String title, required String description, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const Gap(16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Gap(8),
            Text(description, style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}