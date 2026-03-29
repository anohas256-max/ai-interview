import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:sobes/features/interview/presentation/pages/chat_page.dart';
import 'package:sobes/features/interview/domain/entities/session_config.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';
import 'package:sobes/features/profile/presentation/providers/profile_provider.dart';
import 'package:sobes/features/catalog/presentation/providers/catalog_provider.dart';
// 👇 ДОБАВЛЕН ПРОВАЙДЕР АВТОРИЗАЦИИ 👇
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart';

const List<String> availablePersonas = [
  'Строгий HR-менеджер', 'Добродушный рекрутер', 'Придирчивый Техлид', 
  'Простофиля (вообще не шарит)', 'Свой вариант ✍️'
];

const List<String> availableDifficulties = [
  'Junior (Базовый)', 'Middle (Средний)', 'Senior (Хардкор)', 'Progressive (Адаптивно)'
];

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String selectedRole = 'Свой вариант ✍️';
  String selectedPersona = availablePersonas[0];
  String selectedDifficulty = availableDifficulties[3];
  
  String feedbackStyle = 'По делу'; 
  
  bool includeLegend = true;
  bool isTeachingMode = false;
  bool isEndlessMode = false;
  
  int questionLimit = 5;
  bool isCustomLimit = false;

  final TextEditingController _customRoleCtrl = TextEditingController();
  final TextEditingController _customPersonaCtrl = TextEditingController();
  final TextEditingController _customLimitCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final List<String> dynamicRoles = [...catalogProvider.interviewRoles, 'Свой вариант ✍️'];
    
    String currentRole = dynamicRoles.contains(selectedRole) ? selectedRole : dynamicRoles.first;

    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Настройка собеседования", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    _buildLabel("ЖЕЛАЕМАЯ ДОЛЖНОСТЬ"),
                    const Gap(8),
                    _buildDropdown(value: currentRole, items: dynamicRoles, onChanged: (val) => setState(() => selectedRole = val!)),
                    if (currentRole == 'Свой вариант ✍️') ...[
                      const Gap(8),
                      _buildCustomInlineInput(controller: _customRoleCtrl, hint: "Например: Капитан подводной лодки", maxLength: 50),
                    ],
                    const Gap(24),

                    _buildLabel("ТИП ИНТЕРВЬЮЕРА"),
                    const Gap(8),
                    _buildDropdown(value: selectedPersona, items: availablePersonas, onChanged: (val) => setState(() => selectedPersona = val!)),
                    if (selectedPersona == 'Свой вариант ✍️') ...[
                      const Gap(8),
                      _buildCustomInlineInput(controller: _customPersonaCtrl, hint: "Например: Кот, который умеет говорить", maxLength: 50),
                    ],
                    const Gap(24),

                    _buildLabel("УРОВЕНЬ СЛОЖНОСТИ"),
                    const Gap(8),
                    _buildDropdown(value: selectedDifficulty, items: availableDifficulties, onChanged: (val) => setState(() => selectedDifficulty = val!)),
                    const Gap(24),

                    _buildLabel("РЕЖИМЫ РАБОТЫ"),
                    const Gap(8),
                    _buildToggleRow("Вводная часть (Опыт и скиллы)", includeLegend, (val) => setState(() => includeLegend = val)),
                    const Gap(8),
                    _buildToggleRow("Режим обучения 🎓 (Разбор ошибок)", isTeachingMode, (val) => setState(() => isTeachingMode = val)),
                    const Gap(8),
                    _buildToggleRow("Бесконечный режим ♾️", isEndlessMode, (val) => setState(() => isEndlessMode = val)),
                    const Gap(24),

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: isEndlessMode ? const SizedBox.shrink() : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("КОЛИЧЕСТВО ВОПРОСОВ"),
                          const Gap(12),
                          Row(
                            children: [2, 5, 10, -1].map((limit) {
                              final isCustomBtn = limit == -1;
                              final isSelected = isCustomBtn ? isCustomLimit : (!isCustomLimit && questionLimit == limit);
                              final text = isCustomBtn ? "Свой ⚙️" : "$limit";
                              
                              return Expanded(
                                child: GestureDetector(
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
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: isSelected ? Colors.white : const Color(0xFF151515), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
                                    child: Text(text, style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (isCustomLimit) ...[
                            const Gap(8),
                            _buildCustomInlineInput(
                              controller: _customLimitCtrl, 
                              hint: "Введите количество (макс 1000)", 
                              isNumber: true,
                              onChanged: (val) {
                                int? num = int.tryParse(val);
                                if (num != null && num > 0) questionLimit = num > 1000 ? 1000 : num;
                              }
                            ),
                          ],
                          const Gap(24),
                        ],
                      ),
                    ),

                    _buildLabel("ФОРМАТ ОБЩЕНИЯ"),
                    const Gap(12),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildFeedbackCard("Дружелюбный", "Мягко и с поддержкой", false)),
                            const Gap(12),
                            Expanded(child: _buildFeedbackCard("По делу", "Сухо и конструктивно", false)),
                          ],
                        ),
                        const Gap(12),
                        Row(
                          children: [
                            Expanded(child: _buildFeedbackCard("Стресс-тест", "Давит и торопит", true)),
                            const Gap(12),
                            Expanded(child: _buildFeedbackCard("Душнила", "Докопается до мелочей", true)),
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
                  onPressed: () {
                    String finalRole = currentRole == 'Свой вариант ✍️' && _customRoleCtrl.text.isNotEmpty ? _customRoleCtrl.text : currentRole;
                    String finalPersona = selectedPersona == 'Свой вариант ✍️' && _customPersonaCtrl.text.isNotEmpty ? _customPersonaCtrl.text : selectedPersona;
                    
                    final profileProvider = context.read<ProfileProvider>();
                    // 👇 БЕРЕМ ИМЯ ИЗ AUTH PROVIDER 👇
                    final authProvider = context.read<AuthProvider>();

                    final config = SessionConfig(
                      role: finalRole, persona: finalPersona, difficulty: selectedDifficulty, questionLimit: questionLimit,  
                      feedbackStyle: feedbackStyle, includeLegend: includeLegend, isTeachingMode: isTeachingMode, 
                      isEndlessMode: isEndlessMode, 
                      userName: authProvider.currentUsername ?? "User", // 👈 ИСПРАВЛЕНА ОШИБКА
                      userBio: profileProvider.userBio,
                      isRoleplayMode: true, 
                    );
                    
                    context.read<InterviewProvider>().clearChat();
                    context.read<InterviewProvider>().setConfig(config);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(role: finalRole)));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const StadiumBorder()),
                  child: const Text("Начать собеседование", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildCustomInlineInput({required TextEditingController controller, required String hint, bool isNumber = false, int? maxLength, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      maxLength: maxLength,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: Colors.grey[700]),
        filled: true, fillColor: const Color(0xFF1C1C1E), counterText: "", 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
          Switch(value: value, activeColor: Colors.black, activeTrackColor: Colors.white, inactiveThumbColor: Colors.grey, inactiveTrackColor: Colors.grey[800], onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(String title, String subtitle, bool isHarsh) {
    bool isSelected = feedbackStyle == title;
    return GestureDetector(
      onTap: () => setState(() => feedbackStyle = title),
      child: Container(
        padding: const EdgeInsets.all(12), height: 100,
        decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.1), width: isSelected ? 2 : 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)), 
              if (isHarsh) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
            ]),
            const Gap(6), 
            Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}