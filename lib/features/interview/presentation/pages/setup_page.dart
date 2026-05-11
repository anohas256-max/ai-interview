import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const List<String> availablePersonasKeys = ['persona_hr', 'persona_recruiter', 'persona_techlead', 'persona_fool', 'custom_opt'];
const List<String> availableDifficultiesKeys = ['diff_junior', 'diff_middle', 'diff_senior', 'diff_progressive'];

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String selectedRoleKey = 'custom_opt';
  String selectedPersonaKey = availablePersonasKeys[0];
  String selectedDifficultyKey = availableDifficultiesKeys[3];
  
  String feedbackStyleKey = 'style_strict'; 
  
  bool includeLegend = true;
  bool isTeachingMode = false;
  bool isEndlessMode = false;
  
  int questionLimit = 5;
  bool isCustomLimit = false;
  bool isStartingSession = false;

  final TextEditingController _customRoleCtrl = TextEditingController();
  final TextEditingController _customPersonaCtrl = TextEditingController();
  final TextEditingController _customLimitCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final bgColor = isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade50; 
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white; 
    
    final List<String> dynamicRolesKeys = [...catalogProvider.interviewRoles, 'custom_opt'];
    
    if (!dynamicRolesKeys.contains(selectedRoleKey) && selectedRoleKey == 'custom_opt') selectedRoleKey = 'custom_opt';
    String currentRoleKey = dynamicRolesKeys.contains(selectedRoleKey) ? selectedRoleKey : dynamicRolesKeys.first;

    return Scaffold(
      backgroundColor: bgColor, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false, 
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(
          settings.t('setup_title'), 
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
                    _buildLabel(settings.t('desired_role')),
                    const Gap(6), // Уменьшили отступ для лучшей группировки
                    _buildDropdown(
                      value: currentRoleKey, 
                      items: dynamicRolesKeys, 
                      cardColor: cardColor, 
                      textColor: textColor,
                      settings: settings,
                      isDark: isDark,
                      onChanged: (val) => setState(() => selectedRoleKey = val!)
                    ),
                    if (currentRoleKey == 'custom_opt') ...[
                      const Gap(8),
                      _buildCustomInlineInput(
                        controller: _customRoleCtrl, 
                        hint: settings.t('custom_role_hint'),
                        maxLength: 50, 
                        cardColor: cardColor, 
                        textColor: textColor,
                        isDark: isDark
                      ),
                    ],
                    const Gap(24),

                    _buildLabel(settings.t('interviewer_type')),
                    const Gap(6),
                    _buildDropdown(
                      value: selectedPersonaKey, 
                      items: availablePersonasKeys, 
                      cardColor: cardColor, 
                      textColor: textColor,
                      settings: settings,
                      isDark: isDark,
                      onChanged: (val) => setState(() => selectedPersonaKey = val!)
                    ),
                    if (selectedPersonaKey == 'custom_opt') ...[
                      const Gap(8),
                      _buildCustomInlineInput(
                        controller: _customPersonaCtrl, 
                        hint: settings.t('custom_persona_hint'),
                        maxLength: 50, 
                        cardColor: cardColor, 
                        textColor: textColor,
                        isDark: isDark
                      ),
                    ],
                    const Gap(24),

                    _buildLabel(settings.t('difficulty_level')),
                    const Gap(6),
                    _buildDropdown(
                      value: selectedDifficultyKey, 
                      items: availableDifficultiesKeys, 
                      cardColor: cardColor, 
                      textColor: textColor,
                      settings: settings,
                      isDark: isDark,
                      onChanged: (val) => setState(() => selectedDifficultyKey = val!)
                    ),
                    const Gap(24),

                    _buildLabel(settings.t('work_modes')),
                    const Gap(6),
                    _buildToggleRow(settings.t('intro_legend'), includeLegend, cardColor, textColor, isDark, (val) => setState(() => includeLegend = val)),
                    const Gap(8),
                    _buildToggleRow(settings.t('teaching_mode'), isTeachingMode, cardColor, textColor, isDark, (val) => setState(() => isTeachingMode = val)),
                    const Gap(8),
                    _buildToggleRow(settings.t('endless_mode'), isEndlessMode, cardColor, textColor, isDark, (val) => setState(() => isEndlessMode = val)),
                    const Gap(24),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutBack,
                      child: isEndlessMode ? const SizedBox.shrink() : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(settings.t('question_count')),
                          const Gap(12),
                          Row(
                            children: [2, 5, 10, -1].map((limit) {
                              final isCustomBtn = limit == -1;
                              final isSelected = isCustomBtn ? isCustomLimit : (!isCustomLimit && questionLimit == limit);
                              final text = isCustomBtn ? settings.t('custom_limit') : "$limit";
                              
                              return Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blueAccent : cardColor, 
                                    borderRadius: BorderRadius.circular(12), 
                                    border: Border.all(color: isSelected ? Colors.blueAccent : (isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade300)),
                                    // Добавили легкую тень для невыбранных кнопок на светлой теме
                                    boxShadow: isSelected 
                                      ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] 
                                      : (!isDark ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))] : []),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
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
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        alignment: Alignment.center,
                                        child: Text(
                                          text, 
                                          style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.grey : Colors.grey.shade700), fontWeight: FontWeight.bold, fontSize: 16)
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (isCustomLimit) ...[
                            const Gap(8),
                            _buildCustomInlineInput(
                              controller: _customLimitCtrl, 
                              hint: settings.t('custom_limit_hint'), 
                              isNumber: true,
                              cardColor: cardColor, 
                              textColor: textColor,
                              isDark: isDark,
                              onChanged: (val) {
                                int? num = int.tryParse(val);
                                setState(() {
                                  if (num != null && num > 0) {
                                    questionLimit = num > 1000 ? 1000 : num;
                                  } else {
                                    questionLimit = 0;
                                  }
                                });
                              }
                            ),
                          ],
                          const Gap(24),
                        ],
                      ),
                    ),

                    _buildLabel(settings.t('comm_format')),
                    const Gap(12),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildFeedbackCard('style_friendly', false, cardColor, textColor, settings, isDark)),
                            const Gap(12),
                            Expanded(child: _buildFeedbackCard('style_strict', false, cardColor, textColor, settings, isDark)),
                          ],
                        ),
                        const Gap(12),
                        Row(
                          children: [
                            Expanded(child: _buildFeedbackCard('style_stress', true, cardColor, textColor, settings, isDark)),
                            const Gap(12),
                            Expanded(child: _buildFeedbackCard('style_pedant', true, cardColor, textColor, settings, isDark)),
                          ],
                        ),
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
                    // СТАЛО (Глубокий графитовый на светлой теме):
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

                    String translatedRole = currentRoleKey == 'custom_opt' && _customRoleCtrl.text.isNotEmpty 
                        ? _customRoleCtrl.text 
                        : settings.t(currentRoleKey);
                        
                    String translatedPersona = selectedPersonaKey == 'custom_opt' && _customPersonaCtrl.text.isNotEmpty 
                        ? _customPersonaCtrl.text 
                        : settings.t(selectedPersonaKey);
                        
                    String translatedDifficulty = settings.t(selectedDifficultyKey);
                    String translatedFeedback = settings.t(feedbackStyleKey);
                    
                    final profileProvider = context.read<ProfileProvider>();
                    final authProvider = context.read<AuthProvider>();

                    final config = SessionConfig(
                      role: translatedRole, 
                      persona: translatedPersona, 
                      difficulty: translatedDifficulty, 
                      questionLimit: questionLimit,  
                      feedbackStyle: translatedFeedback, 
                      includeLegend: includeLegend, 
                      isTeachingMode: isTeachingMode, 
                      isEndlessMode: isEndlessMode, 
                      userName: authProvider.currentUsername ?? "User", 
                      userBio: profileProvider.userBio,
                      isRoleplayMode: true, 
                      language: settings.currentLanguage,
                    );
                    
                    await context.read<InterviewProvider>().clearChat();
                    context.read<InterviewProvider>().setConfig(config);
                    final result = await context.read<InterviewProvider>().startSession(config);

                    if (!mounted) return;
                    setState(() => isStartingSession = false);

                    if (result['success']) {
                      authProvider.updateBalance(result['new_balance'].toDouble());
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(role: translatedRole)));
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
                        // Добавили Padding внутри FittedBox, чтобы текст не зажимало рамками кнопки
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(settings.t('start_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Gap(8),
                              Builder(builder: (context) {
                                double currentCost = isEndlessMode ? 55.0 : (questionLimit * 0.5);
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
        border: Border.all(color: isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade300),
        // Легкая тень для элементов на белом фоне
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, Color cardColor, Color? textColor, bool isDark, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade300),
        boxShadow: !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))] : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold))),
          Switch(value: value, activeColor: Colors.blueAccent, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(String styleKey, bool isHarsh, Color cardColor, Color? textColor, SettingsProvider settings, bool isDark) {
    bool isSelected = feedbackStyleKey == styleKey;
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
          onTap: () => setState(() => feedbackStyleKey = styleKey),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(settings.t(styleKey), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)
                    ), 
                    if (isHarsh) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                  ]
                ),
                const Gap(6), 
                Text(settings.t('${styleKey}_desc'), style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}