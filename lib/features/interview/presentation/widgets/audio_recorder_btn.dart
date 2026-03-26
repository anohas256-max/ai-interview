import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderBtn extends StatefulWidget {
  final TextEditingController textController;
  final bool isDisabled;

  const AudioRecorderBtn({
    super.key,
    required this.textController,
    this.isDisabled = false,
  });

  @override
  State<AudioRecorderBtn> createState() => _AudioRecorderBtnState();
}

class _AudioRecorderBtnState extends State<AudioRecorderBtn> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _toggleRecording() async {
    if (widget.isDisabled) return;

    // Для веба бразуер сам спросит разрешение, а для телефона нужно дернуть permission_handler
    try {
      await Permission.microphone.request();
    } catch (e) {
      debugPrint("Ошибка запроса прав (игнорируем для Web): $e");
    }

    if (!_isListening) {
      if (!_isInitialized) {
        _isInitialized = await _speech.initialize(
          onStatus: (val) {
            if (val == 'done' || val == 'notListening') {
              setState(() => _isListening = false);
            }
          },
          onError: (val) => setState(() => _isListening = false),
        );
      }

      if (_isInitialized) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              // Вставляем распознанный текст прямо в поле ввода чата
              widget.textController.text = val.recognizedWords;
            });
          },
          // localeId: 'ru_RU', // Можно раскомментировать, если хочешь жестко привязать к русскому языку
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isDisabled
              ? Colors.transparent
              : _isListening
                  ? Colors.redAccent.withOpacity(0.2)
                  : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: widget.isDisabled 
              ? Colors.grey[800] 
              : _isListening ? Colors.redAccent : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}