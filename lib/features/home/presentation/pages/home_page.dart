import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sobes/features/home/widgets/history_drawer.dart';
import 'package:sobes/features/profile/presentation/pages/profile_page.dart';
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';
import 'package:sobes/features/interview/presentation/pages/chat_page.dart';
import 'package:sobes/features/interview/presentation/pages/mode_selection_page.dart';
import 'package:sobes/core/providers/settings_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authData = context.watch<AuthProvider>();
    final interviewProvider = context.watch<InterviewProvider>();
    final settings = context.watch<SettingsProvider>();
    
    // 👇 Мы убрали отсюда CatalogProvider.updateLanguage, теперь экран чистый!
    
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    
    final String currentName = authData.currentUsername ?? "?";
    final String initials = currentName.trim().isNotEmpty && currentName != "?"
        ? currentName.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join() : "?";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      drawer: const HistoryDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: Builder(builder: (context) {
          return IconButton(icon: Icon(Icons.menu, color: textColor), onPressed: () => Scaffold.of(context).openDrawer());
        }),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24), 
            child: GestureDetector( 
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.2))),
                child: Center(child: Text(initials, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14))),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
              const Spacer(flex: 2), 
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.2))),
                child: Icon(Icons.auto_awesome, color: textColor, size: 40),
              ),
              const Gap(32),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontFamily: 'Inter', height: 1.1),
                  children: [
                    TextSpan(text: settings.t('home_master'), style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: textColor)),
                    TextSpan(text: settings.t('home_interview'), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
              const Gap(16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0), 
                child: Text(settings.t('home_sub'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16, height: 1.5)),
              ),
              const Gap(48),

              if (interviewProvider.hasDraft) ...[
                SizedBox(
                  width: 220, height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      await interviewProvider.loadDraft();
                      if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(role: interviewProvider.config?.role ?? "")));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor, foregroundColor: textColor,
                      shape: const StadiumBorder(), elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restore, size: 20), const Gap(8),
                        Text(settings.t('continue_chat'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const Gap(16),
              ],

              SizedBox(
                width: 220, height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModeSelectionPage())),
                  style: ElevatedButton.styleFrom(shape: const StadiumBorder(), elevation: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(settings.t('start_interview'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Gap(8), const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3), 

              Container(
                margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
                    const Gap(10),
                    Text(settings.t('free_sessions'), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}