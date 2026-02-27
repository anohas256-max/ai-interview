import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:sobes/features/interview/presentation/pages/chat_page.dart';
import 'package:sobes/features/interview/domain/entities/session_config.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';

// 👇 ДОБАВЬ ВОТ ЭТУ СТРОЧКУ 👇
import 'package:sobes/features/profile/presentation/providers/profile_provider.dart';

// --- ЛЕГКО РЕДАКТИРУЕМЫЕ СПИСКИ ---
const List<String> availableRoles = [
  'Java-разработчик', 'Frontend (React/Vue)', 'Product Manager', 
  'DevOps-инженер', 'Пчеловод', 'Дайвер-инструктор',
  'Шеф-повар ресторана', 'Специалист по кибербезопасности',
  'Свой вариант ✍️' // Оставляем последним
];

const List<String> availablePersonas = [
  'Строгий HR-менеджер', 'Добродушный рекрутер', 'Придирчивый Техлид', 
  'Простофиля (вообще не шарит)', 'Топ-менеджер (CEO)', 'Душный эксперт',
  'Свой вариант ✍️' // Оставляем последним
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
  
  // --- ТЕКУЩЕЕ СОСТОЯНИЕ ---
  String selectedRole = availableRoles[0];
  String selectedPersona = availablePersonas[0];
  String selectedDifficulty = availableDifficulties[3];
  
  // Изначально "По делу", чтобы выделялась зеленая рамка
  String feedbackStyle = 'По делу'; 
  
  bool includeLegend = true;
  bool isTeachingMode = false;
  bool isEndlessMode = false;
  
  // Лимиты
  int questionLimit = 5;
  bool isCustomLimit = false;

  // Контроллеры для кастомных полей
  final TextEditingController _customRoleCtrl = TextEditingController();
  final TextEditingController _customPersonaCtrl = TextEditingController();
  final TextEditingController _customLimitCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text("Настройка собеседования", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: false, 
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
                    
                    // --- 1. РОЛЬ ---
                    _buildLabel("ЖЕЛАЕМАЯ ДОЛЖНОСТЬ"),
                    const Gap(8),
                    _buildDropdown(value: selectedRole, items: availableRoles, onChanged: (val) => setState(() => selectedRole = val!)),
                    if (selectedRole == 'Свой вариант ✍️') ...[
                      const Gap(8),
                      _buildCustomInlineInput(controller: _customRoleCtrl, hint: "Например: Капитан подводной лодки", maxLength: 50),
                    ],

                    const Gap(24),

                    // --- 2. ПЕРСОНА ---
                    _buildLabel("ТИП ИНТЕРВЬЮЕРА"),
                    const Gap(8),
                    _buildDropdown(value: selectedPersona, items: availablePersonas, onChanged: (val) => setState(() => selectedPersona = val!)),
                    if (selectedPersona == 'Свой вариант ✍️') ...[
                      const Gap(8),
                      _buildCustomInlineInput(controller: _customPersonaCtrl, hint: "Например: Кот, который умеет говорить", maxLength: 50),
                    ],

                    const Gap(24),

                    // --- 3. СЛОЖНОСТЬ ---
                    _buildLabel("УРОВЕНЬ СЛОЖНОСТИ"),
                    const Gap(8),
                    _buildDropdown(value: selectedDifficulty, items: availableDifficulties, onChanged: (val) => setState(() => selectedDifficulty = val!)),

                    const Gap(24),

                    // --- 4. РЕЖИМЫ (ТОГЛЫ) ---
                    _buildLabel("РЕЖИМЫ РАБОТЫ"),
                    const Gap(8),
                    _buildToggleRow("Вводная часть (Опыт и скиллы)", includeLegend, (val) => setState(() => includeLegend = val)),
                    const Gap(8),
                    _buildToggleRow("Режим обучения 🎓 (Разбор ошибок)", isTeachingMode, (val) => setState(() => isTeachingMode = val)),
                    const Gap(8),
                    _buildToggleRow("Бесконечный режим ♾️", isEndlessMode, (val) => setState(() => isEndlessMode = val)),

                    const Gap(24),

                    // --- 5. ЛИМИТ ВОПРОСОВ (Скрываем, если включена бесконечность) ---
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: isEndlessMode ? const SizedBox.shrink() : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("КОЛИЧЕСТВО ТЕХ. ВОПРОСОВ"),
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
                                if (num != null && num > 0) {
                                  questionLimit = num > 1000 ? 1000 : num; // Ограничение 1000
                                }
                              }
                            ),
                          ],
                          const Gap(24),
                        ],
                      ),
                    ),

                    // --- 6. ФОРМАТ ОБЩЕНИЯ ---
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

            // --- КНОПКА СТАРТ ---
            // --- КНОПКА СТАРТ ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    String finalRole = selectedRole == 'Свой вариант ✍️' && _customRoleCtrl.text.isNotEmpty ? _customRoleCtrl.text : selectedRole;
                    String finalPersona = selectedPersona == 'Свой вариант ✍️' && _customPersonaCtrl.text.isNotEmpty ? _customPersonaCtrl.text : selectedPersona;

                    // 👇 1. СТУЧИМСЯ В ПУЛЬТ ПРОФИЛЯ 👇
                    // (Убедись, что импортировал ProfileProvider сверху файла!)
                    final profileProvider = context.read<ProfileProvider>();

                    // 2. Собираем конфиг
                    final config = SessionConfig(
                      role: finalRole,               
                      persona: finalPersona,         
                      difficulty: selectedDifficulty,
                      questionLimit: questionLimit,  
                      feedbackStyle: feedbackStyle,  
                      
                      includeLegend: includeLegend,   
                      isTeachingMode: isTeachingMode, 
                      isEndlessMode: isEndlessMode,   
                      
                      // 👇 3. БЕРЕМ РЕАЛЬНЫЕ ДАННЫЕ ИЗ ПРОФИЛЯ 👇
                      userName: profileProvider.userName, 
                      userBio: profileProvider.userBio, 
                    );

                    context.read<InterviewProvider>().setConfig(config);
                    context.read<InterviewProvider>().startInterview();
                    
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(role: finalRole)));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: const StadiumBorder()),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Начать собеседование", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Gap(8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
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

  // Инлайн инпут для своих вариантов
  Widget _buildCustomInlineInput({required TextEditingController controller, required String hint, bool isNumber = false, int? maxLength, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      maxLength: maxLength,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[700]),
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        counterText: "", // Скрываем счетчик символов снизу
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
    return _FeedbackCard(title: title, subtitle: subtitle, isSelected: feedbackStyle == title, isHarsh: isHarsh, onTap: () => setState(() => feedbackStyle = title));
  }
}

class _FeedbackCard extends StatelessWidget {
  final String title; final String subtitle; final bool isSelected; final bool isHarsh; final VoidCallback onTap;
  const _FeedbackCard({required this.title, required this.subtitle, required this.isSelected, this.isHarsh = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12), height: 100,
        decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.1), width: isSelected ? 2 : 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)), if (isHarsh) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))]),
            const Gap(6), Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}