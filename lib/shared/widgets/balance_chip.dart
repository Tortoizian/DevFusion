import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_format.dart';

class BalanceChip extends StatelessWidget {
  final double balance;
  final bool compact;

  const BalanceChip({
    super.key,
    required this.balance,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final settled = balance.abs() < 0.01;
    final color = settled
        ? AppColors.textSecondary
        : balance > 0
            ? AppColors.owedToYou
            : AppColors.owed;
    final label = formatCurrencyAmount(balance, compact: compact, showSign: !settled);

    if (compact) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 72,
          maxHeight: 26,
          minWidth: 40,
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                height: 1.1,
              ),
            ),
          ),
        ),
      );
    }

    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
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
