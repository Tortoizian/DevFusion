import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BalanceChip extends StatelessWidget {
  final double balance;

  const BalanceChip({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final settled = balance.abs() < 0.01;
    final color = settled
        ? AppColors.textSecondary
        : balance > 0
            ? AppColors.owedToYou
            : AppColors.owed;
    final label = settled
        ? '₹0.00'
        : '${balance > 0 ? '+' : '-'}₹${balance.abs().toStringAsFixed(2)}';

    return Chip(
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
