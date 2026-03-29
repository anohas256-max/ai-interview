import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:sobes/features/interview/presentation/pages/chat_page.dart';
import 'package:sobes/features/interview/domain/entities/session_config.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';
import 'package:sobes/features/profile/presentation/providers/profile_provider.dart';
import 'package:sobes/features/catalog/presentation/providers/catalog_provider.dart';
// 👇 ДОБАВЛЕН ПРОВАЙДЕР АВТОРИЗАЦИИ 👇
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart';

const List<String> quizDifficulties = [
  'Легкий (Базовые понятия)', 'Средний (Углубленные знания)', 'Сложный (Экспертный уровень)'
];

const Map<String, int> quizLengths = {
  'Мало (3-5 вопросов)': 5,
  'Средне (8-10 вопросов)': 10,
  'Много (14-16 вопросов)': 15,
};

class SetupQuizPage extends StatefulWidget {
  const SetupQuizPage({super.key});

  @override
  State<SetupQuizPage> createState() => _SetupQuizPageState();
}

class _SetupQuizPageState extends State<SetupQuizPage> {
  String selectedTopic = 'Свой вариант ✍️';
  String selectedDifficulty = quizDifficulties[1]; 
  String selectedLengthLabel = quizLengths.keys.elementAt(1);
  String communicationStyle = 'По делу'; 

  final TextEditingController _customTopicCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final List<String> dynamicTopics = [...catalogProvider.quizTopics, 'Свой вариант ✍️'];
    
    String currentTopic = dynamicTopics.contains(selectedTopic) ? selectedTopic : dynamicTopics.first;

    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Настройка опроса", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("ТЕМА ОПРОСА / ПРОФЕССИЯ"),
                    const Gap(8),
                    _buildDropdown(value: currentTopic, items: dynamicTopics, onChanged: (val) => setState(() => selectedTopic = val!)),
                    if (currentTopic == 'Свой вариант ✍️') ...[
                      const Gap(8),
                      TextField(
                        controller: _customTopicCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Например: Квантовая физика",
                          filled: true, fillColor: const Color(0xFF1C1C1E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                    const Gap(24),

                    _buildLabel("УРОВЕНЬ СЛОЖНОСТИ"),
                    const Gap(8),
                    _buildDropdown(value: selectedDifficulty, items: quizDifficulties, onChanged: (val) => setState(() => selectedDifficulty = val!)),
                    const Gap(24),

                    _buildLabel("ДЛИТЕЛЬНОСТЬ ОПРОСА"),
                    const Gap(8),
                    _buildDropdown(value: selectedLengthLabel, items: quizLengths.keys.toList(), onChanged: (val) => setState(() => selectedLengthLabel = val!)),
                    const Gap(24),

                    _buildLabel("СТИЛЬ ОБЩЕНИЯ"),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildStyleCard("Дружелюбный", "Мягко указывает на ошибки")),
                        const Gap(12),
                        Expanded(child: _buildStyleCard("По делу", "Сухо, четко, без эмоций")),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildStyleCard("Душнила", "Придирается к каждой мелочи")),
                        const Gap(12),
                        Expanded(child: _buildStyleCard("Провокатор", "Пытается запутать и сбить с толку")),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    String finalTopic = currentTopic == 'Свой вариант ✍️' && _customTopicCtrl.text.isNotEmpty ? _customTopicCtrl.text : currentTopic;
                    
                    final profileProvider = context.read<ProfileProvider>();
                    // 👇 БЕРЕМ ИМЯ ИЗ AUTH PROVIDER 👇
                    final authProvider = context.read<AuthProvider>();

                    final config = SessionConfig(
                      role: finalTopic,
                      persona: "Экзаменатор", 
                      difficulty: selectedDifficulty, 
                      questionLimit: quizLengths[selectedLengthLabel]!,  
                      feedbackStyle: communicationStyle, 
                      includeLegend: false, 
                      isRoleplayMode: false, 
                      userName: authProvider.currentUsername ?? "User", // 👈 ИСПРАВЛЕНА ОШИБКА
                      userBio: profileProvider.userBio,
                    );

                    context.read<InterviewProvider>().clearChat();
                    context.read<InterviewProvider>().setConfig(config);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(role: finalTopic)));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const StadiumBorder()),
                  child: const Text("Начать проверку знаний", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0));

  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first, 
          dropdownColor: const Color(0xFF1E1E1E), isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStyleCard(String title, String subtitle) {
    bool isSelected = communicationStyle == title;
    return GestureDetector(
      onTap: () => setState(() => communicationStyle = title),
      child: Container(
        padding: const EdgeInsets.all(12), height: 100,
        decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.1), width: isSelected ? 2 : 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const Gap(6), 
            Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11), maxLines: 2),
          ],
        ),
      ),
    );
  }
}