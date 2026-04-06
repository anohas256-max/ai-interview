import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:sobes/features/interview/presentation/pages/chat_page.dart';
import 'package:sobes/features/interview/domain/entities/session_config.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';
import 'package:sobes/features/profile/presentation/providers/profile_provider.dart';
import 'package:sobes/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart';
import 'package:sobes/core/providers/settings_provider.dart';

const List<String> quizDifficultiesKeys = ['diff_junior', 'diff_middle', 'diff_senior'];
const Map<String, int> quizLengthsKeys = { 'quiz_short': 5, 'quiz_medium': 10, 'quiz_long': 15 };

class SetupQuizPage extends StatefulWidget {
  const SetupQuizPage({super.key});

  @override
  State<SetupQuizPage> createState() => _SetupQuizPageState();
}

class _SetupQuizPageState extends State<SetupQuizPage> {
  String selectedTopicKey = 'custom_opt';
  String selectedDifficultyKey = quizDifficultiesKeys[1]; 
  String selectedLengthKey = quizLengthsKeys.keys.elementAt(1);
  String communicationStyleKey = 'style_strict'; 

  final TextEditingController _customTopicCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final settings = context.watch<SettingsProvider>();
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;
    
    final List<String> dynamicTopicsKeys = [...catalogProvider.quizTopics, 'custom_opt'];
    
    if (!dynamicTopicsKeys.contains(selectedTopicKey) && selectedTopicKey == 'custom_opt') selectedTopicKey = 'custom_opt';
    String currentTopicKey = dynamicTopicsKeys.contains(selectedTopicKey) ? selectedTopicKey : dynamicTopicsKeys.first;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(settings.t('setup_quiz_title'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
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
                    _buildLabel(settings.t('quiz_topic')),
                    const Gap(8),
                    _buildDropdown(
                      value: currentTopicKey, 
                      items: dynamicTopicsKeys, 
                      cardColor: cardColor, 
                      textColor: textColor,
                      settings: settings,
                      onChanged: (val) => setState(() => selectedTopicKey = val!)
                    ),
                    if (currentTopicKey == 'custom_opt') ...[
                      const Gap(8),
                      TextField(
                        controller: _customTopicCtrl,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: settings.t('custom_topic_hint'), // 👈 ИСПРАВЛЕН ХИНТ
                          filled: true, 
                          fillColor: cardColor,
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                    const Gap(24),

                    _buildLabel(settings.t('difficulty_level')),
                    const Gap(8),
                    _buildDropdown(
                      value: selectedDifficultyKey, 
                      items: quizDifficultiesKeys, 
                      cardColor: cardColor, 
                      textColor: textColor,
                      settings: settings,
                      onChanged: (val) => setState(() => selectedDifficultyKey = val!)
                    ),
                    const Gap(24),

                    _buildLabel(settings.t('quiz_duration')),
                    const Gap(8),
                    _buildDropdown(
                      value: selectedLengthKey, 
                      items: quizLengthsKeys.keys.toList(), 
                      cardColor: cardColor, 
                      textColor: textColor,
                      settings: settings,
                      onChanged: (val) => setState(() => selectedLengthKey = val!)
                    ),
                    const Gap(24),

                    _buildLabel(settings.t('comm_format')),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildStyleCard('style_friendly', cardColor, textColor, settings)),
                        const Gap(12),
                        Expanded(child: _buildStyleCard('style_strict', cardColor, textColor, settings)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildStyleCard('style_pedant', cardColor, textColor, settings)),
                        const Gap(12),
                        Expanded(child: _buildStyleCard('style_provocateur', cardColor, textColor, settings)),
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
                    String finalTopic = currentTopicKey == 'custom_opt' && _customTopicCtrl.text.isNotEmpty 
                        ? _customTopicCtrl.text 
                        : settings.t(currentTopicKey);
                        
                    String translatedDifficulty = settings.t(selectedDifficultyKey);
                    String translatedFeedback = settings.t(communicationStyleKey);
                    
                    final profileProvider = context.read<ProfileProvider>();
                    final authProvider = context.read<AuthProvider>();

                    final config = SessionConfig(
                      role: finalTopic,
                      persona: "Экзаменатор", 
                      difficulty: translatedDifficulty, 
                      questionLimit: quizLengthsKeys[selectedLengthKey]!,  
                      feedbackStyle: translatedFeedback, 
                      includeLegend: false, 
                      isRoleplayMode: false, 
                      userName: authProvider.currentUsername ?? "User", 
                      userBio: profileProvider.userBio,
                      language: settings.currentLanguage,
                    );

                    context.read<InterviewProvider>().clearChat();
                    context.read<InterviewProvider>().setConfig(config);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(role: finalTopic)));
                  },
                  child: Text(settings.t('start_quiz_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0));

  Widget _buildDropdown({required String value, required List<String> items, required Color cardColor, required Color? textColor, required SettingsProvider settings, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.2))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first, 
          dropdownColor: cardColor, 
          isExpanded: true, 
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(settings.t(item)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStyleCard(String styleKey, Color cardColor, Color? textColor, SettingsProvider settings) {
    bool isSelected = communicationStyleKey == styleKey;
    return GestureDetector(
      onTap: () => setState(() => communicationStyleKey = styleKey),
      child: Container(
        padding: const EdgeInsets.all(12), 
        height: 100,
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.withOpacity(0.2), width: isSelected ? 2 : 1)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(settings.t(styleKey), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
            const Gap(6), 
            Text(settings.t('${styleKey}_desc'), style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 2),
          ],
        ),
      ),
    );
  }
}