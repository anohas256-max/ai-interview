import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class TranscriptPage extends StatelessWidget {
  const TranscriptPage({super.key});

  // Фейковые данные (потом это будет приходить от ИИ после анализа)
  final List<Map<String, dynamic>> _mockTranscript = const [
    {
      "isUser": false,
      "text": "Explain the difference between checked and unchecked exceptions in Java. Can you provide a real-world scenario?",
    },
    {
      "isUser": true,
      "text": "Well, you see, it really depends on the situation. Sometimes you write code and errors happen, so you have to handle them depending on the project requirements...",
      "timeTaken": "45s",
      "inputType": "Voice",
      "isWater": true, // ДЕТЕКТОР ВОДЫ СРАБОТАЛ
      "feedback": "Too much fluff. You spoke for 45 seconds without naming specific classes (Exception vs RuntimeException).",
    },
    {
      "isUser": false,
      "text": "Let's try again. Please give a specific technical definition and a brief example.",
    },
    {
      "isUser": true,
      "text": "Checked exceptions are verified at compile time (like IOException). Unchecked exceptions occur at runtime (like NullPointerException).",
      "timeTaken": "12s",
      "inputType": "Text",
      "isWater": false, // ХОРОШИЙ ОТВЕТ
      "feedback": "Clear, concise, and technically accurate.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      // --- ВЕРХНЯЯ ПАНЕЛЬ ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Full Transcript", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),

      // --- ТЕЛО ЭКРАНА (Список сообщений) ---
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _mockTranscript.length,
        itemBuilder: (context, index) {
          final msg = _mockTranscript[index];
          return _buildTranscriptBubble(msg);
        },
      ),
    );
  }

  // --- ЛОГИКА ОТРИСОВКИ ПУЗЫРЕЙ ---
  Widget _buildTranscriptBubble(Map<String, dynamic> msg) {
    final bool isUser = msg['isUser'];
    final String text = msg['text'];

    // Если это сообщение от ИИ (HR-бота)
    if (!isUser) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24, right: 40),
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF151515), // Темно-серый
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
        ),
      );
    }

    // --- ЕСЛИ ЭТО СООБЩЕНИЕ ПОЛЬЗОВАТЕЛЯ ---
    final bool isWater = msg['isWater'] ?? false;
    final String timeTaken = msg['timeTaken'] ?? "";
    final String inputType = msg['inputType'] ?? "";
    final String feedback = msg['feedback'] ?? "";

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 20),
        decoration: BoxDecoration(
          // Если "вода" - делаем красноватый фон и красную рамку, иначе обычный стиль
          color: isWater ? const Color(0xFF2B1515) : const Color(0xFF1C1C1E),
          border: isWater ? Border.all(color: Colors.red.withOpacity(0.5)) : Border.all(color: Colors.white.withOpacity(0.05)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // 1. Плашка со статистикой (Время и Тип ввода)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        inputType == "Voice" ? Icons.mic : Icons.keyboard, 
                        color: Colors.grey[500], size: 14
                      ),
                      const Gap(6),
                      Text(inputType, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.grey[500], size: 14),
                      const Gap(4),
                      Text(timeTaken, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Сам текст ответа
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
            ),

            // 3. Комментарий от ИИ (Разбор полетов)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isWater ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isWater ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: isWater ? Colors.redAccent : Colors.green,
                    size: 18,
                  ),
                  const Gap(10),
                  Expanded(
                    child: Text(
                      feedback,
                      style: TextStyle(
                        color: isWater ? Colors.redAccent : Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
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