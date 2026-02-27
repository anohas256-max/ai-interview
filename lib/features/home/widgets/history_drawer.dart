import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

// Подключаем наш пульт истории
import 'package:sobes/features/history/presentation/providers/history_provider.dart';

class HistoryDrawer extends StatelessWidget {
  const HistoryDrawer({super.key});

  // Умный форматтер даты
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
    // 👇 Подключаемся к базе данных истории 👇
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
                  const Text("History", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context), 
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.05), height: 1),
            
            // --- СПИСОК ПРОШЛЫХ СОБЕСЕДОВАНИЙ ---
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Text(
                        "No completed sessions yet.",
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _HistoryItem(
                          role: session.role,
                          subtitle: "${session.persona} • Оценка: ${session.score}",
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
  final String role;
  final String subtitle;
  final String timeBadge;

  const _HistoryItem({required this.role, required this.subtitle, required this.timeBadge});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // TODO: Открыть детальную статистику (Позже сделаем)
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Gap(4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(timeBadge, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}