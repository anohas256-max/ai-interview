import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:sobes/features/history/presentation/providers/history_provider.dart';
import 'package:sobes/features/history/domain/entities/session_history.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';
import 'package:sobes/features/interview/presentation/pages/chat_page.dart';
import 'package:sobes/features/interview/presentation/pages/analysis_page.dart';
import 'package:sobes/core/providers/settings_provider.dart'; // 👈 Добавили провайдер

class HistoryDrawer extends StatelessWidget {
  const HistoryDrawer({super.key});

  String _formatDate(DateTime date, SettingsProvider settings) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0 && now.day == date.day) {
      if (diff.inHours > 0) return "${diff.inHours} ${settings.t('h_ago')}";
      if (diff.inMinutes > 0) return "${diff.inMinutes} ${settings.t('m_ago')}";
      return settings.t('just_now');
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) {
      return settings.t('yesterday');
    } else {
      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return "${months[date.month - 1]} ${date.day}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final sessions = historyProvider.sessions;
    
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Drawer(
      backgroundColor: bgColor, 
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    settings.t('drawer_archive'), 
                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context), 
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.withOpacity(0.2), height: 1),
            
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Text(settings.t('drawer_empty'), style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _HistoryItem(
                          session: session,
                          timeBadge: _formatDate(session.date, settings),
                          textColor: textColor,
                          settings: settings,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final SessionHistory session;
  final String timeBadge;
  final Color? textColor;
  final SettingsProvider settings;

  const _HistoryItem({required this.session, required this.timeBadge, this.textColor, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final provider = context.read<InterviewProvider>();
          provider.loadSessionFromHistory(session);
          Navigator.pop(context); // Закрываем Drawer

          if (session.isFinished) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalysisPage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatPage(role: session.config.role)),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title, 
                      style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const Gap(4),
                    Text(
                      "${session.subtitle} • ${settings.t('drawer_score')}: ${session.score > 0 ? session.score.toString() : '—'}", 
                      style: const TextStyle(color: Colors.grey, fontSize: 13), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                  ],
                ),
              ),
              const Gap(12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor, 
                  borderRadius: BorderRadius.circular(6), 
                  border: Border.all(color: Colors.grey.withOpacity(0.2))
                ),
                child: Text(
                  timeBadge, 
                  style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}