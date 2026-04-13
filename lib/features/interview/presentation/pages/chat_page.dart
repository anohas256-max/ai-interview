import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:sobes/features/interview/presentation/pages/analysis_page.dart';
import 'package:sobes/features/interview/presentation/widgets/chat_bubble.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';
import 'package:sobes/core/providers/settings_provider.dart'; 
import '../widgets/audio_recorder_btn.dart';

class ChatPage extends StatefulWidget {
  final String role;
  const ChatPage({super.key, required this.role});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isBullshitting = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InterviewProvider>();

      if (provider.messages.isEmpty) {
        provider.startInterview();
      } else if (!provider.isFinished) {
        provider.resumeTimer();
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    _controller.clear();
    setState(() => _isBullshitting = false);

    context.read<InterviewProvider>().sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();
    final settings = context.watch<SettingsProvider>(); 
    final messages = provider.messages;
    final isLoading = provider.isLoading;

    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: Center( 
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), 
          child: Stack(
            children: [
              Column(
                children: [
                  // 👇 --- ИДЕАЛЬНАЯ ШАПКА ЧАТА --- 👇
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // 1. Кнопка "Назад"
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: textColor), 
                            onPressed: () {
                              context.read<InterviewProvider>().pauseTimer();
                              Navigator.pop(context);
                            },
                          ),
                          
                          const Spacer(), // 2. Расталкиваем элементы по краям
                          
                          // 3. Кнопка звука (теперь она прижата вправо)
                          IconButton(
                            icon: Icon(
                              provider.isVoiceEnabled ? Icons.volume_up : Icons.volume_off,
                              color: provider.isVoiceEnabled ? Colors.blueAccent : Colors.grey,
                            ),
                            onPressed: () => provider.toggleVoice(),
                          ),
                          
                          const Gap(8), // Небольшой отступ между звуком и кнопкой END

                          // 4. Кнопка завершения с ПЕРЕВОДОМ
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => const AnalysisPage())
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                            ),
                            child: Text(
                              settings.t('end'), // 👈 Перевод работает здесь
                              style: const TextStyle(color: Color(0xFFFF453A), fontWeight: FontWeight.bold, fontSize: 16)
                            ), 
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 👆 --- КОНЕЦ ШАПКИ --- 👆

                  // --- СПИСОК СООБЩЕНИЙ ---
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        
                        if (index == messages.length && isLoading) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 8, right: 60),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5),
                                boxShadow: [
                                  BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 10)
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16, 
                                    height: 16, 
                                    child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2.5),
                                  ),
                                  const Gap(12),
                                  Text(settings.t('ai_typing'), style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                          );
                        }

                        final msg = messages[index];
                        return ChatBubble(
                          text: msg.text,
                          isUser: msg.isUser,
                        );
                      },
                    ),
                  ),

                  // --- КНОПКА ПОВТОРА ПРИ ОШИБКЕ ---
                  if (messages.isNotEmpty && !messages.last.isUser && messages.last.text.contains('⚠️'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            provider.retryLastMessage();
                            _scrollToBottom();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: Text(settings.t('retry_send'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                    ),

                  // --- ПАНЕЛЬ ВВОДА ИЛИ КНОПКА ЗАВЕРШЕНИЯ ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor, 
                      border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))), 
                    ),
                    child: SafeArea(
                      child: (provider.isFailed || provider.isFinished) 
                        ? SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (_) => const AnalysisPage())
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: provider.isFailed ? const Color(0xFFB71C1C) : const Color(0xFF2E7D32),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center, 
                                children: [
                                  Icon(
                                    provider.isFailed ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                    color: Colors.white,
                                  ),
                                  const Gap(12),
                                  Expanded( 
                                    child: Text(
                                      provider.isFailed ? settings.t('interview_aborted') : settings.t('session_finished'), 
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                      maxLines: 2, 
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AudioRecorderBtn(
                                textController: _controller,
                                isDisabled: isLoading,
                              ),
                              const Gap(4), 
                              
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cardColor, 
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _controller,
                                          minLines: 1,
                                          maxLines: 4,
                                          maxLength: provider.isLegendPhase ? 1000 : 5000, 
                                          style: TextStyle(color: textColor), 
                                          enabled: !isLoading, 
                                          decoration: InputDecoration(
                                            hintText: provider.isLegendPhase ? settings.t('legend_hint') : (isLoading ? settings.t('ai_typing') : settings.t('your_answer')),
                                            hintStyle: const TextStyle(color: Colors.grey),
                                            border: InputBorder.none,
                                            counterText: "", 
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: IconButton(
                                          icon: const Icon(Icons.arrow_upward, color: Colors.white),
                                          style: IconButton.styleFrom(
                                            backgroundColor: isLoading ? Colors.transparent : Colors.blueAccent, 
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          onPressed: isLoading ? null : _sendMessage,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
              
              if (_isBullshitting)
                IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isBullshitting ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.withOpacity(0.6), width: 4),
                        gradient: RadialGradient(colors: [Colors.transparent, Colors.red.withOpacity(0.15)], radius: 1.5),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48), 
                            const Gap(8),
                            Text(settings.t('fluff_warn'), style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}