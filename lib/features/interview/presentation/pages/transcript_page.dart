import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';
import 'package:sobes/features/interview/domain/entities/message_entity.dart';
import 'package:sobes/core/providers/settings_provider.dart'; // 👈 Добавили настройки

class TranscriptPage extends StatelessWidget {
  const TranscriptPage({super.key});

  String _calculateTimeTaken(List<MessageEntity> messages, int currentIndex) {
    if (currentIndex == 0) return "0s";
    
    final currentMsg = messages[currentIndex];
    final prevMsg = messages[currentIndex - 1];
    
    final diff = currentMsg.timestamp.difference(prevMsg.timestamp).inSeconds;
    return "${diff}s";
  }

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
    final settings = context.watch<SettingsProvider>(); // 👈 Настройки
    final textColor = Theme.of(context).textTheme.bodyLarge?.color; // 👈 Цвет текста

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 👈 Адаптивный фон
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor), // 👈 Адаптивная иконка
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(settings.t('transcript_title'), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
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
              final feedback = msg.feedback ?? settings.t('no_rating'); // 👈 Перевод

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
    double screenWidth = MediaQuery.of(context).size.width;
    double maxBubbleWidth = screenWidth > 800 ? 800 * 0.85 : screenWidth * 0.85;

    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    if (!isUser) {
      return Align(
        alignment: Alignment.centerLeft, 
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxWidth: maxBubbleWidth), 
          decoration: BoxDecoration(
            color: cardColor, // 👈 Адаптивный фон
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16), 
              topRight: Radius.circular(16), 
              bottomRight: Radius.circular(16)
            ),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: SelectableText.rich(
            TextSpan(children: _parseMarkdown(text, TextStyle(color: textColor, fontSize: 15, height: 1.4))),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight, 
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth), 
        decoration: BoxDecoration(
          color: isWater ? Colors.red.withOpacity(0.05) : cardColor, // 👈 Адаптивный фон
          border: isWater ? Border.all(color: Colors.red.withOpacity(0.5)) : Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), 
            topRight: Radius.circular(16), 
            bottomLeft: Radius.circular(16)
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, 
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
              child: SelectableText(text, style: TextStyle(color: textColor, fontSize: 15, height: 1.4)), // 👈 Адаптивный текст
            ),
            
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