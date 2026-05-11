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

  void _showEnergyMenu(BuildContext context) {
    // ... (логика _showEnergyMenu остается такой же, как была, она в порядке)
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final balance = authProvider.coinsBalance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Получаем ширину экрана, чтобы понять, насколько мы стеснены
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360; // Порог для совсем маленьких экранов

    final textColor = isDark ? Colors.amberAccent : Colors.amber.shade800;
    final baseBgColor = isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.withOpacity(0.10);
    final borderColor = isDark ? Colors.amber : Colors.amber.shade600;

    final displayBalance = balance % 1 == 0 ? balance.toInt().toString() : balance.toString();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          // Адаптивный маржин: на маленьких экранах прижимаемся к краю
          margin: EdgeInsets.only(
            right: isCompact ? 8 : 16, 
            top: 10, 
            bottom: 10
          ),
          constraints: BoxConstraints(maxWidth: isCompact ? 80 : 120),
          decoration: BoxDecoration(
            color: _isHovered ? baseBgColor.withOpacity(0.3) : baseBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showEnergyMenu(context),
              child: Padding(
                // Уменьшаем внутренние отступы на маленьких экранах
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 6 : 10, 
                  vertical: 4
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡️', style: TextStyle(fontSize: 14)),
                      Gap(isCompact ? 3 : 6),
                      Text(
                        displayBalance,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      // СКРЫВАЕМ ПЛЮСИК, если экран слишком узкий
                      if (!isCompact) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: textColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add, size: 12, color: textColor),
                        ),
                      ],
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