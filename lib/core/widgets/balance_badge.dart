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
  final LayerLink _layerLink = LayerLink();

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
    final badgeAccentColor = isDark ? Colors.amberAccent : Colors.amber.shade800;
    final borderColor = isDark ? Colors.amber : Colors.amber.shade600;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeEnergyMenu,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox(width: double.infinity, height: double.infinity),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 10), 
              showWhenUnlinked: false,
              child: Material(
                elevation: isDark ? 8 : 4, 
                borderRadius: BorderRadius.circular(16),
                color: Colors.transparent, 
                clipBehavior: Clip.antiAlias, 
                shadowColor: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                child: Container(
                  width: 270, 
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor.withOpacity(0.3), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: ListenableBuilder(
                    listenable: authProvider,
                    builder: (context, child) {
                      final descColor = isDark ? Colors.grey : Colors.grey.shade600; 

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: badgeAccentColor.withOpacity(isDark ? 0.15 : 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor.withOpacity(0.4), width: 1),
                                ),
                                child: Transform.translate(
                                  offset: const Offset(0, 1.5),
                                  child: const Text('🎁', style: TextStyle(fontSize: 18, height: 1.0)),
                                ),
                              ),
                              const Gap(12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authProvider.isRewardReady ? "Энергия накоплена!" : "Ежедневный бонус",
                                      style: TextStyle(fontWeight: FontWeight.w800, color: textColor, fontSize: 14),
                                    ),
                                    const Gap(4),
                                    Text(
                                      authProvider.isRewardReady
                                          ? "Нажмите, чтобы забрать"
                                          : "Доступно через: ${authProvider.formattedRewardTime}",
                                      style: TextStyle(
                                        color: authProvider.isRewardReady ? Colors.green : descColor, 
                                        fontSize: 12,
                                        fontWeight: authProvider.isRewardReady ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(8),
                              Transform.translate(
                                offset: const Offset(0, 1.0),
                                child: Text('+15 ⚡️', style: TextStyle(fontWeight: FontWeight.w800, color: badgeAccentColor, fontSize: 16)),
                              ),
                            ],
                          ),
                          
                          if (authProvider.isRewardReady) ...[
                            const Gap(16),
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: badgeAccentColor,
                                  foregroundColor: isDark ? Colors.black87 : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  authProvider.claimDailyReward();
                                  _closeEnergyMenu();
                                },
                                child: const Text("Забрать бонус", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ],
                          const Gap(16),
                          Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          const Gap(12),
                          Opacity(
                            opacity: 0.6,
                            child: Row(
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, 1.0),
                                  child: const Text('💳 🛒', style: TextStyle(fontSize: 18)),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      "Другие способы пополнения (кошелек, магазин)\nпоявятся позже...",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: descColor, fontSize: 10, fontStyle: FontStyle.italic, height: 1.3),
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
    final baseBgColor = isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.withOpacity(0.10);
    final borderColor = isDark ? Colors.amber : Colors.amber.shade600;

    final displayBalance = balance % 1 == 0 ? balance.toInt().toString() : balance.toString();

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        // Обернули только в Center, чтобы он идеально вставал по вертикали AppBar'а
        child: Center(
          child: AnimatedScale(
            scale: _isHovered ? 1.03 : 1.0, 
            duration: const Duration(milliseconds: 150),
            child: Container(
              height: 38, // Жесткая высота
              padding: const EdgeInsets.symmetric(horizontal: 14), // Горизонтальный отступ внутри кнопки
              decoration: BoxDecoration(
                color: _isHovered ? baseBgColor.withOpacity(0.3) : baseBgColor,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(19),
                  onTap: () => _toggleEnergyMenu(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 👇 ЖЕСТКО СПУСКАЕМ ЭМОДЗИ НА 1.5 ПИКСЕЛЯ ВНИЗ 👇
                      Transform.translate(
                        offset: const Offset(0, 1.5), 
                        child: const Text('⚡️', style: TextStyle(fontSize: 14, height: 1.0)),
                      ),
                      const Gap(6),
                      Text(
                        displayBalance,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.0, 
                        ),
                      ),
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, size: 12, color: accentColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}