import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart';

class BalanceBadge extends StatefulWidget {
  const BalanceBadge({super.key});

  @override
  State<BalanceBadge> createState() => _BalanceBadgeState();
}

class _BalanceBadgeState extends State<BalanceBadge> {
  bool _isHovered = false;
  OverlayEntry? _overlayEntry;

  void _toggleEnergyMenu(BuildContext context) {
    if (_overlayEntry != null) {
      _closeEnergyMenu();
    } else {
      _showEnergyMenu(context);
    }
  }

  void _closeEnergyMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showEnergyMenu(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final overlay = Overlay.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? Theme.of(context).cardColor : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final badgeAccentColor =
        isDark ? Colors.amberAccent : Colors.amber.shade800;
    final borderColor = isDark ? Colors.amber : Colors.amber.shade600;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final menuWidth = screenWidth < 340 ? screenWidth - 24 : 300.0;

        return Stack(
          children: [
            GestureDetector(
              onTap: _closeEnergyMenu,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
            Positioned(
              top: 92,
              right: 12,
              child: Material(
                elevation: isDark ? 8 : 4,
                borderRadius: BorderRadius.circular(18),
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                shadowColor: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                child: Container(
                  width: menuWidth,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: borderColor.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: ListenableBuilder(
                    listenable: authProvider,
                    builder: (context, child) {
                      final descColor =
                          isDark ? Colors.grey : Colors.grey.shade600;

                      final canClaimReward = authProvider.dailyRewardAvailable;

                      final rewardBlockedByBalance =
                          authProvider.isDailyRewardBlockedByBalance;

                      final rewardOnCooldown =
                          authProvider.isDailyRewardOnCooldown;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: badgeAccentColor.withOpacity(
                                    isDark ? 0.15 : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: borderColor.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  '🎁',
                                  style: TextStyle(
                                    fontSize: 22,
                                    height: 1,
                                  ),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Text(
                                  'Ежедневный бонус',
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    fontSize: 16,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              const Gap(8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '+15 ⚡️',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: badgeAccentColor,
                                    fontSize: 18,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (canClaimReward) ...[
                            const Gap(16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: badgeAccentColor,
                                  foregroundColor:
                                      isDark ? Colors.black87 : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () async {
                                  await authProvider.claimDailyReward();
                                  _closeEnergyMenu();
                                },
                                child: const Text(
                                  'Забрать бонус',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          if (rewardBlockedByBalance) ...[
                            const Gap(16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  disabledBackgroundColor:
                                      Colors.grey.withOpacity(0.18),
                                  disabledForegroundColor: Colors.grey,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Бонус недоступен',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const Gap(8),
                            Text(
                              'Бонус можно получить, когда баланс ниже 30 ⚡️',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: descColor,
                                fontSize: 12,
                                height: 1.25,
                              ),
                            ),
                          ],

                          if (rewardOnCooldown) ...[
                            const Gap(16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  disabledBackgroundColor:
                                      Colors.grey.withOpacity(0.18),
                                  disabledForegroundColor: Colors.grey,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Доступно через ${authProvider.formattedRewardTime}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const Gap(16),
                          Divider(
                            height: 1,
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                          const Gap(12),
                          Opacity(
                            opacity: 0.6,
                            child: Row(
                              children: [
                                const Text(
                                  '💳 🛒',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Text(
                                    'Другие способы пополнения\nпоявятся позже...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: descColor,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final balance = authProvider.coinsBalance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accentColor = isDark ? Colors.amberAccent : Colors.amber.shade800;
    final baseBgColor =
        isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.withOpacity(0.10);
    final borderColor = isDark ? Colors.amber : Colors.amber.shade600;

    final displayBalance =
        balance % 1 == 0 ? balance.toInt().toString() : balance.toString();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Center(
        child: AnimatedScale(
          scale: _isHovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            height: 38,
            constraints: const BoxConstraints(
              minWidth: 92,
              maxWidth: 150,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _isHovered ? baseBgColor.withOpacity(0.3) : baseBgColor,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(19),
                onTap: () => _toggleEnergyMenu(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '⚡️',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1,
                      ),
                    ),
                    const Gap(6),
                    Flexible(
                      child: Text(
                        displayBalance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1,
                        ),
                      ),
                    ),
                    const Gap(6),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 12,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}