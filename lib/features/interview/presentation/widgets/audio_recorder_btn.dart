import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  late final stt.SpeechToText _speech;

  bool _isListening = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _toggleRecording() async {
    if (widget.isDisabled) return;

    try {
      await Permission.microphone.request();
    } catch (e) {
      debugPrint("Ошибка запроса прав микрофона: $e");
    }

    if (!_isListening) {
      if (!_isInitialized) {
        _isInitialized = await _speech.initialize(
          onStatus: (val) {
            if (val == 'done' || val == 'notListening') {
              if (mounted) {
                setState(() => _isListening = false);
              }
            }
          },
          onError: (val) {
            if (mounted) {
              setState(() => _isListening = false);
            }
          },
        );
      }

      if (_isInitialized) {
        setState(() => _isListening = true);

        _speech.listen(
          onResult: (val) {
            if (!mounted) return;

            setState(() {
              widget.textController.text = val.recognizedWords;
              widget.textController.selection = TextSelection.fromPosition(
                TextPosition(offset: widget.textController.text.length),
              );
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

@override
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final Color bgColor;
  final Color iconColor;
  final Color borderColor;

  if (widget.isDisabled) {
    bgColor = Colors.transparent;
    iconColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
  } else if (_isListening) {
    bgColor = Colors.redAccent.withOpacity(0.12);
    iconColor = Colors.redAccent;
    borderColor = Colors.redAccent.withOpacity(0.55);
  } else {
    bgColor = Colors.transparent;
    iconColor = isDark ? Colors.white70 : Colors.grey.shade500;
    borderColor = isDark
        ? Colors.white.withOpacity(0.18)
 : Colors.grey.shade300;
  }

  return InkWell(
    onTap: _toggleRecording,
    borderRadius: BorderRadius.circular(22),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.4,
        ),
      ),
      child: Icon(
        _isListening ? Icons.mic : Icons.keyboard_voice_outlined,
        color: iconColor,
        size: 22,
      ),
    ),
  );
}
}