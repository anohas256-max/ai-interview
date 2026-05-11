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
import 'package:sobes/core/widgets/balance_badge.dart';

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
  
  bool isStartingSession = false; 

  final TextEditingController _customTopicCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade50;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    
    final List<String> dynamicTopicsKeys = [...catalogProvider.quizTopics, 'custom_opt'];
    
    if (!dynamicTopicsKeys.contains(selectedTopicKey) && selectedTopicKey == 'custom_opt') selectedTopicKey = 'custom_opt';
    String currentTopicKey = dynamicTopicsKeys.contains(selectedTopicKey) ? selectedTopicKey : dynamicTopicsKeys.first;

    return Scaffold(
      backgroundColor: bgColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(
          settings.t('setup_quiz_title'), 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [BalanceBadge()],
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
                    const Gap(6), // Уменьшили отступ
                    _buildDropdown(
                      value: currentTopicKey, 
                      items: dynamicTopicsKeys, 
                      cardColor: cardColor, 
                      textColor: textColor,
                      settings: settings,
                      isDark: isDark,
                      onChanged: (val) => setState(() => selectedTopicKey = val!)
                    ),
                    if (currentTopicKey == 'custom_opt') ...[
                      const Gap(8),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))] : [],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _customTopicCtrl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: settings.t('custom_topic_hint'),
                            filled: true, 
                            fillColor: cardColor,
                            hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade500),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300)),
                          ),
                        ),
                      ),
                    ],
                    const Gap(24),

                    _buildLabel(settings.t('difficulty_level')),
                    const Gap(6),
                    _buildDropdown(
                      value: selectedDifficultyKey, 
                      items: quizDifficultiesKeys, 
                      cardColor: cardColor, 
                      textColor: textColor,
                      settings: settings,
                      isDark: isDark,
                      onChanged: (val) => setState(() => selectedDifficultyKey = val!)
                    ),
                    const Gap(24),

                    _buildLabel(settings.t('quiz_duration')),
                    const Gap(6),
                    _buildDropdown(
                      value: selectedLengthKey, 
                      items: quizLengthsKeys.keys.toList(), 
                      cardColor: cardColor, 
                      textColor: textColor,
                      settings: settings,
                      isDark: isDark,
                      onChanged: (val) => setState(() => selectedLengthKey = val!)
                    ),
                    const Gap(24),

                    _buildLabel(settings.t('comm_format')),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildStyleCard('style_friendly', cardColor, textColor, settings, isDark)),
                        const Gap(12),
                        Expanded(child: _buildStyleCard('style_strict', cardColor, textColor, settings, isDark)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildStyleCard('style_pedant', cardColor, textColor, settings, isDark)),
                        const Gap(12),
                        Expanded(child: _buildStyleCard('style_provocateur', cardColor, textColor, settings, isDark)),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // И для светлой, и для темной
                    foregroundColor: Colors.white,
                    elevation: isDark ? 4 : 2,
                    shadowColor: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? Colors.transparent : Colors.black87),
                    ),
                  ),
                  onPressed: isStartingSession ? null : () async {
                    setState(() => isStartingSession = true); 

                    String finalTopic = currentTopicKey == 'custom_opt' && _customTopicCtrl.text.isNotEmpty 
                        ? _customTopicCtrl.text 
                        : settings.t(currentTopicKey);
                        
                    String translatedDifficulty = settings.t(selectedDifficultyKey);
                    String translatedFeedback = settings.t(communicationStyleKey);
                    
                    final profileProvider = context.read<ProfileProvider>();
                    final authProvider = context.read<AuthProvider>();
                    
                    final selectedLimit = quizLengthsKeys[selectedLengthKey]!;

                    final config = SessionConfig(
                      role: finalTopic,
                      persona: "Экзаменатор", 
                      difficulty: translatedDifficulty, 
                      questionLimit: selectedLimit,  
                      feedbackStyle: translatedFeedback, 
                      includeLegend: false, 
                      isRoleplayMode: false, 
                      userName: authProvider.currentUsername ?? "User", 
                      userBio: profileProvider.userBio,
                      language: settings.currentLanguage,
                    );

                    await context.read<InterviewProvider>().clearChat();
                    context.read<InterviewProvider>().setConfig(config);

                    final result = await context.read<InterviewProvider>().startSession(config);

                    if (!mounted) return;
                    setState(() => isStartingSession = false);

                    if (result['success']) {
                      authProvider.updateBalance(result['new_balance'].toDouble());
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(role: finalTopic)));
                    } else {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white),
                              const Gap(12),
                              Text(result['error'] ?? 'Ошибка оплаты'),
                            ],
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        )
                      );
                    }
                  },
                  child: isStartingSession 
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        // Добавили Padding внутри FittedBox
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(settings.t('start_quiz_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Gap(8),
                              Builder(builder: (context) {
                                int selectedLimit = quizLengthsKeys[selectedLengthKey]!;
                                double currentCost = selectedLimit * 0.5;
                                String priceText = currentCost % 1 == 0 ? currentCost.toInt().toString() : currentCost.toString();
                                Color priceColor = isDark ? Colors.amberAccent : Colors.amber;
                                return Text("(Цена: $priceText ⚡️)", style: TextStyle(fontSize: 14, color: priceColor, fontWeight: FontWeight.bold));
                              }),
                            ],
                          ),
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0));

  Widget _buildDropdown({required String value, required List<String> items, required Color cardColor, required Color? textColor, required SettingsProvider settings, required bool isDark, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade300),
        // Легкая тень
        boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))] : [],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first, 
          dropdownColor: cardColor, 
          isExpanded: true, 
          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.grey : Colors.grey.shade700),
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(settings.t(item)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStyleCard(String styleKey, Color cardColor, Color? textColor, SettingsProvider settings, bool isDark) {
    bool isSelected = communicationStyleKey == styleKey;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: 100,
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueAccent.withOpacity(0.08) : cardColor, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isSelected ? Colors.blueAccent : (isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade300), width: isSelected ? 2 : 1),
        // Добавили красивую мягкую тень
        boxShadow: isSelected 
            ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
            : (!isDark ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))] : []),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => communicationStyleKey = styleKey),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(settings.t(styleKey), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                const Gap(6), 
                Text(settings.t('${styleKey}_desc'), style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600, fontSize: 11), maxLines: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}