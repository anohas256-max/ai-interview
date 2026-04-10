import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sobes/features/auth/presentation/providers/auth_provider.dart';

class BalanceBadge extends StatelessWidget {
  const BalanceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<AuthProvider>().coinsBalance;
    
    // Адаптация под светлую/темную тему
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.amberAccent : Colors.orange.shade900;
    final bgColor = isDark ? Colors.amber.withOpacity(0.15) : Colors.orange.withOpacity(0.15);
    final borderColor = isDark ? Colors.amber : Colors.orange.shade700;

    // Убираем ".0", если число целое (чтобы 2.5 было 2.5, а 50.0 стало 50)
    final displayBalance = balance % 1 == 0 ? balance.toInt().toString() : balance.toString();

    return Container(
      margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: borderColor, width: 1.5), 
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(displayBalance, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}