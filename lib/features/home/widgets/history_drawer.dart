import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:sobes/core/providers/settings_provider.dart';
import 'package:sobes/features/history/domain/entities/session_history.dart';
import 'package:sobes/features/history/presentation/providers/history_provider.dart';
import 'package:sobes/features/interview/presentation/pages/chat_page.dart';
import 'package:sobes/features/interview/presentation/providers/interview_provider.dart';

class HistoryDrawer extends StatefulWidget {
  const HistoryDrawer({super.key});

  @override
  State<HistoryDrawer> createState() => _HistoryDrawerState();
}

class _HistoryDrawerState extends State<HistoryDrawer> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HistoryProvider>().loadHistory();
      }
    });
  }

  void _confirmClearHistory(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            ),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              Gap(8),
              Expanded(
                child: Text(
                  'Очистить историю?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Вы уверены, что хотите удалить все сессии? Это действие необратимо.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Отмена',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                provider.clearAllHistoryFromDB();
                Navigator.pop(ctx);
              },
              child: const Text(
                'Удалить всё',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final settings = context.watch<SettingsProvider>();
    final sessions = historyProvider.sessions;

    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = math.min(screenWidth * 0.88, 390.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;
    final borderColor =
        isDark ? Colors.white10 : Colors.black.withOpacity(0.08);

    return Drawer(
      width: drawerWidth,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Закрыть',
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: textColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Gap(2),
                  Expanded(
                    child: Text(
                      settings.t('drawer_archive'),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (sessions.isNotEmpty)
                    IconButton(
                      tooltip: 'Очистить историю',
                      icon: const Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        _confirmClearHistory(context, historyProvider);
                      },
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _HistorySortBar(
                currentSort: historyProvider.currentSort,
                cardColor: cardColor,
                borderColor: borderColor,
                isDark: isDark,
                onChanged: historyProvider.setSort,
              ),
            ),

            Divider(
              height: 1,
              color: Colors.grey.withOpacity(0.18),
            ),

            Expanded(
              child: historyProvider.isLoading && sessions.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : sessions.isEmpty
                      ? Center(
                          child: Text(
                            settings.t('drawer_empty'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: sessions.length,
                          itemBuilder: (ctx, i) {
                            return _HistoryItem(
                              session: sessions[i],
                              settings: settings,
                              provider: historyProvider,
                              textColor: textColor,
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

class _HistorySortBar extends StatelessWidget {
  final HistorySortType currentSort;
  final Color cardColor;
  final Color borderColor;
  final bool isDark;
  final ValueChanged<HistorySortType> onChanged;

  const _HistorySortBar({
    required this.currentSort,
    required this.cardColor,
    required this.borderColor,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SortButton(
              label: 'Недавние',
              shortLabel: 'Нед.',
              icon: Icons.schedule_rounded,
              selected: currentSort == HistorySortType.dateDesc,
              isDark: isDark,
              onTap: () => onChanged(HistorySortType.dateDesc),
            ),
          ),
          const Gap(5),
          Expanded(
            child: _SortButton(
              label: 'Старые',
              shortLabel: 'Стар.',
              icon: Icons.history_rounded,
              selected: currentSort == HistorySortType.dateAsc,
              isDark: isDark,
              onTap: () => onChanged(HistorySortType.dateAsc),
            ),
          ),
          const Gap(5),
          Expanded(
            child: _SortButton(
              label: 'Оценка',
              shortLabel: 'Оц.',
              icon: Icons.star_rounded,
              selected: currentSort == HistorySortType.scoreDesc,
              isDark: isDark,
              onTap: () => onChanged(HistorySortType.scoreDesc),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final String shortLabel;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = Colors.blueAccent;
    final width = MediaQuery.of(context).size.width;
    final visibleLabel = width < 390 ? shortLabel : label;

    return Material(
      color: selected
          ? selectedColor.withOpacity(isDark ? 0.24 : 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? selectedColor
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
              ),
              const Gap(4),
              Flexible(
                child: Text(
                  visibleLabel,
                  style: TextStyle(
                    color: selected
                        ? selectedColor
                        : (isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final SessionHistory session;
  final SettingsProvider settings;
  final HistoryProvider provider;
  final Color? textColor;

  const _HistoryItem({
    required this.session,
    required this.settings,
    required this.provider,
    this.textColor,
  });

  String _formatDate(DateTime date, SettingsProvider settings) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0 && now.day == date.day) {
      if (diff.inHours > 0) return '${diff.inHours} ${settings.t('h_ago')}';
      if (diff.inMinutes > 0) return '${diff.inMinutes} ${settings.t('m_ago')}';
      return settings.t('just_now');
    }

    if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) {
      return settings.t('yesterday');
    }

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }

  void _showRenameDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(text: session.title);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            ),
          ),
          title: const Text(
            'Переименовать',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'Новое название',
              filled: true,
              fillColor: isDark ? Colors.black12 : Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Отмена',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                provider.renameSession(session, ctrl.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text(
                'Сохранить',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        context.read<InterviewProvider>().loadSessionFromHistory(session);
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(role: session.config.role),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.only(
          left: 16,
          top: 13,
          bottom: 13,
          right: 8,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.10),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Text(
                    '${settings.t('drawer_score')}: ${session.hasAnalysis ? session.score.toStringAsFixed(1) : '—'}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.08),
                    ),
                  ),
                  child: Text(
                    _formatDate(session.date, settings),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Colors.grey,
                    size: 20,
                  ),
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'rename') _showRenameDialog(context);
                    if (value == 'delete') provider.deleteSession(session.id);
                  },
                  itemBuilder: (BuildContext context) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.blueAccent,
                            ),
                            Gap(10),
                            Text(
                              'Переименовать',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            Gap(10),
                            Text(
                              'Удалить',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
