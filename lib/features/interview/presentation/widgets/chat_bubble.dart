import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interview_provider.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  // Простой парсер Markdown для жирного и курсива
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
    final provider = context.watch<InterviewProvider>();
    final isPlaying = provider.currentlyPlayingText == text;

    // 👇 УМНАЯ ШИРИНА ДЛЯ ВЕБА И МОБИЛОК 👇
    double screenWidth = MediaQuery.of(context).size.width;
    double maxBubbleWidth = screenWidth > 800 ? 800 * 0.8 : screenWidth * 0.85;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth), // 👈 ПРИМЕНЯЕМ ЗДЕСЬ
        decoration: BoxDecoration(
          color: isUser ? Colors.white : const Color(0xFF2A2A2C),
// ... (дальше твой код без изменений)
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, 
          children: [
            SelectableText.rich(
              TextSpan(children: _parseMarkdown(text, TextStyle(
                color: isUser ? Colors.black : Colors.white, 
                fontSize: 15,
                height: 1.4,
              ))),
              style: const TextStyle(fontSize: 15), 
            ),
            
            // 👇 АНИМИРОВАННАЯ КНОПКА ОЗВУЧКИ 👇
            if (!isUser) ...[
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    provider.speak(text); // Работает и как Play, и как Stop
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPlaying ? Colors.redAccent.withOpacity(0.15) : Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPlaying ? Colors.redAccent.withOpacity(0.5) : Colors.transparent,
                      )
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_fill,
                            key: ValueKey(isPlaying), // Нужно для анимации смены иконки
                            color: isPlaying ? Colors.redAccent : Colors.blueAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPlaying ? "Остановить" : "Озвучить",
                          style: TextStyle(
                            color: isPlaying ? Colors.redAccent : Colors.blueAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]
            // 👆 КОНЕЦ ВСТАВКИ 👆
          ],
        ),
      ),
    );
  }
}