import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 Добавили для FilteringTextInputFormatter
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

const List<String> quizDifficultiesKeys = ['diff_basic', 'diff_intermediate', 'diff_advanced', 'diff_expert'];

class SetupQuizPage extends StatefulWidget {
  const SetupQuizPage({super.key});

  @override
  State<SetupQuizPage> createState() => _SetupQuizPageState();
}

class _SetupQuizPageState extends State<SetupQuizPage> {
  // Изначально null, чтобы подхватить первую роль из базы
  String? selectedTopicKey;
  String selectedDifficultyKey = quizDifficultiesKeys[1];
  String communicationStyleKey = 'style_strict'; 
  
  // 👇 НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ КОЛИЧЕСТВА ВОПРОСОВ (как в Roleplay) 👇
  int questionLimit = 10; // Дефолт
  bool isCustomLimit = false;

  bool isStartingSession = false; 

  final TextEditingController _customTopicCtrl = TextEditingController();
  final TextEditingController _customLimitCtrl = TextEditingController(); // Контроллер лимита

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade50;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;
    
    // Формируем список и подхватываем дефолт
    final List<String> dynamicTopicsKeys = [...catalogProvider.quizTopics, 'custom_opt'];
    if (selectedTopicKey == null) {
       selectedTopicKey = catalogProvider.quizTopics.isNotEmpty ? catalogProvider.quizTopics.first : 'custom_opt';
    } else if (!dynamicTopicsKeys.contains(selectedTopicKey) && selectedTopicKey != 'custom_opt') {
       selectedTopicKey = 'custom_opt';
    }

    return Scaffold(
      backgroundColor: bgColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0, 
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(
          settings.t('setup_quiz_title'), 
          style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 20, height: 1.1), 
          maxLines: 2, 
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: BalanceBadge(),
          ),
        ],
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
                    const Gap(6), 
                    _buildDropdown(
                      value: selectedTopicKey!, 
                      items: dynamicTopicsKeys, 
                      cardColor: cardColor, 
                      textColor: textColor,
                      settings: settings,
                      isDark: isDark,
                      onChanged: (val) => setState(() => selectedTopicKey = val!)
                    ),
                    if (selectedTopicKey == 'custom_opt') ...[
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
                            // 👇 ОБВОДКА 👇
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08), width: 1.2)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08), width: 1.2)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
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

                    // 👇 ВСТАВЛЕН БЛОК ВЫБОРА КОЛИЧЕСТВА ВОПРОСОВ ИЗ ROLEPLAY 👇
                    _buildLabel(settings.t('question_count')),
                    const Gap(12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [5, 10, 15, -1].map((limit) { // Немного другие пресеты для квиза
                        final isCustomBtn = limit == -1;
                        final isSelected = isCustomBtn ? isCustomLimit : (!isCustomLimit && questionLimit == limit);
                        final text = isCustomBtn ? "⚙️" : "$limit";
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isCustomBtn) {
                                isCustomLimit = true;
                              } else {
                                isCustomLimit = false;
                                questionLimit = limit;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isCustomBtn ? 50 : 60,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blueAccent : cardColor, 
                              borderRadius: BorderRadius.circular(12), 
                              border: Border.all(color: isSelected ? Colors.blueAccent : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)), width: 1.2),
                              boxShadow: isSelected 
                                ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] 
                                : (!isDark ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))] : []),
                            ),
                            child: Text(
                              text, 
                              style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.grey : Colors.grey.shade700), fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (isCustomLimit) ...[
                      const Gap(8),
                      _buildCustomInlineInput(
                        controller: _customLimitCtrl, 
                        hint: "Кол-во (макс 100)",
                        isNumber: true,
                        maxLength: 3, 
                        cardColor: cardColor, 
                        textColor: textColor,
                        isDark: isDark,
                        onChanged: (val) {
                          int? num = int.tryParse(val);
                          setState(() {
                            if (num != null && num > 0) {
                              questionLimit = num > 100 ? 100 : num;
                              if (num > 100) {
                                 _customLimitCtrl.text = '100';
                                 _customLimitCtrl.selection = TextSelection.fromPosition(const TextPosition(offset: 3));
                              }
                            } else {
                              questionLimit = 1;
                            }
                          });
                        }
                      ),
                    ],
                    // 👆 КОНЕЦ БЛОКА ВОПРОСОВ 👆
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
                    backgroundColor: Colors.blueAccent, 
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

                    String finalTopic = selectedTopicKey == 'custom_opt' && _customTopicCtrl.text.isNotEmpty 
                        ? _customTopicCtrl.text 
                        : settings.t(selectedTopicKey!);
                        
                    String translatedDifficulty = settings.t(selectedDifficultyKey);
                    String translatedFeedback = settings.t(communicationStyleKey);
                    
                    final profileProvider = context.read<ProfileProvider>();
                    final authProvider = context.read<AuthProvider>();

                    final config = SessionConfig(
                      role: finalTopic,
                      persona: "Экзаменатор", 
                      difficulty: translatedDifficulty, 
                      questionLimit: questionLimit, // 👈 Теперь берем лимит отсюда
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(settings.t('start_quiz_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Gap(8),
                              Builder(builder: (context) {
                                // 👈 Вычисляем стоимость по новому лимиту
                                double currentCost = questionLimit * 0.5;
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

  // --- Вспомогательные виджеты ---
  
  Widget _buildLabel(String text) => Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0));

  Widget _buildDropdown({required String value, required List<String> items, required Color cardColor, required Color? textColor, required SettingsProvider settings, required bool isDark, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08), width: 1.2),
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

  Widget _buildCustomInlineInput({required TextEditingController controller, required String hint, required Color cardColor, required Color? textColor, required bool isDark, bool isNumber = false, int? maxLength, Function(String)? onChanged}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))] : [],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
        maxLength: maxLength,
        onChanged: onChanged,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint, 
          hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade500),
          filled: true, 
          fillColor: cardColor, 
          counterText: "", 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08), width: 1.2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08), width: 1.2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        border: Border.all(color: isSelected ? Colors.blueAccent : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)), width: isSelected ? 2 : 1.2),
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