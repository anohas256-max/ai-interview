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

const List<String> availablePersonasKeys = [
  'persona_hr',
  'persona_recruiter',
  'persona_techlead',
  'persona_fool',
  'custom_opt',
];

const List<String> availableDifficultiesKeys = [
  'diff_basic',
  'diff_intermediate',
  'diff_advanced',
  'diff_expert',
  'diff_progressive',
];

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  String? selectedRoleKey;
  String selectedPersonaKey = availablePersonasKeys[0];
  String selectedDifficultyKey = availableDifficultiesKeys[1];

  String feedbackStyleKey = 'style_strict';

  bool includeLegend = true;
  bool isTeachingMode = false;
  bool isEndlessMode = false;

  int questionLimit = 5;
  bool isCustomLimit = false;
  bool isStartingSession = false;

  bool isRolePickerOpen = false;
  bool skipDeleteConfirm = false;

  final TextEditingController _customRoleCtrl = TextEditingController();
  final TextEditingController _customPersonaCtrl = TextEditingController();
  final TextEditingController _customLimitCtrl = TextEditingController();

  @override
  void dispose() {
    _customRoleCtrl.dispose();
    _customPersonaCtrl.dispose();
    _customLimitCtrl.dispose();
    super.dispose();
  }

  String _displayItem(String item, SettingsProvider settings) {
    final translated = settings.t(item);
    return translated == item ? item : translated;
  }

  int _clampQuestionLimit(int? value) {
    if (value == null) return 3;
    if (value < 3) return 3;
    if (value > 100) return 100;
    return value;
  }

  Future<void> _saveCustomRole({
    required CatalogProvider catalogProvider,
    required String value,
  }) async {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (normalized.length < 2) return;

    final ok = await catalogProvider.saveCustomRoleplayPreset(normalized);

    if (!mounted) return;

    if (ok) {
      setState(() {
        selectedRoleKey = normalized;
        isRolePickerOpen = false;
        _customRoleCtrl.clear();
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Роль сохранена'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

Future<bool> _confirmDelete({
  required String title,
  required String kind,
}) async {
  if (skipDeleteConfirm) return true;

  bool dontAskAgain = false;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
      final textColor = isDark ? Colors.white : const Color(0xFF25242A);
      final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Удалить $kind?',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Точно удалить "$title"?',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 18),

                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setDialogState(() {
                          dontAskAgain = !dontAskAgain;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.035),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Checkbox(
                                value: dontAskAgain,
                                activeColor: Colors.redAccent,
                                onChanged: (value) {
                                  setDialogState(() {
                                    dontAskAgain = value ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Больше не спрашивать',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext, false);
                              },
                              child: const Text(
                                'Отмена',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext, true);
                              },
                              child: const Text(
                                'Удалить',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  if (confirmed == true && dontAskAgain) {
    setState(() {
      skipDeleteConfirm = true;
    });
  }

  return confirmed == true;
}

  Future<void> _deleteCustomRole(String title) async {
    final confirmed = await _confirmDelete(title: title, kind: 'роль');
    if (!confirmed) return;

    final catalogProvider = context.read<CatalogProvider>();
    final ok = await catalogProvider.deleteCustomRoleplayPreset(title);

    if (!mounted) return;

    if (ok) {
      final roles = catalogProvider.interviewRoles
          .where((role) => role != title)
          .where((role) => role != 'Loading...')
          .toList();

      setState(() {
        if (selectedRoleKey == title) {
          selectedRoleKey = roles.isNotEmpty ? roles.first : 'custom_opt';
        }
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Роль удалена'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<CatalogProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final bgColor =
        isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade50;
    final cardColor = isDark ? Theme.of(context).cardColor : Colors.white;

    final List<String> dynamicRolesKeys = [
      ...catalogProvider.interviewRoles,
      'custom_opt',
    ];

    if (selectedRoleKey == null) {
      selectedRoleKey = catalogProvider.interviewRoles.isNotEmpty
          ? catalogProvider.interviewRoles.first
          : 'custom_opt';
    } else if (!dynamicRolesKeys.contains(selectedRoleKey)) {
      selectedRoleKey = 'custom_opt';
    }

    final systemRoles = catalogProvider.interviewRoles
        .where((role) => !catalogProvider.isCustomRoleplayPreset(role))
        .where((role) => role != 'Loading...')
        .toList();

    final customRoles = catalogProvider.customRoleplayPresets;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          settings.t('setup_title'),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            height: 1.1,
          ),
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
                    _buildLabel(settings.t('desired_role')),
                    const Gap(6),
                    _buildPickerTile(
                      value: selectedRoleKey == 'custom_opt'
                          ? settings.t('custom_opt')
                          : _displayItem(selectedRoleKey!, settings),
                      cardColor: cardColor,
                      textColor: textColor,
                      isDark: isDark,
                      isOpen: isRolePickerOpen,
                      onTap: () {
                        setState(() {
                          isRolePickerOpen = !isRolePickerOpen;
                        });
                      },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: isRolePickerOpen
                          ? _buildInlinePresetList(
                              settings: settings,
                              isDark: isDark,
                              cardColor: cardColor,
                              textColor: textColor,
                              selectedValue: selectedRoleKey,
                              systemTitle: 'Системные роли',
                              customTitle: 'Кастомные роли',
                              customAddTitle: settings.t('custom_opt'),
                              systemItems: systemRoles,
                              customItems: customRoles,
                              onSelect: (value) {
                                setState(() {
                                  selectedRoleKey = value;
                                  isRolePickerOpen = false;
                                });
                              },
                              onDeleteCustom: _deleteCustomRole,
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (selectedRoleKey == 'custom_opt') ...[
                      const Gap(8),
                      _buildCustomInlineInput(
                        controller: _customRoleCtrl,
                        hint: settings.t('custom_role_hint'),
                        maxLength: 100,
                        cardColor: cardColor,
                        textColor: textColor,
                        isDark: isDark,
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () async {
                            await _saveCustomRole(
                              catalogProvider: context.read<CatalogProvider>(),
                              value: _customRoleCtrl.text,
                            );
                          },
                        ),
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
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => selectedPersonaKey = val);
                      },
                    ),
                    if (selectedPersonaKey == 'custom_opt') ...[
                      const Gap(8),
                      _buildCustomInlineInput(
                        controller: _customPersonaCtrl,
                        hint: settings.t('custom_persona_hint'),
                        maxLength: 50,
                        cardColor: cardColor,
                        textColor: textColor,
                        isDark: isDark,
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
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => selectedDifficultyKey = val);
                      },
                    ),
                    const Gap(24),
                    _buildLabel(settings.t('work_modes')),
                    const Gap(6),
                    _buildToggleRow(
                      settings.t('intro_legend'),
                      includeLegend,
                      cardColor,
                      textColor,
                      isDark,
                      (val) => setState(() => includeLegend = val),
                    ),
                    const Gap(8),
                    _buildToggleRow(
                      settings.t('teaching_mode'),
                      isTeachingMode,
                      cardColor,
                      textColor,
                      isDark,
                      (val) => setState(() => isTeachingMode = val),
                    ),
                    const Gap(8),
                    _buildToggleRow(
                      settings.t('endless_mode'),
                      isEndlessMode,
                      cardColor,
                      textColor,
                      isDark,
                      (val) => setState(() => isEndlessMode = val),
                    ),
                    const Gap(24),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutBack,
                      child: isEndlessMode
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(settings.t('question_count')),
                                const Gap(12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [3, 5, 10, -1].map((limit) {
                                    final isCustomBtn = limit == -1;
                                    final isSelected = isCustomBtn
                                        ? isCustomLimit
                                        : (!isCustomLimit &&
                                            questionLimit == limit);
                                    final text = isCustomBtn ? '⚙️' : '$limit';

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
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: isCustomBtn ? 50 : 60,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blueAccent
                                              : cardColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.blueAccent
                                                : (isDark
                                                    ? Colors.white10
                                                    : Colors.black
                                                        .withOpacity(0.08)),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Text(
                                          text,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark
                                                    ? Colors.grey
                                                    : Colors.grey.shade700),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
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
                                    hint: 'Кол-во (3–100)',
                                    isNumber: true,
                                    maxLength: 3,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    isDark: isDark,
                                    onChanged: (val) {
  final parsed = int.tryParse(val);

  if (parsed == null) {
    setState(() {
      questionLimit = 3;
    });
    return;
  }

  if (parsed < 3) {
    setState(() {
      questionLimit = 3;
      _customLimitCtrl.text = '3';
      _customLimitCtrl.selection = TextSelection.fromPosition(
        const TextPosition(offset: 1),
      );
    });
    return;
  }

  if (parsed > 100) {
    setState(() {
      questionLimit = 100;
      _customLimitCtrl.text = '100';
      _customLimitCtrl.selection = TextSelection.fromPosition(
        const TextPosition(offset: 3),
      );
    });
    return;
  }

  setState(() {
    questionLimit = parsed;
  });
},
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
                            Expanded(
                              child: _buildFeedbackCard(
                                'style_friendly',
                                false,
                                cardColor,
                                textColor,
                                settings,
                                isDark,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: _buildFeedbackCard(
                                'style_strict',
                                false,
                                cardColor,
                                textColor,
                                settings,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                        const Gap(12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeedbackCard(
                                'style_stress',
                                true,
                                cardColor,
                                textColor,
                                settings,
                                isDark,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: _buildFeedbackCard(
                                'style_pedant',
                                true,
                                cardColor,
                                textColor,
                                settings,
                                isDark,
                              ),
                            ),
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
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    elevation: isDark ? 4 : 2,
                    shadowColor: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.transparent : Colors.black87,
                      ),
                    ),
                  ),
                  onPressed: isStartingSession
                      ? null
                      : () async {
                          setState(() => isStartingSession = true);

                          String translatedRole;

                          if (selectedRoleKey == 'custom_opt' &&
                              _customRoleCtrl.text.trim().isNotEmpty) {
                            translatedRole = _customRoleCtrl.text.trim();
                          } else {
                            translatedRole =
                                _displayItem(selectedRoleKey!, settings);
                          }

                          final translatedPersona =
                              selectedPersonaKey == 'custom_opt' &&
                                      _customPersonaCtrl.text.trim().isNotEmpty
                                  ? _customPersonaCtrl.text.trim()
                                  : settings.t(selectedPersonaKey);

                          final translatedDifficulty =
                              settings.t(selectedDifficultyKey);
                          final translatedFeedback =
                              settings.t(feedbackStyleKey);

                          final profileProvider =
                              context.read<ProfileProvider>();
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
                            userName: authProvider.currentUsername ?? 'User',
                            userBio: profileProvider.userBio,
                            isRoleplayMode: true,
                            language: settings.currentLanguage,
                          );

                          await context.read<InterviewProvider>().clearChat();
                          context.read<InterviewProvider>().setConfig(config);

                          final result = await context
                              .read<InterviewProvider>()
                              .startSession(config);

                          if (!mounted) return;
                          setState(() => isStartingSession = false);

                          if (result['success']) {
                            authProvider.updateBalance(
                              result['new_balance'].toDouble(),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(role: translatedRole),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                    ),
                                    const Gap(12),
                                    Text(result['error'] ?? 'Ошибка оплаты'),
                                  ],
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                  child: isStartingSession
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  settings.t('start_btn'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Gap(8),
                                Builder(
                                  builder: (context) {
                                    final currentCost = isEndlessMode
                                        ? 55.0
                                        : (questionLimit * 0.5);
                                    final priceText = currentCost % 1 == 0
                                        ? currentCost.toInt().toString()
                                        : currentCost.toString();
                                    final priceColor = isDark
                                        ? Colors.amberAccent
                                        : Colors.amber;

                                    return Text(
                                      '(Цена: $priceText ⚡️)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: priceColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildPickerTile({
    required String value,
    required Color cardColor,
    required Color? textColor,
    required bool isDark,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOpen
                ? Colors.blueAccent
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
            width: isOpen ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedRotation(
              turns: isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: isDark ? Colors.grey : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlinePresetList({
    required SettingsProvider settings,
    required bool isDark,
    required Color cardColor,
    required Color? textColor,
    required String? selectedValue,
    required String systemTitle,
    required String customTitle,
    required String customAddTitle,
    required List<String> systemItems,
    required List<String> customItems,
    required Function(String value) onSelect,
    required Future<void> Function(String title) onDeleteCustom,
  }) {
    final borderColor = isDark ? Colors.white10 : Colors.black.withOpacity(0.08);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInlineSectionTitle(systemTitle),
          ...systemItems.map(
            (item) => _buildInlinePresetRow(
              title: _displayItem(item, settings),
              rawValue: item,
              isSelected: item == selectedValue,
              isDark: isDark,
              canDelete: false,
              onSelect: onSelect,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              color: isDark ? Colors.white12 : Colors.black12,
              height: 18,
            ),
          ),
          _buildInlineSectionTitle(customTitle),
          if (customItems.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Text(
                'Пока нет сохранённых',
                style: TextStyle(
                  color: isDark ? Colors.grey : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
          ...customItems.map(
            (item) => _buildInlinePresetRow(
              title: item,
              rawValue: item,
              isSelected: item == selectedValue,
              isDark: isDark,
              canDelete: true,
              onSelect: onSelect,
              onDelete: () async {
                await onDeleteCustom(item);
              },
            ),
          ),
          _buildInlinePresetRow(
            title: customAddTitle,
            rawValue: 'custom_opt',
            isSelected: selectedValue == 'custom_opt',
            isDark: isDark,
            canDelete: false,
            leadingIcon: Icons.edit_note_rounded,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }

  Widget _buildInlineSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInlinePresetRow({
    required String title,
    required String rawValue,
    required bool isSelected,
    required bool isDark,
    required bool canDelete,
    required Function(String value) onSelect,
    IconData? leadingIcon,
    Future<void> Function()? onDelete,
  }) {
    return Material(
      color: isSelected
          ? Colors.blueAccent.withOpacity(isDark ? 0.22 : 0.10)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(rawValue),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                leadingIcon ??
                    (isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off),
                color: isSelected ? Colors.blueAccent : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canDelete)
                IconButton(
                  tooltip: 'Удалить',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 21,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Color cardColor,
    required Color? textColor,
    required SettingsProvider settings,
    required bool isDark,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          dropdownColor: cardColor,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.grey : Colors.grey.shade700,
          ),
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(_displayItem(item, settings)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCustomInlineInput({
    required TextEditingController controller,
    required String hint,
    required Color cardColor,
    required Color? textColor,
    required bool isDark,
    bool isNumber = false,
    int? maxLength,
    Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      maxLength: maxLength,
      onChanged: onChanged,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey : Colors.grey.shade500,
        ),
        filled: true,
        fillColor: cardColor,
        counterText: '',
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.blueAccent,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    bool value,
    Color cardColor,
    Color? textColor,
    bool isDark,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.blueAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(
    String styleKey,
    bool isHarsh,
    Color cardColor,
    Color? textColor,
    SettingsProvider settings,
    bool isDark,
  ) {
    final isSelected = feedbackStyleKey == styleKey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: 100,
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueAccent.withOpacity(0.08) : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Colors.blueAccent
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          width: isSelected ? 2 : 1.2,
        ),
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
                      child: Text(
                        settings.t(styleKey),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHarsh)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const Gap(6),
                Text(
                  settings.t('${styleKey}_desc'),
                  style: TextStyle(
                    color: isDark ? Colors.grey : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
