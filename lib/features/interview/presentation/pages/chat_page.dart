import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:sobes/features/interview/presentation/pages/analysis_page.dart';
import 'package:sobes/features/interview/presentation/widgets/chat_bubble.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';

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
      provider.clearChat();
      // Заставляем ИИ начать диалог первым!
      provider.startInterview(); 
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
    final messages = provider.messages;
    final isLoading = provider.isLoading;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // --- ШАПКА ЧАТА ---
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          context.read<InterviewProvider>().clearChat();
                          Navigator.pop(context);
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1010),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.circle, size: 8, color: Colors.red),
                            Gap(8),
                            Text("Live", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context, 
                            MaterialPageRoute(builder: (_) => const AnalysisPage())
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF2B1515),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("END", style: TextStyle(color: Color(0xFFFF453A), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),

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
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 2),
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

              // 👇 НОВАЯ КНОПКА ПОВТОРА ПРИ ОШИБКЕ 👇
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
                      label: const Text("Повторить отправку", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ),
              // 👆 КОНЕЦ КНОПКИ ПОВТОРА 👆

              // --- ПАНЕЛЬ ВВОДА ИЛИ КНОПКА ЗАВЕРШЕНИЯ ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
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
                            backgroundColor: provider.isFailed ? Colors.red[800] : Colors.green[700],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            provider.isFailed ? "Интервью прервано. Смотреть итоги" : "Собеседование завершено! Смотреть итоги", 
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      minLines: 1,
                                      maxLines: 4,
                                      // ДИНАМИЧЕСКИЙ ЛИМИТ: 1000 для легенды, 5000 для техники
                                      maxLength: provider.isLegendPhase ? 1000 : 5000, 
                                      style: const TextStyle(color: Colors.white),
                                      enabled: !isLoading, 
                                      decoration: InputDecoration(
                                        hintText: provider.isLegendPhase ? "Кратко расскажите о себе..." : (isLoading ? "AI печатает..." : "Ваш ответ..."),
                                        hintStyle: const TextStyle(color: Colors.grey),
                                        border: InputBorder.none,
                                        counterText: "", // Скрываем счетчик
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: IconButton(
                                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                                      style: IconButton.styleFrom(
                                        backgroundColor: isLoading ? Colors.transparent : const Color(0xFF3A3A3C),
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
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48), Gap(8),
                        Text("Too much fluff. Be specific.", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}