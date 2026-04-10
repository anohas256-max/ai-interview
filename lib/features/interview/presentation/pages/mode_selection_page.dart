import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sobes/core/providers/settings_provider.dart';
import 'package:sobes/core/widgets/balance_badge.dart'; // 👈 Добавили плашку монет
import 'setup_page.dart'; 
import 'setup_quiz_page.dart'; 

class ModeSelectionPage extends StatelessWidget {
  const ModeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(settings.t('mode_title'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true, 
        actions: const [BalanceBadge()], // 👈 Теперь монеты видно и здесь!
      ),
      body: Center( 
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), 
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
                _AnimatedModeCard(
                  title: settings.t('mode_roleplay'), 
                  description: settings.t('mode_roleplay_desc'),
                  icon: Icons.cases_rounded, 
                  color: Colors.blueAccent, 
                  cardColor: cardColor, 
                  textColor: textColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupPage())),
                ),
                const Gap(24),
                _AnimatedModeCard(
                  title: settings.t('mode_quiz'), 
                  description: settings.t('mode_quiz_desc'),
                  icon: Icons.psychology_rounded, 
                  color: Colors.greenAccent, 
                  cardColor: cardColor, 
                  textColor: textColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupQuizPage())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 👇 НОВЫЙ УМНЫЙ ВИДЖЕТ С АНИМАЦИЯМИ 👇
class _AnimatedModeCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final Color? textColor;
  final VoidCallback onTap;

  const _AnimatedModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_AnimatedModeCard> createState() => _AnimatedModeCardState();
}

class _AnimatedModeCardState extends State<_AnimatedModeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // AnimatedScale отвечает за эффект "вдавливания"
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.cardColor, 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(
            color: _isPressed ? widget.color : widget.color.withOpacity(0.3), 
            width: _isPressed ? 3 : 2, // Рамка становится толще при нажатии
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_isPressed ? 0.3 : 0.05),
              blurRadius: _isPressed ? 20 : 10,
              offset: const Offset(0, 8),
            )
          ]
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            highlightColor: widget.color.withOpacity(0.05),
            splashColor: widget.color.withOpacity(0.1), // Цвет волны
            // Ловим события нажатия для запуска анимации
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(_isPressed ? 0.2 : 0.1), 
                      shape: BoxShape.circle
                    ), 
                    child: Icon(widget.icon, color: widget.color, size: 32)
                  ),
                  const Gap(16),
                  Text(widget.title, style: TextStyle(color: widget.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Gap(8),
                  Text(widget.description, style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}