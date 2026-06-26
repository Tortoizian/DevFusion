import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

/// Top-of-dashboard summary of net balance across all groups.
class GlobalBalanceCard extends StatelessWidget {
  final double netBalance;

  const GlobalBalanceCard({
    super.key,
    required this.netBalance,
  });

  String get _headline {
    if (netBalance.abs() < 0.01) return 'All settled';
    if (netBalance > 0) return 'You are owed';
    return 'You owe';
  }

  IconData get _icon {
    if (netBalance.abs() < 0.01) return Icons.check_circle_outline;
    if (netBalance > 0) return Icons.south_west;
    return Icons.north_east;
  }

  Color get _amountColor {
    if (netBalance.abs() < 0.01) return AppColors.textSecondary;
    if (netBalance > 0) return AppColors.owedToYou;
    return AppColors.owed;
  }

  @override
  Widget build(BuildContext context) {
    final amountLabel = '₹${netBalance.abs().toStringAsFixed(2)}';

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_icon, color: _amountColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your balance',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  _headline,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  netBalance.abs() < 0.01 ? '₹0.00' : amountLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: _amountColor,
                        fontSize: 28,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
