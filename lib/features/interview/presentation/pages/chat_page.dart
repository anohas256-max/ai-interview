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

  // 👇 ДИАЛОГ ПОДТВЕРЖДЕНИЯ ЗАВЕРШЕНИЯ 👇
  Future<bool?> _showEndConfirmDialog(BuildContext context, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const Gap(8),
            Expanded(
              child: Text(
                settings.t('end_chat_title') != 'end_chat_title' ? settings.t('end_chat_title') : 'Завершить чат?', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
            ),
          ],
        ),
        content: Text(
          settings.t('end_chat_desc') != 'end_chat_desc' 
              ? settings.t('end_chat_desc') 
              : 'Вы уверены, что хотите досрочно завершить собеседование? Это действие необратимо.',
          style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontSize: 14, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              settings.t('cancel') != 'cancel' ? settings.t('cancel') : 'Отмена', 
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              settings.t('confirm_end') != 'confirm_end' ? settings.t('confirm_end') : 'Завершить', 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();
    final settings = context.watch<SettingsProvider>(); 
    final messages = provider.messages;
    final isLoading = provider.isLoading;

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: textColor), 
                            onPressed: () {
                              context.read<InterviewProvider>().pauseTimer();
                              Navigator.pop(context);
                            },
                          ),
                          
                          const Spacer(), 
                          
                          // Красивая кнопка "Завершить" с подтверждением
                          ElevatedButton.icon(
                            onPressed: () async {
                              context.read<InterviewProvider>().pauseTimer();
                              
                              final shouldEnd = await _showEndConfirmDialog(context, settings);
                              if (!context.mounted) return;
                              
                              if (shouldEnd == true) {
                                Navigator.pushReplacement(
                                  context, 
                                  MaterialPageRoute(builder: (_) => const AnalysisPage())
                                );
                              } else {
                                context.read<InterviewProvider>().resumeTimer();
                              }
                            },
                            icon: const Icon(Icons.stop_circle_outlined, size: 20),
                            label: Text(
                              settings.t('end'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.redAccent.withOpacity(0.15) : Colors.red.shade50,
                              foregroundColor: isDark ? Colors.redAccent.shade100 : Colors.red.shade700,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: isDark ? Colors.redAccent.withOpacity(0.3) : Colors.red.shade200),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                                Navigator.pushReplacement(
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
                        : IntrinsicHeight( // 👈 Это магический виджет для выравнивания микрофона
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0), // Тонкая подгонка под поле
                                  child: AudioRecorderBtn(
                                    textController: _controller,
                                    isDisabled: isLoading,
                                  ),
                                ),
                                const Gap(8), 
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
                                            textInputAction: TextInputAction.send,
                                            onSubmitted: (_) {
                                              if (!isLoading) _sendMessage();
                                            },
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
                                          padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
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