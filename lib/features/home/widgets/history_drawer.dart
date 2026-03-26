import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:sobes/features/history/presentation/providers/history_provider.dart';
import 'package:sobes/features/history/domain/entities/session_history.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';
import 'package:sobes/features/interview/presentation/pages/chat_page.dart';
import 'package:sobes/features/interview/presentation/pages/analysis_page.dart';

class HistoryDrawer extends StatelessWidget {
  const HistoryDrawer({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0 && now.day == date.day) {
      if (diff.inHours > 0) return "${diff.inHours}H AGO";
      if (diff.inMinutes > 0) return "${diff.inMinutes}M AGO";
      return "JUST NOW";
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) {
      return "YESTERDAY";
    } else {
      const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return "${months[date.month - 1]} ${date.day}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final sessions = historyProvider.sessions;

    return Drawer(
      backgroundColor: Colors.black, 
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Архив сессий", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context), 
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.05), height: 1),
            
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Text("Пока нет сохраненных сессий.", style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _HistoryItem(
                          session: session,
                          timeBadge: _formatDate(session.date),
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

  const _HistoryItem({required this.session, required this.timeBadge});

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
    // Если интервью закончено, сразу в аналитику
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalysisPage()),
    );
  } else {
    // Если не закончено — в чат доигрывать
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(role: session.config.role)),
    );
  }
},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Gap(4),
                    Text(
                      "${session.subtitle} • Оценка: ${session.score > 0 ? session.score.toString() : '—'}", 
                      style: TextStyle(color: Colors.grey[500], fontSize: 13), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                  ],
                ),
              ),
              const Gap(12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white.withOpacity(0.1))),
                child: Text(timeBadge, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}