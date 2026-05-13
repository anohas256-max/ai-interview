import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sobes/features/history/presentation/providers/history_provider.dart';
import 'package:sobes/features/history/domain/entities/session_history.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';
import 'package:sobes/features/interview/presentation/pages/chat_page.dart';
import 'package:sobes/core/providers/settings_provider.dart';

class HistoryDrawer extends StatefulWidget {
  const HistoryDrawer({super.key});
  @override
  State<HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<HistoryDrawer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<HistoryProvider>().loadHistory());
  }

  // 👇 ТЕПЕРЬ ТУТ ТОЛЬКО СОРТИРОВКА 👇
  void _showSortSheet(BuildContext context, HistoryProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Сортировка", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Gap(16),
              Wrap(
                spacing: 8, 
                runSpacing: 8, 
                children: [
                  ChoiceChip(
                    label: const Text("Недавние"), 
                    selected: provider.currentSort == HistorySortType.dateDesc, 
                    side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                    onSelected: (_) {
                      provider.setSort(HistorySortType.dateDesc);
                      Navigator.pop(ctx);
                    }
                  ),
                  ChoiceChip(
                    label: const Text("Старые"), 
                    selected: provider.currentSort == HistorySortType.dateAsc, 
                    side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                    onSelected: (_) {
                      provider.setSort(HistorySortType.dateAsc);
                      Navigator.pop(ctx);
                    }
                  ),
                  ChoiceChip(
                    label: const Text("Лучшие оценки"), 
                    selected: provider.currentSort == HistorySortType.scoreDesc, 
                    side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                    onSelected: (_) {
                      provider.setSort(HistorySortType.scoreDesc);
                      Navigator.pop(ctx);
                    }
                  ),
                ]
              ),
              const Gap(8),
            ]
          ),
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            Gap(8),
            Text("Очистить историю?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text("Вы уверены, что хотите удалить все сессии? Это действие необратимо.", style: TextStyle(color: Colors.grey, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () { provider.clearAllHistoryFromDB(); Navigator.pop(ctx); }, 
            child: const Text("Удалить всё", style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final sessions = historyProvider.sessions;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(settings.t('drawer_archive'), style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.sort), onPressed: () => _showSortSheet(context, historyProvider)),
                  if (sessions.isNotEmpty)
                    IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () => _confirmClearHistory(context, historyProvider)),
                ],
              ),
            ]),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          Expanded(
            child: sessions.isEmpty 
              ? Center(child: Text(settings.t('drawer_empty'), style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (ctx, i) => _HistoryItem(session: sessions[i], settings: settings, provider: historyProvider, textColor: textColor),
                ),
          ),
        ]),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final SessionHistory session;
  final SettingsProvider settings;
  final HistoryProvider provider;
  final Color? textColor;

  const _HistoryItem({required this.session, required this.settings, required this.provider, this.textColor});

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

  void _showRenameDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(text: session.title);
    
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Переименовать", style: TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(
        controller: ctrl, 
        autofocus: true, 
        decoration: InputDecoration(
          hintText: "Новое название",
          filled: true,
          fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        )
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () { provider.renameSession(session, ctrl.text); Navigator.pop(ctx); }, 
          child: const Text("Сохранить", style: TextStyle(fontWeight: FontWeight.bold))
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        context.read<InterviewProvider>().loadSessionFromHistory(session);
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(role: session.config.role)));
      },
      child: Container(
        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Gap(4),
                  Text("${settings.t('drawer_score')}: ${session.hasAnalysis ? session.score.toStringAsFixed(1) : '—'}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, 
                    borderRadius: BorderRadius.circular(6), 
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08))
                  ),
                  child: Text(_formatDate(session.date, settings), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'rename') _showRenameDialog(context);
                    if (value == 'delete') provider.deleteSession(session.id);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'rename',
                      child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blueAccent), Gap(10), Text('Переименовать', style: TextStyle(fontWeight: FontWeight.w500))]),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.redAccent), Gap(10), Text('Удалить', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500))]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}