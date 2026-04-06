import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sobes/core/providers/settings_provider.dart';
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
      ),
      body: Center( 
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), 
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
                _buildModeCard(
                  context: context, title: settings.t('mode_roleplay'), description: settings.t('mode_roleplay_desc'),
                  icon: Icons.cases_rounded, color: Colors.blueAccent, cardColor: cardColor, textColor: textColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupPage())),
                ),
                const Gap(24),
                _buildModeCard(
                  context: context, title: settings.t('mode_quiz'), description: settings.t('mode_quiz_desc'),
                  icon: Icons.psychology_rounded, color: Colors.greenAccent, cardColor: cardColor, textColor: textColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupQuizPage())),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({required BuildContext context, required String title, required String description, required IconData icon, required Color color, required Color cardColor, required Color? textColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.3), width: 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 32)),
            const Gap(16),
            Text(title, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
            const Gap(8),
            Text(description, style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}