import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';

/// Top-of-dashboard summary of net balance across all groups.
/// Step 25 wires this to live data from [globalBalanceProvider].
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

  Color get _amountColor {
    if (netBalance.abs() < 0.01) return AppColors.textSecondary;
    if (netBalance > 0) return AppColors.owedToYou;
    return AppColors.owed;
  }

  @override
  Widget build(BuildContext context) {
    final amountLabel = '₹${netBalance.abs().toStringAsFixed(2)}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your balance',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            _headline,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            netBalance.abs() < 0.01 ? '₹0.00' : amountLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: _amountColor,
                  fontSize: 28,
                ),
          ),
        ],
      ),
    );
  }
}
