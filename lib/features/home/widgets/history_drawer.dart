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

  void _showSortFilterSheet(BuildContext context, HistoryProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Сортировка", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Gap(10),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text("Недавние"), selected: provider.currentSort == HistorySortType.dateDesc, onSelected: (_) => provider.setSort(HistorySortType.dateDesc)),
            ChoiceChip(label: const Text("Старые"), selected: provider.currentSort == HistorySortType.dateAsc, onSelected: (_) => provider.setSort(HistorySortType.dateAsc)),
            ChoiceChip(label: const Text("Лучшие оценки"), selected: provider.currentSort == HistorySortType.scoreDesc, onSelected: (_) => provider.setSort(HistorySortType.scoreDesc)),
          ]),
          const Gap(20),
          const Text("Фильтр", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Gap(10),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text("Все"), selected: provider.currentFilter == HistoryFilterType.all, onSelected: (_) => provider.setFilter(HistoryFilterType.all)),
            ChoiceChip(label: const Text("Завершенные"), selected: provider.currentFilter == HistoryFilterType.finished, onSelected: (_) => provider.setFilter(HistoryFilterType.finished)),
            ChoiceChip(label: const Text("В процессе"), selected: provider.currentFilter == HistoryFilterType.unfinished, onSelected: (_) => provider.setFilter(HistoryFilterType.unfinished)),
          ]),
          const Gap(20),
        ]),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text("Очистить историю?"),
        content: const Text("Вы уверены, что хотите удалить все сессии? Это действие необратимо.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () { provider.clearAllHistoryFromDB(); Navigator.pop(ctx); }, child: const Text("Удалить всё", style: TextStyle(color: Colors.red))),
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
                  IconButton(icon: const Icon(Icons.tune), onPressed: () => _showSortFilterSheet(context, historyProvider)),
                  if (sessions.isNotEmpty)
                    IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: () => _confirmClearHistory(context, historyProvider)),
                ],
              ),
            ]),
          ),
          const Divider(height: 1),
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
    final ctrl = TextEditingController(text: session.title);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: const Text("Переименовать"),
      content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: "Новое название")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена", style: TextStyle(color: Colors.grey))),
        TextButton(onPressed: () { provider.renameSession(session, ctrl.text); Navigator.pop(ctx); }, child: const Text("Сохранить", style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
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
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.withOpacity(0.2))),
                  child: Text(_formatDate(session.date, settings), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                // 👇 КОМПАКТНОЕ POPUP МЕНЮ (КАК НА СКРИНШОТЕ) 👇
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'rename') _showRenameDialog(context);
                    if (value == 'delete') provider.deleteSession(session.id);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'rename',
                      child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blueAccent), Gap(10), Text('Переименовать')]),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.redAccent), Gap(10), Text('Удалить', style: TextStyle(color: Colors.redAccent))]),
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