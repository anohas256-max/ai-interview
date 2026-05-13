import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interview_provider.dart';
import 'package:sobes/core/providers/settings_provider.dart'; // 👈 Подтянули настройки для перевода

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
    final settings = context.watch<SettingsProvider>();
    final isPlaying = provider.currentlyPlayingText == text;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Умная ширина для веба и мобилок
    double screenWidth = MediaQuery.of(context).size.width;
    double maxBubbleWidth = screenWidth > 800 ? 800 * 0.8 : screenWidth * 0.85;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: BoxDecoration(
          color: isUser ? (isDark ? Colors.blueAccent.withOpacity(0.8) : Colors.blue.shade50) : (isDark ? const Color(0xFF2A2A2C) : Colors.white),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
          border: isDark ? null : Border.all(color: Colors.grey.withOpacity(0.1)),
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
                color: isUser ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white : Colors.black87), 
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
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    provider.speak(text); 
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isPlaying ? Colors.redAccent.withOpacity(0.15) : Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isPlaying ? Colors.redAccent.withOpacity(0.4) : Colors.blueAccent.withOpacity(0.2),
                      )
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isPlaying ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                            key: ValueKey(isPlaying),
                            color: isPlaying ? Colors.redAccent : Colors.blueAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPlaying 
                            ? (settings.t('stop_voice') != 'stop_voice' ? settings.t('stop_voice') : 'Остановить') 
                            : (settings.t('play_voice') != 'play_voice' ? settings.t('play_voice') : 'Озвучить'),
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
          ],
        ),
      ),
    );
  }
}