import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';
import 'package:sobes/features/interview/domain/entities/message_entity.dart';

class TranscriptPage extends StatelessWidget {
  const TranscriptPage({super.key});

  // Высчитываем, сколько секунд юзер думал над ответом
  String _calculateTimeTaken(List<MessageEntity> messages, int currentIndex) {
    if (currentIndex == 0) return "0s";
    
    final currentMsg = messages[currentIndex];
    final prevMsg = messages[currentIndex - 1];
    
    // Считаем разницу во времени между вопросом HR и твоим ответом
    final diff = currentMsg.timestamp.difference(prevMsg.timestamp).inSeconds;
    return "${diff}s";
  }

  // 👇 НАШ ПАРСЕР МАРКДАУНА ДЛЯ КРАСИВОГО ТЕКСТА 👇
  List<TextSpan> _parseMarkdown(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'(\*\*.*?\*\*|\*.*?\*)');
    int lastMatchEnd = 0;

    for (final Match m in exp.allMatches(text)) {
      if (m.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, m.start), style: baseStyle));
      }
      String matchText = m.group(0)!;
      if (matchText.startsWith('**') && matchText.endsWith('**')) {
        spans.add(TextSpan(
            text: matchText.substring(2, matchText.length - 2),
            style: baseStyle.copyWith(fontWeight: FontWeight.bold)));
      } else if (matchText.startsWith('*') && matchText.endsWith('*')) {
        spans.add(TextSpan(
            text: matchText.substring(1, matchText.length - 1),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic)));
      }
      lastMatchEnd = m.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<InterviewProvider>().messages;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Разбор диалога", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      // 👇 ЦЕНТРИРУЕМ ДЛЯ WEB 👇
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              
              if (!msg.isUser) {
                return _buildTranscriptBubble(
                  context: context,
                  text: msg.text, 
                  isUser: false, 
                  timeTaken: "", 
                  inputType: "", 
                  isWater: false, 
                  feedback: ""
                );
              }

              final timeTaken = _calculateTimeTaken(messages, index);
              final isWater = msg.isWater; 
              final feedback = msg.feedback ?? "Оценка не получена";

              return _buildTranscriptBubble(
                context: context,
                text: msg.text, 
                isUser: true, 
                timeTaken: timeTaken, 
                inputType: "Text", 
                isWater: isWater, 
                feedback: feedback
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptBubble({
    required BuildContext context,
    required String text, 
    required bool isUser, 
    required String timeTaken, 
    required String inputType, 
    required bool isWater, 
    required String feedback
  }) {
    // 👇 Умная ширина: 85% экрана, но не больше 800px 👇
    double screenWidth = MediaQuery.of(context).size.width;
    double maxBubbleWidth = screenWidth > 800 ? 800 * 0.85 : screenWidth * 0.85;

    if (!isUser) {
      return Align(
        alignment: Alignment.centerLeft, // Прижимаем ИИ влево
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxWidth: maxBubbleWidth), // Ограничиваем ширину
          decoration: const BoxDecoration(
            color: Color(0xFF151515),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), 
              topRight: Radius.circular(16), 
              bottomRight: Radius.circular(16)
            ),
          ),
          // 👇 Теперь ИИ использует Markdown 👇
          child: SelectableText.rich(
            TextSpan(children: _parseMarkdown(text, const TextStyle(color: Colors.white, fontSize: 15, height: 1.4))),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight, // Прижимаем юзера вправо
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth), // Ограничиваем ширину
        decoration: BoxDecoration(
          color: isWater ? const Color(0xFF2B1515) : const Color(0xFF1C1C1E),
          border: isWater ? Border.all(color: Colors.red.withOpacity(0.5)) : Border.all(color: Colors.white.withOpacity(0.05)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), 
            topRight: Radius.circular(16), 
            bottomLeft: Radius.circular(16)
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Важно! Пузырь облегает контент
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.keyboard, color: Colors.grey[500], size: 14), 
                    const Gap(6), 
                    Text(inputType, style: TextStyle(color: Colors.grey[500], fontSize: 12))
                  ]),
                  Row(children: [
                    Icon(Icons.timer_outlined, color: Colors.grey[500], size: 14), 
                    const Gap(4), 
                    Text(timeTaken, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold))
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              // Юзер тоже может копировать свой текст
              child: SelectableText(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
            ),
            
            // 👇 МЫ УБРАЛИ width: double.infinity отсюда 👇
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isWater ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), 
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16))
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isWater ? Icons.warning_amber_rounded : Icons.check_circle_outline, 
                    color: isWater ? Colors.redAccent : Colors.green, 
                    size: 18
                  ),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      feedback, 
                      style: TextStyle(
                        color: isWater ? Colors.redAccent : Colors.green, 
                        fontSize: 13, 
                        fontWeight: FontWeight.w500, 
                        height: 1.4
                      )
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}